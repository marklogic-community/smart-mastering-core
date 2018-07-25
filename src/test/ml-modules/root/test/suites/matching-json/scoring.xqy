xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace constants = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare option xdmp:mapping "false";

let $doc := fn:doc($lib:URI2)
let $options := matcher:get-options-as-xml($lib:SCORE-OPTIONS-NAME)
let $max-score := fn:sum($options//*:add/@weight)
let $actual := matcher:find-document-matches-by-options-name($doc, $lib:SCORE-OPTIONS-NAME)
let $score := $actual//result[@uri=$lib:URI3]/@score/xs:int(.)
return (
  test:assert-equal($max-score, $score)
),

let $doc := fn:doc($lib:URI2)
let $options := matcher:get-options-as-xml($lib:SCORE-OPTIONS-NAME2)
let $max-score := fn:sum($options//*:add/@weight)
let $actual := matcher:find-document-matches-by-options-name($doc, $lib:SCORE-OPTIONS-NAME2)
let $score := $actual//result[@uri=$lib:URI3]/@score/xs:int(.)
return (
  test:assert-equal($max-score, $score)
)
