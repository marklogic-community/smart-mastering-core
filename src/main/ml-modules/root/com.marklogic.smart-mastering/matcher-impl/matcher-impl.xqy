xquery version "1.0-ml";

(:
 : This is an implementation library, not an interface to the Smart Mastering functionality.
 :)

module namespace match-impl = "http://marklogic.com/smart-mastering/matcher-impl";

import module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms"
  at  "/com.marklogic.smart-mastering/algorithms/base.xqy";
import module namespace blocks-impl = "http://marklogic.com/smart-mastering/blocks-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/blocks-impl.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";
import module namespace notify-impl = "http://marklogic.com/smart-mastering/notification-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/notification-impl.xqy";
import module namespace opt-impl = "http://marklogic.com/smart-mastering/options-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/options-impl.xqy";

declare namespace matcher = "http://marklogic.com/smart-mastering/matcher";
declare namespace sm = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";

declare option xdmp:mapping "false";

declare function match-impl:find-document-matches-by-options(
  $document,
  $options,
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold as xs:double,
  $lock-on-search,
  $include-matches as xs:boolean
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
  let $reduced-boost := cts:query(
    element cts:or-query {
      $serialized-query/cts:or-query/element(*, cts:query)
    }
  )
  let $_lock-on-search :=
    if ($lock-on-search) then
      match-impl:lock-on-search($serialized-match-query/cts:and-query/cts:or-query)
    else ()
  let $matches :=
    match-impl:drop-redundant(
      $document,
      match-impl:search(
        $match-query,
        $reduced-boost,
        $minimum-threshold,
        $thresholds,
        $start,
        $page-length,
        $scoring,
        $algorithms,
        $options,
        $include-matches
      )
    )
  return (
    $_lock-on-search,
    element results {
      attribute total { xdmp:estimate(cts:search(fn:collection(), $match-query, "unfiltered")) },
      attribute page-length { $page-length },
      attribute start { $start },
      element boost-query {$reduced-boost},
      $serialized-match-query,
      $matches
    }
  )
};

(:
 : Does each item in $s1 appear in $s2?
 :)
declare function match-impl:seq-contains($s1, $s2)
{
  every $s in $s1 satisfies $s = $s2
};

(:
 : Merges happen in a child transaction. If we're calling match functions
 : multiple times within the same transaction, a merge document may end up
 : matching. In case that happens, remove it and its source documents from the
 : list of matches.
 : Rule: if all sources from a merged document are in the list of documents to
 :       be merged, drop the merged document and the sources.
 :)
declare function match-impl:drop-redundant($uri, $matches as element(result)*)
  as element(result)*
{
  let $drop := map:map()
  let $merge-results := $matches[@action=$const:MERGE-ACTION]
  let $merge-uris := ($uri, $merge-results/@uri/fn:string())
  let $merges :=
    for $merge in $merge-results
    return
      if (xdmp:document-get-collections($merge/@uri) = $const:MERGED-COLL) then
        let $sources := fn:doc($merge/@uri)/es:envelope/es:headers/sm:merges/sm:document-uri/fn:string()
        return
          if (match-impl:seq-contains($sources, $merge-uris)) then
            ($sources ! map:put($drop, ., fn:true()))
          else ()
      else
        $merge
  let $notification-results := $matches[@action=$const:NOTIFY-ACTION]
  let $notification-uris := $notification-results/@uri
  let $notifications :=
    let $nots := xdmp:invoke-function(
      function() {
        notify-impl:get-existing-match-notification((), $notification-uris, map:map())
      },
      map:entry("isolation", "different-transaction")
    )
    for $notification in $nots
    let $sources := $notification/sm:document-uris/sm:document-uri[fn:not(. = $notification-uris)]
    return
      if (match-impl:seq-contains($sources, $notification-uris)) then
        ($sources ! map:put($drop, ., fn:true()))
      else ()
  let $drop-uris := map:keys($drop)
  let $results := (
    $merges except $merge-results[@uri = $drop-uris],
    $notification-results except $notification-results[@uri = $drop-uris],
    $matches[fn:not(@action = $const:MERGE-ACTION or @action = $const:NOTIFY-ACTION)]
  )
  for $result in $results
  order by $result/@index
  return $result
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
  $options,
  $include-matches as xs:boolean
) {
  let $range := $start to ($start + $page-length - 1)
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
    element result {
      attribute uri {xdmp:node-uri($result)},
      attribute index {$range[fn:position() = $pos]},
      if ($include-matches) then
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
      else ()
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
    element result {
      $result-stub/@*,
      attribute score {$reduced-score},
      let $selected-threshold := (
        for $threshold in $thresholds/matcher:threshold
        where $reduced-score ge fn:number($threshold/@above)
        order by fn:number($threshold/@above) descending
        return $threshold
      )[1]
      return (
        attribute threshold { fn:string($selected-threshold/@label) },
        attribute action { fn:string($selected-threshold/@action) }
      ),
      $result-stub/*
    }
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

(:
 : Identify a sequence of queries whose scores add up to the $threshold. A document must match at least one of these
 : queries in order to be returned as a potential match.
 :
 : @param $query-results  a sequence of queries with weights
 : @param $threshold  minimum weighted-score for a match to be relevant
 : @return a sequence of queries; a document that matches any of these will have at least $threshold as a score
 :)
declare function match-impl:minimum-threshold-combinations($query-results, $threshold as xs:double)
  as cts:query*
{
  let $weighted-queries :=
    for $query in ($query-results//element(*,cts:query) except $query-results//(cts:and-query|cts:or-query))
    let $weight := $query/@weight ! fn:number(.)
    where fn:empty($weight) or $weight gt 0
    order by $weight descending empty least
    return $query
  (: Each of $queries-ge-threshold has a weight high enough to hit the $threshold :)
  let $queries-ge-threshold := $weighted-queries[@weight][@weight ge $threshold]
  let $queries-lt-threshold := $weighted-queries[fn:empty(@weight) or @weight lt $threshold]
  return (
    match-impl:strip-query-weights($queries-ge-threshold) ! cts:query(.),
    match-impl:filter-for-required-queries($queries-lt-threshold, 0, $threshold, ())
  )
};

(: sets the @weight attributes from cts:queries to 0
 : note: return type left off to allow for tail recursion optimization
 :)
declare function match-impl:strip-query-weights($queries)
{
  for $query in $queries
  return
    typeswitch ($query)
      case schema-element(cts:query) return
        element { fn:node-name($query) } {
          if (fn:ends-with(fn:local-name($query), "-query")) then
            attribute { "weight" } { 0 }
          else (),
          $query/@*[fn:not(self::attribute(weight))],
          match-impl:strip-query-weights($query/node())
        }
      case element() return
        element { fn:node-name($query) } {
          $query/@*,
          match-impl:strip-query-weights($query/node())
        }
      default return $query
};

(:
 : Find combinations of queries whose weights are individually below the threshold, but combined are above it.
 :
 : @param $remaining-queries  sequence of queries ordered by their weights, descending
 : @param $combined-weight
 : @param $threshold  the target value
 : @param $accumulated-queries  accumlated sequence, building up to see whether it can hit the $threshold.
 : @return a sequence of cts:and-queries, one for each required filter
 : note: return type left off to allow for tail recursion optimization.
 :)
declare function match-impl:filter-for-required-queries(
  $remaining-queries as element()*,
  $combined-weight,
  $threshold,
  $accumulated-queries as element()*
)
{
  if ($threshold eq 0 or $combined-weight ge $threshold) then (
    cts:and-query(
      for $query in $accumulated-queries
      return
        match-impl:strip-query-weights($query) ! cts:query(.)
    )
  )
  else
    (: These two lines are only needed for the commented-out code below.
    let $last-accumulated := fn:head(fn:reverse($accumulated-queries))
    let $last-accumulated-weight := fn:head(($last-accumulated/@weight/fn:number(),1))
    :)
    for $query at $pos in $remaining-queries
    let $query-weight := fn:head(($query/@weight ! fn:number(.), 1))
    let $new-combined-weight := $combined-weight + $query-weight
    (: TODO: if this next if statement is true, also need to reduce $new-combined-weight. Commenting out until fixed. :)
    (:
    let $accumulated-queries :=
      if (fn:exists($last-accumulated) and
        ($new-combined-weight - $last-accumulated-weight) ge $threshold) then
        $accumulated-queries except $last-accumulated
      else
        $accumulated-queries
    :)
    return (
      match-impl:filter-for-required-queries(
        fn:subsequence($remaining-queries, $pos + 1),
        $new-combined-weight,
        $threshold,
        ($accumulated-queries, $query)
      )
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
