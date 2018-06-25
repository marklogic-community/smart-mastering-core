xquery version "1.0-ml";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $notification := lib:get-notification($lib:LBL-LIKELY, $lib:URI-SET1)

(: Verify starting state :)
let $assertions := (
  test:assert-equal(
    element sm:status { $const:STATUS-UNREAD },
    $notification/sm:meta/sm:status
  )
)

let $_ :=
  xdmp:invoke-function(
    function() {
      matcher:update-notification-status(fn:base-uri($notification), $const:STATUS-READ)
    },
    $lib:INVOKE_OPTIONS
  )

let $notification := lib:get-notification($lib:LBL-LIKELY, $lib:URI-SET1)

let $assertions := (
  $assertions,
  test:assert-equal(
    element sm:status { $const:STATUS-READ },
    $notification/sm:meta/sm:status
  )
)

return $assertions
