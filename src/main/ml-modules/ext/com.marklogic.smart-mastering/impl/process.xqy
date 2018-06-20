xquery version "1.0-ml";

module namespace proc-impl = "http://marklogic.com/smart-mastering/process-records/impl";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/ext/com.marklogic.smart-mastering/merging.xqy";

declare option xdmp:mapping "false";

declare function proc-impl:process-match-and-merge($uri as xs:string)
  as element()*
{
  for $merging-options in merging:get-options($const:FORMAT-XML)
  return
    proc-impl:process-match-and-merge($uri, $merging-options)
};

declare function proc-impl:process-match-and-merge($uri as xs:string, $option-name as xs:string)
  as item()*
{
  proc-impl:process-match-and-merge-with-options(
    $uri,
    merging:get-options($option-name, $const:FORMAT-XML)
  )
};

(:
 : The workhorse function.
 :)
declare function proc-impl:process-match-and-merge-with-options($uri as xs:string, $options as item())
{
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
      fn:false()
    )
  let $merge-uris as xs:string* := $matching-results/result[@action = $const:MERGE-ACTION]/@uri/fn:string()
  let $notifies := $matching-results/result[@action = $const:NOTIFY-ACTION]
  return (
    (: Must do merges before notifications so that notifications can update
     : their URI references for docs that got merged. Those merges are done
     : in a separate transaction so that they'll be visible.
     :)
    if (fn:exists($merge-uris)) then
      merging:save-merge-models-by-uri(
        ($uri, $merge-uris),
        $options
      )
    else (),

    let $threshold-labels := fn:distinct-values($notifies/@threshold/fn:string())
    for $label in $threshold-labels
    let $notify-uris := $notifies[@threshold eq $label]/@uri/fn:string()
    return
      matcher:save-match-notification(
        $label,
        ($uri, $notify-uris)
      )
  )
};
