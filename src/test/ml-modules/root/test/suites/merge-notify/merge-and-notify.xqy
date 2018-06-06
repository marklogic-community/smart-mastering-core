xquery version "1.0-ml";

(:
 : Scenario: We run process-match-and-merge on a document (doc1.xml). One other document (doc2.xml) scores high enough
 : to be automatically merged. Another document (doc3.xml) scores high enough to generate a notification.
 :
 : Desired result:
 :   - create merged document (doc12.xml)
 :   - create notification that refers to the merged doc instead of the original (doc3.xml, doc12.xml)
 :)

import module namespace constants = "http://marklogic.com/smart-mastering/constants"
at "/ext/com.marklogic.smart-mastering/constants.xqy";
import module namespace process = "http://marklogic.com/smart-mastering/process-records"
at "/ext/com.marklogic.smart-mastering/process-records.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace es="http://marklogic.com/entity-services";
declare namespace sm="http://marklogic.com/smart-mastering";

declare option xdmp:update "true";

declare option xdmp:mapping "false";

declare variable $MERGED-QNAME := xs:QName("es:envelope");
declare variable $NOTIFY-QNAME := xs:QName("sm:notification");

let $actual :=
  xdmp:invoke-function(
    function() { process:process-match-and-merge($lib:URI1, $lib:MERGE-OPTIONS-NAME) },
    $lib:INVOKE_OPTIONS
  )

let $merged := $actual[1]
let $notify := $actual[2]

let $merged-uri := cts:uris((), (), cts:element-value-query(xs:QName("sm:id"), $merged/es:headers/sm:id/fn:string()))


return (
  test:assert-equal($MERGED-QNAME, fn:node-name($merged)),
  test:assert-equal($NOTIFY-QNAME, fn:node-name($notify)),

  test:assert-same-values(($lib:URI1, $lib:URI2), $merged/es:headers/sm:merges/sm:document-uri/fn:string()),

  test:assert-same-values(($merged-uri, $lib:URI3), $notify/sm:document-uris/sm:document-uri/fn:string())

)
