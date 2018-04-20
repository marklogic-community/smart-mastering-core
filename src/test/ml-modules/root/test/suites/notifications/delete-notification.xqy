xquery version "1.0-ml";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $initial1 := lib:get-notification($lib:LBL-LIKELY, $lib:URI-SET1)
let $initial2 := lib:get-notification($lib:LBL-POSSIBLE, $lib:URI-SET2)

let $assertions := (
  test:assert-equal(1, fn:count($initial1)),
  test:assert-equal(1, fn:count($initial2))
)

(: Delete the first notification :)
let $_ := lib:delete-notification(fn:base-uri($initial1))

(: Verify that the first notification was deleted, but the second is still there. :)
let $post-delete-1 := lib:get-notification($lib:LBL-LIKELY, $lib:URI-SET1)
let $post-delete-2 := lib:get-notification($lib:LBL-POSSIBLE, $lib:URI-SET2)

let $assertions := (
  $assertions,
  test:assert-equal(0, fn:count($post-delete-1)),
  test:assert-equal(1, fn:count($post-delete-2))
)

return $assertions
