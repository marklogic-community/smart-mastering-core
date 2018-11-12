xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

for $name in map:keys($lib:MATCH-OPTIONS)
let $options := test:get-test-file(map:get($lib:MATCH-OPTIONS, $name))
return
  matcher:save-options($name, $options),

for $name in map:keys($lib:MERGE-OPTIONS)
let $options := test:get-test-file(map:get($lib:MERGE-OPTIONS, $name))
return
  merging:save-options($name, $options)
