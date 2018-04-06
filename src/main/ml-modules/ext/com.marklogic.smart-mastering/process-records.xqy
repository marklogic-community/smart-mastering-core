xquery version '1.0-ml';

module namespace process = "http://marklogic.com/smart-mastering/process-records";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "matcher.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "survivorship/merging/base.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
at "/ext/com.marklogic.smart-mastering/constants.xqy";

declare option xdmp:mapping "false";

declare function process:process-match-and-merge($uri as xs:string)
{
  for $merging-options in merging:get-options()
  return
    process:process-match-and-merge($uri, $merging-options)
};

declare function process:process-match-and-merge($uri as xs:string, $options as item())
{
  let $matching-options := matcher:get-options(fn:string($options/merging:match-options))
  let $thresholds := $options/merging:thresholds/merging:threshold[@action = ($const:MERGE-ACTION, $const:NOTIFY-ACTION)]
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
      $lock-on-query
    )
  return (
    for $threshold in $thresholds
    let $threshold-label := $threshold/@label
    let $threshold-action := $threshold/@action
    let $document-uris :=
        $matching-results
        /*:results[@threshold = $threshold-label]
        /@uri ! fn:string(.)
    where fn:exists($document-uris)
    return (
      if ($threshold-action = $const:MERGE-ACTION) then
        merging:save-merge-models-by-uri(
          ($uri,
          $document-uris),
          $options
        )
      else if ($threshold-action = $const:NOTIFY-ACTION) then
        matcher:save-match-notification(
          $threshold-label,
          ($uri, $document-uris)
        )
      else ()
    )
  )
};
