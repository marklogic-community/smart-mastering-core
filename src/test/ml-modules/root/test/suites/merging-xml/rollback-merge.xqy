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
      merging:save-merge-models-by-uri(
        map:keys($lib:TEST-DATA),
        merging:get-options($lib:OPTIONS-NAME, $const:FORMAT-XML))
    },
    $lib:INVOKE_OPTIONS
  )

let $assertions := xdmp:eager(
  let $smid := $merged-doc/es:headers/sm:id/fn:string()
  let $s1-dt := $merged-doc//sm:source[sm:name = "SOURCE1"]/sm:dateTime/fn:string()
  let $s2-dt := $merged-doc//sm:source[sm:name = "SOURCE2"]/sm:dateTime/fn:string()
  let $expected := <es:envelope xmlns:es="http://marklogic.com/entity-services"><es:headers><sm:id xmlns:sm="http://marklogic.com/smart-mastering">{$smid}</sm:id><sm:merges xmlns:sm="http://marklogic.com/smart-mastering"><sm:document-uri>/source/2/doc2.xml</sm:document-uri><sm:document-uri>/source/1/doc1.xml</sm:document-uri></sm:merges><sm:sources xmlns:sm="http://marklogic.com/smart-mastering"><sm:source><sm:name>SOURCE2</sm:name><sm:import-id>mdm-import-b96735af-f7c3-4f95-9ea1-f884bc395e0f</sm:import-id><sm:user>admin</sm:user><sm:dateTime>{$s2-dt}</sm:dateTime></sm:source><sm:source><sm:name>SOURCE1</sm:name><sm:import-id>mdm-import-8cf89514-fb1d-45f1-b95f-8b69f3126f04</sm:import-id><sm:user>admin</sm:user><sm:dateTime>{$s1-dt}</sm:dateTime></sm:source></sm:sources></es:headers><es:instance><MDM><Person><PersonType><PersonName><PersonNameType><PersonSurName>JONES</PersonSurName><PersonGivenName>LINDSEY</PersonGivenName></PersonNameType></PersonName><Address><AddressType><LocationState>PA</LocationState><AddressPrivateMailboxText>45</AddressPrivateMailboxText><AddressSecondaryUnitText>JANA</AddressSecondaryUnitText><LocationPostalCode>18505</LocationPostalCode><LocationCityName>SCRANTON</LocationCityName></AddressType></Address><id>6270654339</id><id>6986792174</id><PersonBirthDate>19801001</PersonBirthDate><CaseAmount>1287.9</CaseAmount><CustomThing>2</CustomThing><CustomThing>1</CustomThing><PersonSSNIdentification><PersonSSNIdentificationType><IdentificationID>393225353</IdentificationID></PersonSSNIdentificationType></PersonSSNIdentification><Revenues><RevenuesType><Revenue>4332</Revenue></RevenuesType></Revenues><CaseStartDate>20110406</CaseStartDate><PersonSex>F</PersonSex></PersonType></Person></MDM></es:instance></es:envelope>
  return
    test:assert-equal-xml($expected, $merged-doc)
)

let $merged-id := $merged-doc/es:headers/sm:id
let $merged-uri := $merging-impl:MERGED-DIR || $merged-id || ".xml"

(: At this point, there should be no blocks :)
let $assertions := xdmp:eager(
  map:keys($lib:TEST-DATA) ! test:assert-not-exists(matcher:get-blocks(.)/node())
)

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
