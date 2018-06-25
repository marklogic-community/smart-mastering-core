xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace constants = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare option xdmp:mapping "false";

let $doc := fn:doc($lib:URI2)
let $options := matcher:get-options-as-xml($lib:MATCH-OPTIONS-NAME)
return (
  (: test page length gt # of results :)
  let $actual := matcher:find-document-matches-by-options($doc, $options, 1, 6, fn:true())
  return (
    test:assert-true($actual instance of element(results)),
    test:assert-equal(6, $actual/@page-length/xs:int(.)),
    test:assert-equal(5, fn:count($actual/result)),
    test:assert-equal(1, $actual/@start/xs:int(.)),
    test:assert-equal(5, $actual/@total/xs:int(.)),
    test:assert-not-exists($actual/result/@total),
    for $r at $i in $actual/result
    order by $r/@index/xs:int(.) ascending
    return
      test:assert-equal($i, $r/@index/xs:int(.))
  ),

  (: test page length < # of results :)
  let $actual := matcher:find-document-matches-by-options($doc, $options, 1, 2, fn:true())
  return (
    test:assert-true($actual instance of element(results)),
    test:assert-equal(2, $actual/@page-length/xs:int(.)),
    test:assert-equal(2, fn:count($actual/result)),
    test:assert-equal(1, $actual/@start/xs:int(.)),
    test:assert-equal(5, $actual/@total/xs:int(.)),
    test:assert-not-exists($actual/result/@total),
    for $r at $i in $actual/result
    order by $r/@index/xs:int(.) ascending
    return
      test:assert-equal($i, $r/@index/xs:int(.))
  ),

  (: test last page :)
  let $actual := matcher:find-document-matches-by-options($doc, $options, 5, 2, fn:true())
  return (
    test:assert-true($actual instance of element(results)),
    test:assert-equal(2, $actual/@page-length/xs:int(.)),
    test:assert-equal(1, fn:count($actual/result)),
    test:assert-equal(5, $actual/@start/xs:int(.)),
    test:assert-equal(5, $actual/@total/xs:int(.)),
    test:assert-not-exists($actual/result/@total),
    for $r at $i in $actual/result
    order by $r/@index/xs:int(.) ascending
    return
      test:assert-equal($i + 4, $r/@index/xs:int(.))
  ),

  (: test no results :)
  let $doc := fn:doc($lib:URI7)
  let $actual := matcher:find-document-matches-by-options($doc, $options, 5, 2, fn:true())
  return (
    test:assert-true($actual instance of element(results)),
    test:assert-equal(2, $actual/@page-length/xs:int(.)),
    test:assert-equal(0, fn:count($actual/result)),
    test:assert-equal(5, $actual/@start/xs:int(.)),
    test:assert-equal(0, $actual/@total/xs:int(.)),
    test:assert-not-exists($actual/result/@total)
  )
)
