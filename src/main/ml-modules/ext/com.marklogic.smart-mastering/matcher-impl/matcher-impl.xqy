xquery version "1.0-ml";

(:
 : This is an implementation library, not an interface to the Smart Mastering functionality.
 :)

module namespace match-impl = "http://marklogic.com/smart-mastering/matcher-impl";

import module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms"
  at  "/ext/com.marklogic.smart-mastering/algorithms/base.xqy";
import module namespace blocks-impl = "http://marklogic.com/smart-mastering/blocks-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/blocks-impl.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";
import module namespace opt-impl = "http://marklogic.com/smart-mastering/options-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/options-impl.xqy";

declare namespace matcher = "http://marklogic.com/smart-mastering/matcher";

declare option xdmp:mapping "false";

declare function match-impl:find-document-matches-by-options(
  $document,
  $options,
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold,
  $lock-on-search
) as element(results)
{
  let $options :=
    if ($options instance of object-node()) then
      opt-impl:options-from-json($options)
    else
      $options
  let $tuning := $options/matcher:tuning
  let $property-defs := $options/matcher:property-defs
  let $thresholds := $options/matcher:thresholds
  let $scoring := $options/matcher:scoring
  let $algorithms := algorithms:build-algorithms-map($options/matcher:algorithms)
  let $query := match-impl:build-query($document, $property-defs, $scoring, $algorithms, $options)
  let $serialized-query := element boost-query {$query}
  let $minimum-threshold-combinations :=
    match-impl:minimum-threshold-combinations($serialized-query, $minimum-threshold)
  let $match-query :=
    cts:and-query((
      cts:collection-query($const:CONTENT-COLL),
      if (fn:exists(xdmp:node-uri($document))) then
        cts:not-query(cts:document-query(xdmp:node-uri($document)))
      else (),
      cts:or-query(
        $minimum-threshold-combinations
      ),
      let $blocks := blocks-impl:get-blocks(fn:base-uri($document))
      where fn:exists($blocks/node())
      return
        cts:not-query(cts:document-query($blocks/node()))
    ))
  let $serialized-match-query :=
    element match-query {
      $match-query
    }
  let $serialized-match-query-combinations := $serialized-match-query/cts:and-query/cts:or-query//element(*, cts:query)
  let $reduced-boost := cts:query(
    element cts:or-query {
      for $query in $serialized-query/cts:or-query/element(*, cts:query)
      where fn:not(
        some $match-combo in $serialized-match-query-combinations
        satisfies fn:deep-equal($query, $match-combo)
      )
      return
        $query
    }
  )
  let $_lock-on-search :=
    if ($lock-on-search) then
      match-impl:lock-on-search($serialized-match-query/cts:and-query/cts:or-query)
    else ()
  return (
    $_lock-on-search,
    element results {
      element boost-query {$reduced-boost},
      $serialized-match-query,
      match-impl:search(
        $match-query,
        $reduced-boost,
        $minimum-threshold,
        $thresholds,
        $start,
        $page-length,
        $scoring,
        $algorithms,
        $options
      )
    }
  )
};

declare function match-impl:build-query($document, $property-defs, $scoring, $algorithms, $options)
{
  cts:or-query((
    for $score in $scoring/*
    let $property-name := $score/@property-name
    let $property-def := $property-defs/matcher:property[@name = $property-name]
    where fn:exists($property-def)
    return
      let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
      let $values := $document//*[fn:node-name(.) eq $qname] ! fn:normalize-space(.)[.]
      where fn:exists($values)
      return
        if ($score instance of element(matcher:add)) then
          cts:element-value-query(
            $qname,
            $values,
            ("case-insensitive"),
            $score/@weight
          )
        else if ($score instance of element(matcher:expand)) then
          let $algorithm := map:get($algorithms, $score/@algorithm-ref)
          where fn:exists($algorithm)
          return algorithms:execute-algorithm($algorithm, $values, $score, $options)
        else ()
  (:,
    for $reduction in $scoring/matcher:reduce
    let $algorithm := map:get($algorithms, concat($reduction/@algorithm-ref, '-query'))
    where fn:exists($algorithm)
    return algorithms:execute-algorithm($algorithm, $document, $reduction, $options):)
  ))
};

declare function match-impl:search(
  $match-query,
  $boosting-query,
  $min-threshold,
  $thresholds,
  $start,
  $page-length,
  $scoring,
  $algorithms,
  $options
) {
  let $range := $start to ($start + $page-length - 1)
  let $additional-documents :=
    for $result at $pos in cts:search(
      fn:collection(),
      cts:boost-query(
        $match-query,
        $boosting-query
      ),
      ("unfiltered", "score-simple")
    )[fn:position() = $range]
    let $score := match-impl:simple-score($result)
    let $result-stub :=
      element results {
        attribute uri {xdmp:node-uri($result)},
        attribute index {$range[fn:position() = $pos]},
        attribute total {cts:remainder($result)},
        element matches {
          cts:walk(
            $result,
            cts:or-query((
              $match-query,
              $boosting-query
            )),
            $cts:node/..
          )
        }
      }
    let $reduced-score := $score -
      fn:sum(
        for $reduction in $scoring/matcher:reduce
        let $algorithm := map:get($algorithms, $reduction/@algorithm-ref)
        where fn:exists($algorithm) and algorithms:execute-algorithm($algorithm, $result-stub, $reduction, $options)
        return $reduction/@weight ! fn:number(.)
      )
    where $score ge $min-threshold
    return
      element results {
        $result-stub/@*,
        attribute score {$reduced-score},
        attribute threshold {
          (
            for $threshold in $thresholds/matcher:threshold
            where $reduced-score ge fn:number($threshold/@above)
            order by fn:number($threshold/@above) descending
            return fn:string($threshold/@label)
          )[1]
        },
        $result-stub/*
      }
  return
    $additional-documents
};

(:
 : score-simple gives 8pts per matching term and multiplies the results by 256 (MarkLogic documentation)
 : this reduces the magnitude of the score
 :)
declare function match-impl:simple-score($item) {
  cts:score($item) div (256 * 8)
};

declare variable $results-json-config := match-impl:_results-json-config();

declare function match-impl:_results-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", ("results","matches",xs:QName("cts:option"),xs:QName("cts:text"),xs:QName("cts:element"))),
    map:put($config, "full-element-names",
      (xs:QName("cts:query"),
      xs:QName("cts:and-query"),
      xs:QName("cts:near-query"),
      xs:QName("cts:or-query"))
    ),
    map:put($config, "json-children", "queries"),
    map:put($config, "attribute-names",
      ("name","localname", "namespace", "function",
      "at", "property-name", "weight", "above", "label","algorithm-ref")
    ),
    $config
  )
};

declare function match-impl:minimum-threshold-combinations($query-results, $threshold)
{
  let $weighted-queries :=
    for $query in ($query-results//element(*,cts:query) except $query-results//(cts:and-query|cts:or-query))
    let $weight := $query/@weight ! fn:number(.)
    where fn:empty($weight) or $weight gt 0
    order by $weight descending empty least
    return $query
  let $queries-ge-threshold := $weighted-queries[@weight][@weight ge $threshold]
  let $queries-lt-threshold := $weighted-queries except $queries-ge-threshold
  return (
    $queries-ge-threshold ! cts:query(.),
    match-impl:filter-for-required-queries($queries-lt-threshold, 0, $threshold, ())
  )
};

declare function match-impl:filter-for-required-queries(
  $remaining-queries,
  $combined-weight,
  $threshold,
  $accumulated-queries
) {
  if ($threshold eq 0 or $combined-weight ge $threshold) then
    cts:and-query(
      $accumulated-queries ! cts:query(.)
    )
  else
    for $query at $pos in $remaining-queries
    let $query-weight := fn:head(($query/@weight ! fn:number(.), 1))
    let $new-combined-weight := $combined-weight + $query-weight
    let $last-accumulated := fn:head(fn:reverse($accumulated-queries))
    let $last-accumulated-weight := fn:min(($last-accumulated/@weight/fn:number(),1))
    let $accumulated-queries :=
      if (fn:exists($last-accumulated) and
        ($new-combined-weight - $last-accumulated-weight) ge $threshold) then
        $accumulated-queries except $last-accumulated
      else
        $accumulated-queries
    return
      match-impl:filter-for-required-queries(
        fn:subsequence($remaining-queries, $pos + 1),
        $new-combined-weight,
        $threshold,
        ($accumulated-queries, $query)
      )
};

declare function match-impl:lock-on-search($query-results)
  as empty-sequence()
{
  let $required-queries := $query-results/element(*,cts:query)
  for $required-query in $required-queries
  let $lock-uri := "/com.marklogic.smart-mastering/query-lock/"||
  fn:normalize-unicode(
    fn:normalize-space(fn:lower-case(fn:string($required-query)))
  )
  return
    fn:function-lookup(xs:QName("xdmp:lock-for-update"),1)($lock-uri)
};

declare function match-impl:results-to-json($results-xml)
  as object-node()?
{
  if (fn:exists($results-xml)) then
    xdmp:to-json(
      json:transform-to-json-object($results-xml, $results-json-config)
    )
  else ()
};
