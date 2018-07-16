xquery version "1.0-ml";

import module namespace history = "http://marklogic.com/smart-mastering/auditing/history"
  at "/com.marklogic.smart-mastering/auditing/history.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare variable $property-list := (
  "CaseStartDate", "Address", "PersonSex", "PersonBirthDate", "PersonName", "CaseAmount",
  "PersonSSNIdentification", "Revenues", "id"
);

declare option xdmp:mapping "false";

let $assertions := ()

let $merged-uri := cts:uris((), "limit=1", cts:collection-query($const:MERGED-COLL))
let $actual as map:map := history:property-history($merged-uri)
let $assertions := (
  $assertions,
  test:assert-same-values($property-list, map:keys($actual))
)

(: normalize-value-for-tracing should not return empty for text nodes :)
let $assertions := (
  $assertions,
  test:assert-equal('textValue', history:normalize-value-for-tracing(text{'textValue'}))
)

return $assertions
