xquery version "1.0-ml";

(:
 : This is an implementation library, not an interface to the Smart Mastering functionality.
 :
 : Match-and-merge combines the two primary functions of Smart Mastering in a
 : single call. This means that both happen in the same transaction. When
 : called this way, the actions configured on thresholds in the match options
 : are taken automatically, rather than individually by the client.
 :)

module namespace proc-impl = "http://marklogic.com/smart-mastering/process-records/impl";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace fun-ext = "http://marklogic.com/smart-mastering/function-extension"
  at "../function-extension/base.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace merge-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace tel = "http://marklogic.com/smart-mastering/telemetry"
  at "/com.marklogic.smart-mastering/telemetry.xqy";

declare option xdmp:mapping "false";

declare function proc-impl:process-match-and-merge($uris as xs:string*)
  as item()*
{
  let $merging-options := merging:get-options($const:FORMAT-XML)
  return
    if (fn:exists($merging-options)) then
      for $merging-options in merging:get-options($const:FORMAT-XML)
      return
        proc-impl:process-match-and-merge-with-options($uris, $merging-options, cts:true-query())
    else
      fn:error($const:NO-MERGE-OPTIONS-ERROR, "No Merging Options are present. See: https://marklogic-community.github.io/smart-mastering-core/docs/merging-options/")
};

declare function proc-impl:process-match-and-merge(
  $uris as xs:string*,
  $option-name as xs:string,
  $filter-query as cts:query)
  as item()*
{
  proc-impl:process-match-and-merge-with-options(
    $uris,
    merging:get-options($option-name, $const:FORMAT-XML),
    $filter-query
  )
};

declare variable $STRING-TOKEN := "##";

(:
 : Given a map with keys that are URIs and values that are the result elements from running the match function against
 : that URI's document, produce a map where the key is a generated unique ID and the values are sequences of URIs to be
 : merged. We want to eliminate redundant cases, such as merge(docA, docB) and merge(docB, docA).
 : @param $matches
 : @return  map(unique ID -> sequence of URIs)
 :)
declare function proc-impl:consolidate-merges($matches as map:map) as map:map
{
  map:new((
    let $merges :=
      fn:distinct-values(
        for $key in map:keys($matches)
        let $merge-uris as xs:string* := map:get($matches, $key)/result[@action="merge"]/@uri
        where fn:exists($merge-uris)
        return
          fn:string-join(
            for $uri in ($key, $merge-uris)
            order by $uri
            return $uri,
            $STRING-TOKEN
          )
      )
    for $merge in $merges
    let $uris := fn:tokenize($merge, $STRING-TOKEN)
    return
      map:entry(sem:uuid-string(), $uris)
  ))
};

declare function proc-impl:consolidate-notifies($all-matches as map:map, $consolidated-merges as map:map)
  as xs:string*
{
  let $merged-into := -$consolidated-merges
  return
    fn:distinct-values(
      for $key in map:keys($all-matches)
      let $updated-key :=
        if (map:contains($merged-into, $key)) then
          merge-impl:build-merge-uri(map:get($merged-into, $key), $key)
        else
          $key
      for $key-notification in map:get($all-matches, $key)/result[@action="notify"]
      let $key-uri as xs:string := $key-notification/@uri
      let $updated-uri :=
        if (map:contains($merged-into, $key-uri)) then
          merge-impl:build-merge-uri(map:get($merged-into, $key-uri), $key-uri)
        else
          $key-uri
      return
        fn:string-join(($key-notification/@threshold, for $uri in ($updated-key, $updated-uri) order by $uri return $uri ), $STRING-TOKEN)
    )
};

(:
 : The workhorse function.
 :)
declare function proc-impl:process-match-and-merge-with-options(
  $uris as xs:string*,
  $options as item(),
  $filter-query as cts:query)
{
  (: increment usage count :)
  tel:increment(),

  let $_ := xdmp:trace($const:TRACE-MATCH-RESULTS, "processing: " || fn:string-join($uris, ", "))
  let $matching-options := matcher:get-options(fn:string($options/merging:match-options), $const:FORMAT-XML)
  let $thresholds := $matching-options/matcher:thresholds/matcher:threshold[@action = ($const:MERGE-ACTION, $const:NOTIFY-ACTION)]
  let $threshold-labels := $thresholds/@label
  let $minimum-threshold :=
    fn:min(
      $matching-options/matcher:thresholds/matcher:threshold[@label = $threshold-labels]/@above ! fn:number(.)
    )
  let $lock-on-query := fn:true()
  let $all-matches :=
    map:new((
      $uris !
        map:entry(
          .,
          matcher:find-document-matches-by-options(
            fn:doc(.),
            $matching-options,
            1,
            fn:head((
              $matching-options/matcher:max-scan ! xs:integer(.),
              500
            )),
            $minimum-threshold,
            $lock-on-query,
            fn:false(),
            $filter-query
          )
        )
    ))
  let $consolidated-merges := proc-impl:consolidate-merges($all-matches)
  let $consolidated-notifies := proc-impl:consolidate-notifies($all-matches, $consolidated-merges)

  return (
    (: Process merges :)
    for $new-uri in map:keys($consolidated-merges)
    return
      merge-impl:save-merge-models-by-uri(map:get($consolidated-merges, $new-uri), $options, $new-uri),

    (: Process notifications :)
    for $notification in $consolidated-notifies
    let $parts := fn:tokenize($notification, $STRING-TOKEN)
    let $threshold := fn:head($parts)
    let $uris := fn:tail($parts)
    return
      matcher:save-match-notification($threshold, $uris),

    (: Process custom actions :)
    let $action-map :=
      map:new((
        let $custom-action-names := $matching-options/matcher:thresholds/matcher:threshold/@action[fn:not(. = $const:NOTIFY-ACTION or . = $const:MERGE-ACTION)]
        for $custom-action-name in fn:distinct-values($custom-action-names)
        let $action-xml := $matching-options/matcher:actions/matcher:action[@name = $custom-action-name]
        return
          map:entry(
            $custom-action-name,
            fun-ext:function-lookup(
              fn:string($action-xml/@function),
              fn:string($action-xml/@namespace),
              fn:string($action-xml/@at),
              ()
            )
          )
      ))
    for $uri in map:keys($all-matches)
    for $custom-action-match in map:get($all-matches, $uri)/result[fn:not(./@action = $const:NOTIFY-ACTION or ./@action = $const:MERGE-ACTION)]
    let $action-func := map:get($action-map, $custom-action-match/@action)
    return
      if (fn:exists($action-func)) then
        if (fn:ends-with(xdmp:function-module($action-func), "sjs")) then
          xdmp:apply(
            $action-func,
            $uri,
            proc-impl:matches-to-json($custom-action-match),
            merge-impl:options-to-json($options)
          )
        else
          xdmp:apply($action-func, $uri, $custom-action-match, $options)
      else
        fn:error(xs:QName("SM-CONFIGURATION"), "Threshold action is not configured or not found", $custom-action-match)
  )
};

(:
 : Convert the result elements into JSON objects.
 : TODO -- does not yet convert result/match elements to JSON. This is okay for now as there is no way to turn on the
 : $include-matches parameter from process-match-and-merge.
 :)
declare function proc-impl:matches-to-json($filtered-matches as element(result)*)
{
  array-node {
    for $match in $filtered-matches
    return object-node {
      "uri": $match/@uri/fn:string(),
      "score": $match/@score/fn:data(),
      "threshold": $match/@threshold/fn:string()
    }
  }
};
