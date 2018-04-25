xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
at "/ext/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

declare namespace smart-mastering="http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $notification := lib:get-notification($lib:LBL-LIKELY, $lib:URI-SET1)

(: Verify starting state :)
let $assertions := (
  test:assert-equal(
    element smart-mastering:status { $matcher:STATUS-UNREAD },
    $notification/smart-mastering:meta/smart-mastering:status
  )
)

let $_ :=
  xdmp:invoke-function(
    function() {
      matcher:update-notification-status(fn:base-uri($notification), $matcher:STATUS-READ)
    },
    $lib:INVOKE_OPTIONS
  )

let $notification := lib:get-notification($lib:LBL-LIKELY, $lib:URI-SET1)

let $assertions := (
  $assertions,
  test:assert-equal(
    element smart-mastering:status { $matcher:STATUS-READ },
    $notification/smart-mastering:meta/smart-mastering:status
  )
)

return $assertions
