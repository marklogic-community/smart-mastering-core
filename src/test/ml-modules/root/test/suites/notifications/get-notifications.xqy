xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

let $actual := matcher:get-notifications(1, 10)
let $likely := $actual[sm:threshold-label = $lib:LBL-LIKELY]
let $possible := $actual[sm:threshold-label = $lib:LBL-POSSIBLE]

return (
  test:assert-equal(2, fn:count($actual)),

  test:assert-exists($likely),
  test:assert-equal(3, fn:count($likely/sm:document-uris/sm:document-uri)),
  test:assert-same-values(
    $lib:URI-SET1,
    $likely/sm:document-uris/sm:document-uri/fn:string()
  ),

  test:assert-exists($possible),
  test:assert-equal(2, fn:count($possible/sm:document-uris/sm:document-uri)),
  test:assert-same-values(
    $lib:URI-SET2,
    $possible/sm:document-uris/sm:document-uri/fn:string()
  )
)
