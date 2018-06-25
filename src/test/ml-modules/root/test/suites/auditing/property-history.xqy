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

let $merged-uri := cts:uris((), "limit=1", cts:collection-query($const:MERGED-COLL))
let $actual as map:map := history:property-history($merged-uri)
return (
  test:assert-same-values($property-list, map:keys($actual))
)
