xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

declare namespace smart-mastering = "http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $threshold-label := "Definitive Match"
let $uris := ("/content1.xml", "/content2.xml")

(: Save a notification :)
let $_ := lib:save-notification($threshold-label, $uris)

(: Read it back :)
let $actual := lib:get-notification($threshold-label, $uris)

(: Make sure we got what we expected :)
let $assertions := (
  test:assert-equal(
    <smart-mastering:threshold-label>{$threshold-label}</smart-mastering:threshold-label>,
    $actual/smart-mastering:threshold-label
  ),
  test:assert-same-values($uris, $actual/smart-mastering:document-uris/smart-mastering:document-uri/fn:string())
)

(: Save an overlapping notification. It should get combined with the first. :)
let $_ := lib:save-notification($threshold-label, ("/content1.xml", "/content3.xml"))

(: Read it back :)
let $actual := lib:get-notification($threshold-label, $uris)

return (
  $assertions,
  test:assert-equal(
    <smart-mastering:threshold-label>{$threshold-label}</smart-mastering:threshold-label>,
    $actual/smart-mastering:threshold-label
  ),
  test:assert-same-values(
    ($uris, "/content3.xml"),
    $actual/smart-mastering:document-uris/smart-mastering:document-uri/fn:string()
  )
)
