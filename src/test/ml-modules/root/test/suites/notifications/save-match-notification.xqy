xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $threshold-label := "Definitive Match"
let $uris := ("/content1.xml", "/content2.xml")

let $count1 := matcher:count-notifications()

(: Save a notification :)
let $_ := lib:save-notification($threshold-label, $uris)

(: Read it back :)
let $actual := lib:get-notification($threshold-label, $uris)

let $count2 := matcher:count-notifications()

(: Make sure we got what we expected :)
let $assertions := (
  test:assert-equal(
    <sm:threshold-label>{$threshold-label}</sm:threshold-label>,
    $actual/sm:threshold-label
  ),
  test:assert-same-values($uris, $actual/sm:document-uris/sm:document-uri/fn:string()),
  test:assert-true($count1 + 1 = $count2)
)

(: Save an overlapping notification. It should get combined with the first. :)
let $_ := lib:save-notification($threshold-label, ("/content1.xml", "/content3.xml"))

(: Read it back :)
let $actual := lib:get-notification($threshold-label, $uris)

let $count3 := matcher:count-notifications()

return (
  $assertions,
  test:assert-equal(
    <sm:threshold-label>{$threshold-label}</sm:threshold-label>,
    $actual/sm:threshold-label
  ),
  test:assert-same-values(
    ($uris, "/content3.xml"),
    $actual/sm:document-uris/sm:document-uri/fn:string()
  ),
  test:assert-equal($count2, $count3)
)
