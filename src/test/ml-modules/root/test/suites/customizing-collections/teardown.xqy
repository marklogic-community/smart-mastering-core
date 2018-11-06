xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace sem = "http://marklogic.com/semantics"
  at "/MarkLogic/semantics.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

let $custom-collections := fn:distinct-values((
    for $name in map:keys($lib:MATCH-OPTIONS)
    let $options := test:get-test-file(map:get($lib:MATCH-OPTIONS, $name))
    return
      $options/*:options/*:collections/* ! fn:string(.),
    for $name in map:keys($lib:MERGE-OPTIONS)
    let $options := test:get-test-file(map:get($lib:MERGE-OPTIONS, $name))
    return
      $options/*:options/*:collections/* ! fn:string(.)
  ))[. ne '']
for $custom-collection in $custom-collections
return xdmp:collection-delete($custom-collection),
xdmp:directory-delete("/source/"),
xdmp:collection-delete($const:CONTENT-COLL),
xdmp:collection-delete($const:ARCHIVED-COLL),
xdmp:collection-delete($const:AUDITING-COLL),
xdmp:collection-delete($const:MERGED-COLL),
sem:graph-delete(sem:iri("http://marklogic.com/semantics#default-graph")),
for $uri in ("/xqy-action-output.xml", "/sjs-action-output.json")
return
  if (fn:doc-available($uri)) then
    xdmp:document-delete($uri)
  else ()
