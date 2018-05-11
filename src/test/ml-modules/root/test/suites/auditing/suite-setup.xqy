xquery version "1.0-ml";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

merging:save-options($lib:OPTIONS-NAME, test:get-test-file("merge-options.xml")),

for $uri in map:keys($lib:TEST-DATA)
let $doc := test:get-test-file(map:get($lib:TEST-DATA, $uri))
return
  xdmp:document-insert(
    $uri,
    $doc,
    xdmp:default-permissions(),
    $const:CONTENT-COLL
  )
