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
    test:assert-same-values(($lib:URI3, $lib:URI5, $lib:URI6) ! attribute uri {.}, $def-match/@uri),
    test:assert-equal(3, fn:count($def-match/@threshold[. = "Definitive Match"])),
    test:assert-equal(3, fn:count($def-match/@action[. = $constants:MERGE-ACTION]))
  ),

  let $likely-match := $actual/results[@threshold="Likely Match"]
  return (
    test:assert-same-values(($lib:URI1, $lib:URI4) ! attribute uri {.}, $likely-match/@uri),
    test:assert-equal(2, fn:count($likely-match/@threshold[. = "Likely Match"])),
    test:assert-equal(2, fn:count($likely-match/@action[. = $constants:NOTIFY-ACTION]))
  )
)
