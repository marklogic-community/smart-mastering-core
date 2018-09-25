xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";

declare option xdmp:mapping "false";

(:~
 : Writer Plugin
 :
 : @param $id       - the identifier returned by the collector
 : @param $envelope - the final envelope
 : @param $options  - a map containing options. Options are sent from Java
 :
 : @return - nothing
 :)
declare function plugin:write(
  $id as xs:string,
  $envelope as node(),
  $options as map:map) as empty-sequence()
{
  (:
   : make sure the incoming document is in the appropriate
   : collections. We are doing this because the incoming
   : document could have already been merged with another
   : document since this batch flow was invoked. No need
   : to run it through again.
   :)
  let $doc-collections :=
    xdmp:invoke-function(function() {
      xdmp:document-get-collections($id)
    })
  where
    $doc-collections = $const:CONTENT-COLL and
    fn:not($doc-collections = $const:MERGED-COLL)
  return
    (: run smart mastering against the incoming document uri :)
    let $_ := process:process-match-and-merge($id, "mdm-merge-options", cts:collection-query("MDM"))

    (: writer wants us to return the empty sequence :)
    return ()
};
