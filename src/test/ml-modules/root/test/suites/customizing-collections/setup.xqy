xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

import module namespace coll = "http://marklogic.com/smart-mastering/collections"
  at "/com.marklogic.smart-mastering/impl/collections.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

declare variable $MATCH-OPTIONS := test:get-test-file("match-options.xml")/node();

for $uri in map:keys($lib:XML-TEST-DATA)
let $doc := test:get-test-file(map:get($lib:XML-TEST-DATA, $uri))
return
  xdmp:document-insert(
    $uri,
    $doc,
    xdmp:default-permissions(),
    coll:content-collections($MATCH-OPTIONS)
  ),

for $uri in map:keys($lib:JSON-TEST-DATA)
let $doc := test:get-test-file(map:get($lib:JSON-TEST-DATA, $uri))
return
  xdmp:document-insert(
    $uri,
    $doc,
    xdmp:default-permissions(),
    coll:content-collections($MATCH-OPTIONS)
  )
