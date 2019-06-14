xquery version "1.0-ml";

import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare option xdmp:mapping "false";

declare variable $success-map := map:map();

try {
  let $uris := cts:uris((), (), cts:collection-query($const:CONTENT-COLL))
  let $_process := process:process-match-and-merge($uris, $lib:BAD-ENTITY-OPTIONS-NAME)
  return map:put(
    $success-map,
    "Not thrown: " || fn:string($const:ENTITY-NOT-FOUND-ERROR),
    fn:true()
  )
} catch ($e) {
  test:assert-equal(fn:string($e/*:name), fn:string($const:ENTITY-NOT-FOUND-ERROR))
},
for $key in map:keys($success-map)
return
  test:assert-equal($key, ())
