xquery version "1.0-ml";

import module namespace match-impl = "http://marklogic.com/smart-mastering/matcher-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/matcher-impl.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare option xdmp:mapping "false";

declare variable $GIVEN-QNAME := xs:QName("given");
declare variable $FAMILY-QNAME := xs:QName("family");
declare variable $NUMBER-QNAME := xs:QName("number");
declare variable $POSTAL-QNAME := xs:QName("postal");
declare variable $STATE-QNAME := xs:QName("state");

(:
 : Each $actual query should have the same element name and text as the corresponding $expected query
 :)
declare function local:verify-group($expected as cts:element-value-query*, $actual as cts:element-value-query*)
{
  if (fn:empty($actual)) then ()
  else
  (
    test:assert-equal(cts:element-value-query-element-name($expected[1]), cts:element-value-query-element-name($actual[1])),
    test:assert-equal(cts:element-value-query-text($expected[1]), cts:element-value-query-text($actual[1])),

    local:verify-group(fn:subsequence($actual, 2), fn:subsequence($expected, 2))
  )
};

let $given  := cts:element-value-query($GIVEN-QNAME, "LINDSEY", "case-insensitive", 12)
let $family := cts:element-value-query($FAMILY-QNAME, "JONES", "case-insensitive", 8)
let $number := cts:element-value-query($NUMBER-QNAME, "45", "case-insensitive", 5)
let $postal := cts:element-value-query($POSTAL-QNAME, "18505", "case-insensitive", 3)
let $state  := cts:element-value-query($STATE-QNAME, "PA", "case-insensitive")
let $remaining-queries := ($given, $family, $number, $postal, $state) ! element q { . }/node()
let $threshold := 15
let $actual := match-impl:filter-for-required-queries($remaining-queries, 0, $threshold, ())

let $assertions := (
  (: We should get back four groups of queries :)
  test:assert-equal(4, fn:count($actual)),

  (: Weights for $given + $family = 20 :)
  local:verify-group(($given, $family), cts:and-query-queries($actual[1])),

  (: Weights for $given + $number = 17 :)
  local:verify-group(($given, $number), cts:and-query-queries($actual[2])),

  (: Weights for $given + $postal = 15 :)
  local:verify-group(($given, $postal), cts:and-query-queries($actual[3])),

  (: Weights for $family + $number + $postal = 16 :)
  local:verify-group(($family, $number, $postal), cts:and-query-queries($actual[4]))

)

return $assertions
