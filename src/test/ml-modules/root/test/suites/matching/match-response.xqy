xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";
import module namespace constants = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare option xdmp:mapping "false";

let $doc := fn:doc($lib:URI2)
let $actual := matcher:find-document-matches-by-options-name($doc, $lib:MATCH-OPTIONS-NAME, fn:true())
return (
  test:assert-true($actual instance of element(results)),
  test:assert-equal($actual/@total/xs:int(.), fn:count($actual/result)),
  test:assert-equal($actual/@total/xs:int(.), 5),
  test:assert-not-exists($actual/result/@total),
  for $r at $i in $actual/result
  order by $r/@index/xs:int(.) ascending
  return
    test:assert-equal($i, $r/@index/xs:int(.))
)
