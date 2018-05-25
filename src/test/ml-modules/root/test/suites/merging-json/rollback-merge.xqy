xquery version "1.0-ml";

(:
 : Test the merging:rollback-merge function.
 :)

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/ext/com.marklogic.smart-mastering/merging.xqy";
import module namespace merging-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare namespace es = "http://marklogic.com/entity-services";
declare namespace sm = "http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

(: Merge a couple documents :)
let $merged-doc :=
  xdmp:invoke-function(
    function() {
      document {
        merging:save-merge-models-by-uri(
          map:keys($lib:TEST-DATA),
          merging:get-options($lib:OPTIONS-NAME, $const:FORMAT-XML))
      }
    },
    $lib:INVOKE_OPTIONS
  )

let $assertions := xdmp:eager(()
(: TODO: uncomment me when https://github.com/marklogic-community/ml-unit-test/issues/19 is fixed
  let $smid := $merged-doc/*:envelope/*:headers/*:id/fn:string()
  let $s1-dt := $merged-doc//*:source[*:name = "SOURCE1"]/*:dateTime/fn:string()
  let $s2-dt := $merged-doc//*:source[*:name = "SOURCE2"]/*:dateTime/fn:string()
  let $expected := xdmp:to-json(xdmp:from-json-string('{"envelope":{"headers":{"id":"' || $smid || '","merges":[{"document-uri":"/source/1/doc1.json"},{"document-uri":"/source/2/doc2.json"}],"sources":[{"name":"SOURCE2","import-id":"mdm-import-b96735af-f7c3-4f95-9ea1-f884bc395e0f","user":"admin","dateTime":"' || $s2-dt || '"},{"name":"SOURCE1","import-id":"mdm-import-8cf89514-fb1d-45f1-b95f-8b69f3126f04","user":"admin","dateTime":"' || $s1-dt || '"}]}, "instance":{"MDM":{"Person":{"PersonType":{"Address":{"AddressType":{"AddressPrivateMailboxText":"45","AddressSecondaryUnitText":"JANA","LocationCityName":"SCRANTON","LocationPostalCode":"18505","LocationState":"PA"}}, "CaseAmount": 1287.9, "CaseStartDate":"20110406","CustomThing":["2","1"],"PersonBirthDate":"19801001","PersonName":{"PersonNameType":{"PersonGivenName":"LINDSEY","PersonSurName":"JONES"}}, "PersonSSNIdentification":{"PersonSSNIdentificationType":{"IdentificationID":"393225353"}}, "PersonSex":"F","Revenues":{"RevenuesType":{"Revenue":"4332"}}, "id":["6270654339","6986792174"]}}}}}}'))
  return
    test:assert-equal-json($expected, $merged-doc)
:)
)

let $merged-id := $merged-doc/*:envelope/*:headers/*:id
let $merged-uri := $merging-impl:MERGED-DIR || $merged-id || ".xml"

(: At this point, there should be no blocks :)
let $assertions := ( $assertions, xdmp:eager(
  map:keys($lib:TEST-DATA) ! test:assert-not-exists(matcher:get-blocks(.)/node())
))

let $unmerge :=
  xdmp:invoke-function(
    function() {
      merging:rollback-merge($merged-uri, fn:true())
    },
    $lib:INVOKE_OPTIONS
  )

(: And now there should be blocks :)
let $assertions := (
  $assertions,
  map:keys($lib:TEST-DATA) ! test:assert-exists(matcher:get-blocks(.)/node())
)
return $assertions
