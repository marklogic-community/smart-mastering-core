xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace constants = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace es="http://marklogic.com/entity-services";
declare namespace sm="http://marklogic.com/smart-mastering";

declare option xdmp:update "true";

declare option xdmp:mapping "false";

(:
 : We're batching calls to process-match-and-merge. The first call merges $lib:URI2 and $lib:URI3. In the second call,
 : the match process will find $lib:URI2 as a match for $lib:URI3, but it should see that those two docs have already
 : been merged and do nothing.
 :)

let $actual :=
  xdmp:invoke-function(
    function() {
      <result>{process:process-match-and-merge($lib:URI2, $lib:MERGE-OPTIONS-NAME)}</result>,
      <result>{process:process-match-and-merge($lib:URI3, $lib:MERGE-OPTIONS-NAME)}</result>
    },
    $lib:INVOKE_OPTIONS
  )

return (
  test:assert-exists(($actual[1]/node())),
  test:assert-equal(xs:QName("es:envelope"), fn:node-name($actual[1]/node()[1])),
  test:assert-equal(xs:QName("sm:notification"), fn:node-name($actual[1]/node()[2])),
  test:assert-equal(xs:QName("sm:notification"), fn:node-name($actual[2]/node()[1])),
  test:assert-same-values(($lib:URI2, $lib:URI3), $actual[1]/es:envelope/es:headers/sm:merges/sm:document-uri/fn:string())
)
