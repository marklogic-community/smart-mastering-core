xquery version "1.0-ml";

module namespace matcher = "http://marklogic.com/smart-mastering/matcher";

import module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms"
  at  "algorithms/base.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";
import module namespace sem = "http://marklogic.com/semantics"
  at "/MarkLogic/semantics.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

declare namespace smart-mastering = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

declare variable $ALGORITHM-OPTIONS-DIR := "/com.marklogic.smart-mastering/options/algorithms/";

(: Predicate for recording match blocks between two documents :)
declare variable $PRED-MATCH-BLOCK := sem:iri("http://marklogic.com/smart-mastering/match-block");

declare variable $STATUS-READ := "read";
declare variable $STATUS-UNREAD := "unread";

(:

Example matcher options:

<options xmlns="http://marklogic.com/smart-mastering/matcher">
  <property-defs>
    <property namespace="" localname="IdentificationID" name="ssn"/>
    <property namespace="" localname="PersonGivenName" name="first-name"/>
    <property namespace="" localname="PersonSurName" name="last-name"/>
    <property namespace="" localname="AddressPrivateMailboxText" name="addr1"/>
    <property namespace="" localname="LocationCity" name="city"/>
    <property namespace="" localname="LocationState" name="state"/>
    <property namespace="" localname="LocationPostalCode" name="zip"/>
  </property-defs>
  <algorithms>
    <algorithm name="std-reduce" function="standard-reduction"/>
    <algorithm name="std-reduce-query" function="standard-reduction-query"/>
    <algorithm name="dbl-metaphone" function="double-metaphone"/>
  </algorithms>
  <scoring>
    <add property-name="ssn" weight="50"/>
    <add property-name="last-name" weight="8"/>
    <add property-name="first-name" weight="12"/>
    <add property-name="addr1" weight="5"/>
    <add property-name="city" weight="3"/>
    <add property-name="state" weight="1"/>
    <add property-name="zip" weight="3"/>
    <expand property-name="first-name" algorithm-ref="dbl-metaphone" weight="6">
      <dictionary>name-dictionary.xml</dictionary>
      <distance-threshold>10</distance-threshold>
    </expand>
    <expand property-name="last-name" algorithm-ref="dbl-metaphone" weight="8">
      <dictionary>name-dictionary.xml</dictionary>
      <!--defaults to 100 distance -->
    </expand>
    <reduce algorithm-ref="std-reduce" weight="4">
      <all-match>
        <property>last-name</property>
        <property>addr1</property>
      </all-match>
    </reduce>
  </scoring>
  <thresholds>
    <threshold above="30" label="Possible Match"/>
    <threshold above="50" label="Likely Match"/>
    <threshold above="75" label="Definitive Match"/>
    <!-- below 25 will be NOT-A-MATCH or no category -->
  </thresholds>
  <tuning>
    <max-scan>200</max-scan>  <!-- never look at more than 200 -->
    <initial-scan>20</initial-scan>
  </tuning>
</options>
:)

declare function matcher:find-document-matches-by-options-name($document, $options-name)
{
  matcher:find-document-matches-by-options($document, matcher:get-options($options-name))
};

declare function matcher:find-document-matches-by-options($document, $options)
{
  matcher:find-document-matches-by-options(
    $document,
    $options,
    1,
    fn:head((
      $options//*:max-scan ! xs:integer(.),
      200
    ))
  )
};


declare function matcher:find-document-matches-by-options(
  $document,
  $options,
  $start,
  $page-length
) {
  matcher:find-document-matches-by-options(
    $document,
    $options,
    $start,
    $page-length,
    fn:min($options//*:thresholds/*:threshold/(@above|above) ! fn:number(.)),
    fn:false()
  )
};

declare function matcher:find-document-matches-by-options(
  $document,
  $options,
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold,
  $lock-on-search
) {
  let $options :=
    if ($options instance of object-node()) then
      matcher:options-from-json($options)
    else
      $options
  let $tuning := $options/matcher:tuning
  let $property-defs := $options/matcher:property-defs
  let $thresholds := $options/matcher:thresholds
  let $scoring := $options/matcher:scoring
  let $algorithms := algorithms:build-algorithms-map($options/matcher:algorithms)
  let $query := matcher:build-query($document, $property-defs, $scoring, $algorithms, $options)
  let $serialized-query := element boost-query {$query}
  let $minimum-threshold-combinations :=
    matcher:minimum-threshold-combinations($serialized-query, $minimum-threshold)
  let $match-query :=
    cts:and-query((
        cts:collection-query($const:CONTENT-COLL),
        if (fn:exists(xdmp:node-uri($document))) then
          cts:not-query(cts:document-query(xdmp:node-uri($document)))
        else (),
        cts:or-query(
          $minimum-threshold-combinations
        ),
        let $blocks := matcher:get-blocks(fn:base-uri($document))
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
      matcher:lock-on-search($serialized-match-query/cts:and-query/cts:or-query)
    else ()
  return (
    $_lock-on-search,
    element results {
      element boost-query {$reduced-boost},
      $serialized-match-query,
      matcher:search(
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

declare function matcher:build-query($document, $property-defs, $scoring, $algorithms, $options)
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

declare function matcher:search(
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
    let $score := matcher:simple-score($result)
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

declare function matcher:get-option-names()
{
  let $options := cts:uris('', (), cts:collection-query($const:MATCH-OPTIONS-COLL))
  let $option-names := $options ! fn:replace(
    fn:replace(., $ALGORITHM-OPTIONS-DIR, ""),
    ".xml", ""
  )
  return
    element matcher:options {
      for $name in $option-names
      return
        element matcher:option { $name }
    }
};

declare variable $option-names-json-config := matcher:_option-names-json-config();

declare function matcher:_option-names-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", "option"),
    map:put($config, "element-namespace", "http://marklogic.com/smart-mastering/matcher"),
    map:put($config, "element-namespace-prefix", "matcher"),
    $config
  )
};

declare function matcher:option-names-to-json($options-xml)
{
  xdmp:to-json(
    json:transform-to-json-object($options-xml, $option-names-json-config)
  )
};

declare function matcher:get-options($options-name)
{
  fn:doc($ALGORITHM-OPTIONS-DIR||$options-name||".xml")/matcher:options
};

(:
 : score-simple gives 8pts per matching term and multiplies the results by 256 (MarkLogic documentation)
 : this reduces the magnitude of the score
 :)
declare function matcher:simple-score($item) {
  cts:score($item) div (256 * 8)
};

declare function matcher:save-options(
  $name as xs:string,
  $options as node()
)
{
  algorithms:setup-algorithms($options/(self::*:options|*:options)),
  xdmp:document-insert(
    $ALGORITHM-OPTIONS-DIR||$name||".xml",
    $options,
    (xdmp:permission($const:MDM-ADMIN, "update"), xdmp:permission($const:MDM-USER, "read")),
    ($const:OPTIONS-COLL, $const:MATCH-OPTIONS-COLL, $const:ALGORITHM-COLL)
  )
};

declare function matcher:save-match-notification(
  $threshold-label as xs:string,
  $uris as xs:string*
) {
  let $existing-notification :=
    matcher:get-existing-match-notification(
      $threshold-label,
      $uris
    )
  let $new-notification :=
    element smart-mastering:notification {
      element smart-mastering:meta {
        element smart-mastering:dateTime {fn:current-dateTime()},
        element smart-mastering:user {xdmp:get-current-user()},
        element smart-mastering:status { $STATUS-UNREAD }
      },
      element smart-mastering:threshold-label {$threshold-label},
      element smart-mastering:document-uris {
        let $distinct-uris :=
          fn:distinct-values((
            $uris,
            $existing-notification
              /smart-mastering:document-uris
              /smart-mastering:document-uri ! fn:string(.)
          ))
        for $uri in $distinct-uris
        return
          element smart-mastering:document-uri {
            $uri
          }
      }
    }
  return
    if (fn:exists($existing-notification)) then (
      xdmp:node-replace(fn:head($existing-notification), $new-notification),
      for $extra-doc in fn:tail($existing-notification)
      return
        xdmp:document-delete(xdmp:node-uri($extra-doc))
    ) else
      xdmp:document-insert(
        "/com.marklogic.smart-mastering/matcher/notifications/" ||
        sem:uuid-string() || ".xml",
        $new-notification,
        (
          xdmp:default-permissions(),
          xdmp:permission($const:MDM-USER, "read"),
          xdmp:permission($const:MDM-USER, "update")
        ),
        $const:NOTIFICATION-COLL
      )
};

declare function matcher:get-existing-match-notification(
  $threshold-label as xs:string,
  $uris as xs:string*
) as element(smart-mastering:notification)*
{
  cts:search(fn:collection()/smart-mastering:notification,
    cts:and-query((
      cts:element-value-query(
        xs:QName("smart-mastering:threshold-label"),
        $threshold-label
      ),
      cts:element-value-query(
        xs:QName("smart-mastering:document-uri"),
        $uris
      )
    ))
  )
};

(:
 : Delete the specified notification
 : TODO: do we want to add any provenance tracking to this?
 :)
declare function matcher:delete-notification($uri as xs:string)
{
  xdmp:document-delete($uri)
};

declare variable $options-json-config := matcher:_options-json-config();

declare function matcher:_options-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names",
             ("algorithm","threshold","scoring","property", "reduce", "add", "expand","results")),
    map:put($config, "element-namespace", "http://marklogic.com/smart-mastering/matcher"),
    map:put($config, "element-namespace-prefix", "matcher"),
    map:put($config, "attribute-names",
      ("name","localname", "namespace", "function",
        "at", "property-name", "weight", "above", "label","algorithm-ref")
    ),
    $config
  )
};

declare function matcher:options-to-json($options-xml)
{
  xdmp:to-json(
    json:transform-to-json-object($options-xml, $options-json-config)
  )
};

declare function matcher:options-from-json($options-json)
{
  json:transform-from-json($options-json, $options-json-config)
};

declare variable $results-json-config := matcher:_results-json-config();

declare function matcher:results-to-json($results-xml)
{
  xdmp:to-json(
    json:transform-to-json-object($results-xml, $results-json-config)
  )
};

declare function matcher:_results-json-config()
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


declare function matcher:minimum-threshold-combinations($query-results, $threshold)
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
    matcher:filter-for-required-queries($queries-lt-threshold, 0, $threshold, ())
  )
};

declare function matcher:filter-for-required-queries(
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
      matcher:filter-for-required-queries(
        fn:subsequence($remaining-queries, $pos + 1),
        $new-combined-weight,
        $threshold,
        ($accumulated-queries, $query)
      )
};

declare function matcher:lock-on-search($query-results)
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
 : Return a JSON array of any URIs the that input URI is blocked from matching.
 : @param $uri  input URI
 : @return JSON array of URIs
 :)
declare function matcher:get-blocks($uri as xs:string)
  as array-node()
{
  let $solution :=
    sem:sparql(
      "select distinct(?uri as ?blocked) where { ?uri ?isBlocked ?target }",
      map:new((
        map:entry("target", sem:iri($uri)),
        map:entry("isBlocked", $PRED-MATCH-BLOCK)
      )),
      "map"
    )
  return
    array-node {
      if (fn:exists($solution)) then
        map:get($solution, "blocked")
      else ()
    }
};

(:
 : Prevent the two input URIs from being allowed to match.
 :
 : @param $uri1  First input URI
 : @param $uri2  Second input URI
 : @error will throw xs:QName("SM-CANT-BLOCK") if unable to record the block.
 : @return empty sequence
 :)
declare function matcher:block-match($uri1 as xs:string, $uri2 as xs:string)
  as empty-sequence()
{
  let $_ :=
    (: Suppress sem:rdf-insert's return value :)
    sem:rdf-insert(
      (
        sem:triple(sem:iri($uri1), $PRED-MATCH-BLOCK, sem:iri($uri2)),
        sem:triple(sem:iri($uri2), $PRED-MATCH-BLOCK, sem:iri($uri1))
      )
    )
  return ()
};

(:
 : Clear a match block between the two input URIs.
 :
 : @param $uri1  First input URI
 : @param $uri2  Second input URI
 :
 : @error will throw xs:QName("SM-CANT-UNBLOCK") if a block is present, but it cannot be cleared
 : @return  fn:true if a block was found and cleared; fn:false if no block was found
 :)
declare function matcher:allow-match($uri1 as xs:string, $uri2 as xs:string)
{
  sem:database-nodes((
    cts:triples(sem:iri($uri1), $PRED-MATCH-BLOCK, sem:iri($uri2)),
    cts:triples(sem:iri($uri2), $PRED-MATCH-BLOCK, sem:iri($uri1))
  )) ! xdmp:node-delete(.)
};

(:
 : Translate a notifcation into JSON.
 :)
declare function matcher:notification-to-json($notification as element(smart-mastering:notification))
{
  object-node {
    "meta": object-node {
      "dateTime": $notification/smart-mastering:meta/smart-mastering:dateTime/fn:string(),
      "user": $notification/smart-mastering:meta/smart-mastering:user/fn:string(),
      "uri": fn:base-uri($notification),
      "status": $notification/smart-mastering:meta/smart-mastering:status/fn:string()
    },
    "thresholdLabel": $notification/smart-mastering:threshold-label/fn:string(),
    "uris": array-node {
      for $uri in $notification/smart-mastering:document-uris/smart-mastering:document-uri
      return
        object-node { "uri": $uri/fn:string() }
    }
  }
};

(:
 : Paged retrieval of notifications
 :)
declare function matcher:get-notifications($start, $end)
{
  (fn:collection($const:NOTIFICATION-COLL)[$start to $end])/smart-mastering:notification
};

(:
 : Return a count of all notifications
 :)
declare function matcher:count-notifications()
{
  xdmp:estimate(fn:collection($const:NOTIFICATION-COLL))
};

(:
 : Return a count of unread notifications
 :)
declare function matcher:count-unread-notifications()
{
  xdmp:estimate(
    cts:search(
      fn:collection($const:NOTIFICATION-COLL),
      cts:element-value-query(xs:QName("smart-mastering:status"), $STATUS-UNREAD))
  )
};
