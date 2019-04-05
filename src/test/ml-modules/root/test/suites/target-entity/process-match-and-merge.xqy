xquery version "1.0-ml";

import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare option xdmp:mapping "false";

let $uris := cts:uris((), (), cts:collection-query($const:CONTENT-COLL))
let $_process := process:process-match-and-merge($uris, $lib:OPTIONS-NAME)
return ();


import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

test:assert-equal(xdmp:estimate(fn:collection($const:MERGED-COLL)), 1),
let $merged-doc-instance := fn:collection($const:MERGED-COLL)/envelope/instance
let $name-instance := $merged-doc-instance/PersonType/PersonName/PersonNameType
return (
  test:assert-equal(fn:string($name-instance/PersonSurName), "JONES"),
  test:assert-equal(fn:string($name-instance/PersonGivenName), "LINDSEY")
)
