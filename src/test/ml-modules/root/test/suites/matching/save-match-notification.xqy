xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
at "/ext/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace smart-mastering = "http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $threshold-label := "Definitive Match"
let $uris := ("/content1.xml", "/content2.xml")

let $_ :=
  xdmp:invoke-function(
    function() { matcher:save-match-notification($threshold-label, $uris) },
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
    </options>
  )

let $actual :=
  matcher:get-existing-match-notification(
    $threshold-label,
    $uris
  )

return (
  test:assert-equal(
    <smart-mastering:threshold-label>{$threshold-label}</smart-mastering:threshold-label>,
    $actual/smart-mastering:threshold-label
  ),
  test:assert-same-values($uris, $actual/smart-mastering:document-uris/smart-mastering:document-uri/fn:string())
)
