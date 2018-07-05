xquery version "1.0-ml";

(:
 : Test the custom sjs action feature.
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
let $options := merging:get-options($lib:OPTIONS-NAME-CUST-ACTION-SJS-MERGE, $const:FORMAT-XML)
let $merged-doc :=
  xdmp:invoke-function(
    function() {
      for $uri in map:keys($lib:TEST-DATA)
      return
        process:process-match-and-merge($uri, $lib:OPTIONS-NAME-CUST-ACTION-SJS-MERGE)
    },
    $lib:INVOKE_OPTIONS
  )

(: verifiy that the custom action was called :)
let $assertions := (
  $assertions,
  let $expected :=
    object-node {
      "uri": "/source/1/doc1.xml",
      "matches": array-node {
        "/source/2/doc2.xml"
      },
      "options": object-node {
        "options": object-node{
          "matchOptions": "custom-sjs-action-match-options",
          "propertyDefs": object-node {
            "property": object-node {
              "namespace": "",
              "localname": "Address",
              "name": "address"
            }
          },
          "merging": object-node {
            "merge": object-node {
              "propertyName": "address",
              "algorithmRef": "address",
              "maxValues": "1",
              "postalCode": object-node {
                "prefer": "zip+4"
              },
              "length": object-node {
                "weight":"8"
              },
              "doubleMetaphone": object-node {
                "distanceThreshold": "50"
              }
            }
          }
        }
      }
    }
  let $actual :=
    xdmp:invoke-function(function() {
      let $actual := fn:doc("/sjs-action-output.json")/object-node()
      return
        $actual
    }, $lib:INVOKE_OPTIONS)
  return
    test:assert-equal-json($expected, $actual)
)

return $assertions
