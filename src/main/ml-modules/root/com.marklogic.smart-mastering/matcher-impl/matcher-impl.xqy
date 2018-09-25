xquery version "1.0-ml";

(:
 : This is an implementation library, not an interface to the Smart Mastering functionality.
 :
 : The process of matching starts with one document, which is not required to
 : be in the database. The match options specify what properties are to be used
 : to find matches. See match options documentation for details. The options
 : may specify multiple thresholds, each of which corresponds to an action.
 :
 : Implementation notes: the configured properties are used to generate a boost
 : query. The match part of the query identifies a set of subqueries that a
 : document must match in order to get a score above the lowest threshold.
 : Match queries all have their scores set to zero. The boost part of the query
 : is used to provide the score.

 : @see https://marklogic-community.github.io/smart-mastering-core/docs/matching-options/
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
import module namespace tel = "http://marklogic.com/smart-mastering/telemetry"
  at "/com.marklogic.smart-mastering/telemetry.xqy";

declare namespace matcher = "http://marklogic.com/smart-mastering/matcher";
declare namespace sm = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";

declare option xdmp:mapping "false";

(:
 : Find documents that are potential matches for the provided document.
 : @param $document  a source document to draw values from
 : @param $options  XML or JSON representation of match options
 : @param $start  paging: 1-based index
 : @param $page-length  paging: number of results to return
 : @param $minimum-threshold  the required score for the lowest-scoring
 :                            threshold (see match options)
 : @param $lock-on-search
 : @param $include-matches  if true, the response will include, for each result,
 :                          the properties that earned points for the match
 :                          (similar) to snippets
 : @param $filter-query  a cts:query that reduces the scope of documents that
 :                       will be searched for matches
 :)
declare function match-impl:find-document-matches-by-options(
  $document,
  $options as item(),
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold as xs:double,
  $lock-on-search as xs:boolean,
  $include-matches as xs:boolean,
  $filter-query as cts:query
) as element(results)
{
  (: increment usage count :)
  tel:increment(),

  let $options :=
    if ($options instance of object-node()) then
      opt-impl:options-from-json($options)
    else
      $options
  let $scoring := $options/matcher:scoring
  let $algorithms := algorithms:build-algorithms-map($options/matcher:algorithms)
  let $boost-query := match-impl:build-boost-query($document, $scoring, $algorithms, $options)
  let $serialized-boost-query := element boost-query {$boost-query}
  let $minimum-threshold-combinations :=
    match-impl:minimum-threshold-combinations($serialized-boost-query, $minimum-threshold)
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
      $serialized-boost-query/cts:or-query/element(*, cts:query)
    }
  )
  let $_lock-on-search :=
    if ($lock-on-search) then
      match-impl:lock-on-search($serialized-match-query/cts:and-query/cts:or-query)
    else ()
  let $matches :=
    match-impl:drop-redundant(
      xdmp:node-uri($document),
      match-impl:search(
        $match-query,
        $reduced-boost,
        $filter-query,
        $minimum-threshold,
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
 : @param $uri  URI of the original document
 : @param $matches  matches that have been found for the original document
 : @result a subset of the $matches passed in
 :)
declare function match-impl:drop-redundant($uri, $matches as element(result)*)
  as element(result)*
{
  let $drop := map:map()

  (: Look for merge-results that have already happened since matching ran :)
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

  (: Look for notification-results that have already happened since matching ran :)
  let $notification-results := $matches[@action=$const:NOTIFY-ACTION]
  let $notification-uris := $notification-results/@uri
  let $notifications :=
    let $notifications := xdmp:invoke-function(
      function() {
        notify-impl:get-existing-match-notification((), $notification-uris)
      },
      map:entry("isolation", "different-transaction")
    )
    for $notification in $notifications
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

(:
 : Build the boost query as specified by the match options.
 : @param $document  the source document from which property values are drawn
 : @param $property-defs  part of match options; identifies properties
 : @param $scoring  part of match options;
 : @param $algorithms  part of match options;
 : @param $options  full match options; included here to pass into algorithm functions
 : @return a cts:or-query that will be used as a boost query
 :)
declare function match-impl:build-boost-query($document, $scoring, $algorithms, $options)
{
  let $property-defs := $options/matcher:property-defs
  return
    cts:or-query((
      for $score in $scoring/*
      let $property-name := $score/@property-name
      let $property-def := $property-defs/matcher:property[@name = $property-name]
      where fn:exists($property-def)
      return
        let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
        let $values := fn:distinct-values($document//*[fn:node-name(.) eq $qname] ! fn:normalize-space(.)[.])
        let $is-json := fn:exists(($document/object-node(), $document/array-node()))
        where fn:exists($values)
        return
          if ($score instance of element(matcher:add)) then
            (: in older version of MarkLogic element-value-query would work
               with json too, but in newer versions of MarkLogic we
               need a separate json query :)
            if ($is-json) then
              cts:json-property-value-query(
                fn:string($qname),
                $values,
                ("case-insensitive"),
                $score/@weight
              )
            else
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

(:
 : Execute the generated search and construct the response.
 : @param $match-query  a query built such that any matches will score at least
 :                      high enough to reach the lowest threshold
 : @param $boosting-query  a query that is used to score matches
 : @param $filter-query  a query to reduce the universe of match candidates
 : @param $min-threshold  lowest score required to hit a threshold
 : @param $start  paging: 1-based index
 : @param $page-length  paging
 : @param $scoring  part of match options
 : @param $algorithms  map derived from match options
 : @param $options  full match options; included to pass to reduce algorithm
 : @param $include-matches
 : @return
 :)
declare function match-impl:search(
  $match-query,
  $boosting-query,
  $filter-query as cts:query,
  $min-threshold as xs:double,
  $start as xs:int,
  $page-length as xs:int,
  $scoring as element(matcher:scoring),
  $algorithms as map:map,
  $options as element(matcher:options),
  $include-matches as xs:boolean
) {
  let $range := $start to ($start + $page-length - 1)
  let $query :=
    cts:and-query((
      cts:query(match-impl:strip-query-weights(document { $filter-query }/element())),
      cts:boost-query($match-query, $boosting-query)
    ))
  let $thresholds := $options/matcher:thresholds
  for $result at $pos in cts:search(
    fn:collection(),
    $query,
    ("unfiltered", "score-simple")
  )[fn:position() = $range]
  let $score := match-impl:simple-score($result)
  let $result-stub :=
    element result {
      attribute uri {xdmp:node-uri($result)},
      attribute index {$range[fn:position() = $pos]},
      if ($include-matches) then
        element matches {
          (: rather than store the entire node and risk mixing
             content type (json != xml) we store the path to the
             node instead :)
          cts:walk(
            $result,
            cts:or-query((
              $match-query,
              $boosting-query
            )),
            $cts:node/<match>{xdmp:path(., fn:true())}</match>
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
 : @see http://docs.marklogic.com/guide/search-dev/relevance#id_37592
 :)
declare function match-impl:simple-score($item) {
  cts:score($item) div (256 * 8)
};

(: Configuration used to convert XML match results to JSON. :)
declare variable $results-json-config := match-impl:_results-json-config();

declare function match-impl:_results-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", ("result","matches",xs:QName("cts:option"),xs:QName("cts:text"),xs:QName("cts:element"))),
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
          attribute { "weight" } { 0 },
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

(:
 : Convert XML match results to JSON.
 :)
declare function match-impl:results-to-json($results-xml)
  as object-node()?
{
  if (fn:exists($results-xml)) then
    xdmp:to-json(
      json:transform-to-json-object($results-xml, $results-json-config)
    )/node()
  else ()
};
