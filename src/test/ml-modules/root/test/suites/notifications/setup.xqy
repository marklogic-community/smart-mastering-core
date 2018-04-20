xquery version "1.0-ml";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare option xdmp:mapping "false";

matcher:save-match-notification($lib:LBL-LIKELY, $lib:URI-SET1),
matcher:save-match-notification($lib:LBL-POSSIBLE, $lib:URI-SET2)
