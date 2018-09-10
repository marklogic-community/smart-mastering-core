xquery version "1.0-ml";

(:
 : Purpose of test: see MDM-491. Boost query was being generated incorrectly.
 :)

import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

let $actual :=
  matcher:find-document-matches-by-options-name(
    fn:doc($lib:URI1),
    $lib:MATCH-OPTIONS-NAME,
    fn:true(),
    cts:collection-query($lib:ORG-COLL)
)
let $_ := xdmp:log("boost-query. actual=" || xdmp:quote($actual))
return (
  test:assert-equal(1, $actual/@total/fn:data()),
  test:assert-equal(1, fn:count($actual/result)),
  test:assert-equal(30, $actual/result/@score/fn:data())
)
