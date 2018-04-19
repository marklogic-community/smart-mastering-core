xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace smart-mastering="http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $label1 := "Likely Match"
let $label2 := "Possible Match"

let $uri-set1 := ("/content1.xml", "/content2.xml", "/content3.xml")
let $uri-set2 := ("/content4.xml", "/content5.xml")

(: Record a couple notifications :)
let $_ :=
  xdmp:invoke-function(
    function() {
      matcher:save-match-notification($label1, $uri-set1),
      matcher:save-match-notification($label2, $uri-set2)
    },
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
    </options>
  )

let $actual := matcher:get-notifications(1, 10)
let $likely := $actual[smart-mastering:threshold-label = $label1]
let $possible := $actual[smart-mastering:threshold-label = $label2]

return (
  test:assert-equal(2, fn:count($actual)),

  test:assert-exists($likely),
  test:assert-equal(3, fn:count($likely/smart-mastering:document-uris/smart-mastering:document-uri)),
  test:assert-same-values(
    $uri-set1,
    $likely/smart-mastering:document-uris/smart-mastering:document-uri/fn:string()
  ),

  test:assert-exists($possible),
  test:assert-equal(2, fn:count($possible/smart-mastering:document-uris/smart-mastering:document-uri)),
  test:assert-same-values(
    $uri-set2,
    $possible/smart-mastering:document-uris/smart-mastering:document-uri/fn:string()
  )
)
