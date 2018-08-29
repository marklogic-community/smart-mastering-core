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

declare function proc-impl:process-match-and-merge($uri as xs:string)
  as item()*
{
  let $merging-options := merging:get-options($const:FORMAT-XML)
  return
    if (fn:exists($merging-options)) then
      for $merging-options in merging:get-options($const:FORMAT-XML)
      return
        proc-impl:process-match-and-merge-with-options($uri, $merging-options, cts:true-query())
    else
      fn:error($const:NO-MERGE-OPTIONS-ERROR, "No Merging Options are present. See: https://marklogic-community.github.io/smart-mastering-core/docs/merging-options/")
};

declare function proc-impl:process-match-and-merge(
  $uri as xs:string,
  $option-name as xs:string,
  $filter-query as cts:query)
  as item()*
{
  proc-impl:process-match-and-merge-with-options(
    $uri,
    merging:get-options($option-name, $const:FORMAT-XML),
    $filter-query
  )
};

(:
 : The workhorse function.
 :)
declare function proc-impl:process-match-and-merge-with-options(
  $uri as xs:string,
  $options as item(),
  $filter-query as cts:query)
{
  (: increment usage count :)
  tel:increment(),

  let $_ := xdmp:trace($const:TRACE-MATCH-RESULTS, "processing: " || $uri)
  let $matching-options := matcher:get-options-as-xml(fn:string($options/merging:match-options))
  let $thresholds := $matching-options/matcher:thresholds/matcher:threshold[@action = ($const:MERGE-ACTION, $const:NOTIFY-ACTION)]
  let $threshold-labels := $thresholds/@label
  let $minimum-threshold :=
    fn:min(
      $matching-options/matcher:thresholds/matcher:threshold[@label = $threshold-labels]/@above ! fn:number(.)
    )
  let $lock-on-query := fn:true()
  let $matching-results :=
    matcher:find-document-matches-by-options(
      fn:doc($uri),
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
  let $_ := xdmp:trace($const:TRACE-MATCH-RESULTS, $matching-results)
  return (
    (: Must do merges before notifications so that notifications can update
     : their URI references for docs that got merged. Those merges are done
     : in a separate transaction so that they'll be visible.
     :)
    let $merge-uris as xs:string* := $matching-results/result[@action = $const:MERGE-ACTION]/@uri/fn:string()
    return
      if (fn:exists($merge-uris)) then
        merging:save-merge-models-by-uri(
          ($uri, $merge-uris),
          $options
        )
      else (),

    let $notifies := $matching-results/result[@action = $const:NOTIFY-ACTION]
    let $threshold-labels := fn:distinct-values($notifies/@threshold/fn:string())
    for $label in $threshold-labels
    let $notify-uris := $notifies[@threshold eq $label]/@uri/fn:string()
    return
      (: do this in a separate transaction so that we can see notifications
       : and avoid creating double notifications
       :)
      xdmp:invoke-function(
        function() {
          matcher:save-match-notification($label, ($uri, $notify-uris))
        },
        map:new((map:entry("isolation", "different-transaction"), map:entry("update", "true")))
      ),

    let $actions := $matching-results/result/@action[fn:not(. = $const:NOTIFY-ACTION or . = $const:MERGE-ACTION)]
    for $action in fn:distinct-values($actions)
    let $action-xml := $matching-options//*:action[@name = $action]
    let $action-func :=
      fun-ext:function-lookup(
        fn:string($action-xml/@function),
        fn:string($action-xml/@namespace),
        fn:string($action-xml/@at),
        ()
      )
    let $filtered-matches := $matching-results/result[@action = $action]
    return
      if (fn:exists($filtered-matches)) then
        xdmp:invoke-function(
          function() {
            if (fn:ends-with(xdmp:function-module($action-func), "sjs")) then
              let $filtered-matches := proc-impl:matches-to-json($filtered-matches)
              let $options := merge-impl:options-to-json($options)
              return
                xdmp:apply($action-func, $uri, $filtered-matches, $options)
            else
              xdmp:apply($action-func, $uri, $filtered-matches, $options)
          },
          map:new((map:entry("isolation", "different-transaction"), map:entry("update", "true")))
        )
      else ()

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
