xquery version "1.0-ml";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/ext/com.marklogic.smart-mastering/merging.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

(: test getting all options :)
let $expected := test:get-test-file("sample-options.xml")/node()
let $actual := merging:get-options($const:FORMAT-XML)
let $assert-get-all-options := test:assert-equal-xml($expected, $actual)

(: test getting options by name :)
let $actual := merging:get-options("sample", $const:FORMAT-XML)
let $assert-get-named-options := test:assert-equal-xml($expected, $actual)


return (
  $assert-get-all-options,
  $assert-get-named-options
)
