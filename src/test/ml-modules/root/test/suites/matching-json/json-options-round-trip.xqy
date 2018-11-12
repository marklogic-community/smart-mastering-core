xquery version "1.0-ml";

(:
 : Match options are stored in the database as XML, but may be uploaded or
 : downloaded by a client as JSON. Make sure the round-trip transformations
 : are done correctly.
 :)

import module namespace match = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare variable $options := test:get-test-file("match-options.json")/object-node();

(: Save JSON options, which will get them written as XML :)
match:save-options("json-options", $options);

xquery version "1.0-ml";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";
import module namespace match = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

(: Retrieve options, requesting JSON format, so they will be converted back to
 : JSON.
 :)

let $expected := test:get-test-file("match-options.json")/node()
let $actual := match:get-options("json-options", $const:FORMAT-JSON)
return test:assert-equal-json($expected, $actual)
