xquery version "1.0-ml";

(:
 : Test the custom xqy action feature.
 :)

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare namespace es = "http://marklogic.com/entity-services";
declare namespace sm = "http://marklogic.com/smart-mastering";

(: Force update mode :)
declare option xdmp:update "true";

declare option xdmp:mapping "false";

let $assertions :=
  test:assert-false(xdmp:invoke-function(function() {
    fn:doc-available("/sjs-action-output.json")
  }, $lib:INVOKE_OPTIONS))

(: Merge a couple documents :)
let $merged-doc :=
  xdmp:invoke-function(
    function() {
      for $uri in map:keys($lib:TEST-DATA)
      return
        process:process-match-and-merge($uri, $lib:OPTIONS-NAME-CUST-ACTION-XQY-MERGE)
    },
    $lib:INVOKE_OPTIONS
  )

(: verifiy that the custom action was called :)
let $assertions := (
  $assertions,
  let $expected :=
    <test uri="/source/1/doc1.xml">
      <uri>/source/2/doc2.xml</uri>
      <options xmlns="http://marklogic.com/smart-mastering/merging">
        <match-options>custom-xqy-action-match-options</match-options>
        <property-defs>
          <property namespace="" localname="IdentificationID" name="ssn"/>
          <property namespace="" localname="PersonName" name="name"/>
          <property namespace="" localname="Address" name="address"/>
        </property-defs>
        <merging>
          <merge property-name="ssn" algorithm-ref="user-defined">
            <source-ref document-uri="docA" />
          </merge>
          <merge property-name="name"  max-values="1">
            <double-metaphone>
              <distance-threshold>50</distance-threshold>
            </double-metaphone>
            <synonyms-support>true</synonyms-support>
            <thesaurus>/mdm/config/thesauri/first-name-synonyms.xml</thesaurus>
            <length weight="8" />
          </merge>
          <merge property-name="address" algorithm-ref="address" max-values="1">
            <postal-code prefer="zip+4" />
            <length weight="8" />
            <double-metaphone>
              <distance-threshold>50</distance-threshold>
            </double-metaphone>
          </merge>
        </merging>
      </options>
    </test>
  let $actual :=
    xdmp:invoke-function(function() {
      fn:doc("/xqy-action-output.xml")/*
    }, $lib:INVOKE_OPTIONS)
  return
    test:assert-equal-xml($expected, $actual)
)

return $assertions
