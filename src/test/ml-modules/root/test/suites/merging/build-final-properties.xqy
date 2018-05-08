xquery version "1.0-ml";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

declare option xdmp:mapping "false";

let $uris := map:keys($lib:TEST-DATA)
let $docs := $uris ! fn:doc(.)
let $merge-options := merging:get-options($lib:OPTIONS-NAME)
let $sources := merging:get-sources($docs)
let $actual := merging:build-final-properties(
  $merge-options,
  merging:get-instances($docs),
  $docs,
  $sources
)
(: top-level-properties: PersonName, Address, IncidentCategoryCodeDate, id, PersonBirthDate, CaseAmount, PersonSSNIdentification, Revenues, CaseStartDate, PersonSex :)

let $revenue-map :=
  for $map in $actual
  where map:contains(-$map, "Revenues")
  return $map
return (
  test:assert-equal(10, fn:count($actual)),
  test:assert-exists($revenue-map),
  test:assert-equal(1, fn:count(map:get($revenue-map, "sources"))),
  test:assert-equal("SOURCE2", map:get(map:get($revenue-map, "sources"), "name"))
)
