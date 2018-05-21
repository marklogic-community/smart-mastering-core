xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";
import module namespace constants = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare option xdmp:mapping "false";

let $doc := fn:doc($lib:URI2)
let $actual := matcher:find-document-matches-by-options-name($doc, $lib:MATCH-OPTIONS-NAME)
return (
  let $def-match := $actual/results[@threshold="Definitive Match"]
  return (
    test:assert-equal(attribute uri {$lib:URI3}, $def-match/@uri),
    test:assert-equal(attribute threshold {"Definitive Match"}, $def-match/@threshold),
    test:assert-equal(attribute action {$constants:MERGE-ACTION}, $def-match/@action)
  ),

  let $likely-match := $actual/results[@threshold="Likely Match"]
  return (
    test:assert-equal(attribute uri {$lib:URI1}, $likely-match/@uri),
    test:assert-equal(attribute threshold {"Likely Match"}, $likely-match/@threshold),
    test:assert-equal(attribute action {$constants:NOTIFY-ACTION}, $likely-match/@action)
  )
)
