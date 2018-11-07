xquery version "1.0-ml";

(:
 : Verify that the collection algorithms are used for merge is done.
 :)

import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";

let $merge-options := merging:get-options($lib:XML-MERGE-OPT-NAME, $const:FORMAT-XML)
let $merge-uris := map:keys($lib:JSON-TEST-DATA)[fn:not(. eq $lib:NO-MATCH-URI)]
let $merge := (
    process:process-match-and-merge($lib:NO-MATCH-URI, $lib:JSON-MERGE-OPT-NAME),
    merging:save-merge-models-by-uri($merge-uris, $merge-options)
  )
return ()
;

import module namespace coll = "http://marklogic.com/smart-mastering/collections"
  at "/com.marklogic.smart-mastering/impl/collections.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare function local:order($strings as xs:string*)
{
  for $str in $strings
  order by $str
  return $str
};

let $merge-options := merging:get-options($lib:JSON-MERGE-OPT-NAME, $const:FORMAT-XML)
let $achived-uris := map:keys($lib:JSON-TEST-DATA)[fn:not(. eq $lib:NO-MATCH-URI)]
let $achived-collections := fn:distinct-values($achived-uris ! xdmp:document-get-collections(.))
let $assertions := (
  test:assert-equal(xdmp:estimate(fn:collection($lib:ALGORITHM-MERGE-COLLECTION)), 1),
  test:assert-equal(xdmp:estimate(fn:collection($lib:ALGORITHM-NO-MATCH-COLLECTION)), 1),
  test:assert-equal(local:order($achived-collections), local:order(("custom-archived",coll:archived-collections($merge-options))))
)
return ()


