xquery version "1.0-ml";

(:
 : Verify that the configured content collection name is being used.
 :)

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

import module namespace coll = "http://marklogic.com/smart-mastering/collections"
  at "/com.marklogic.smart-mastering/impl/collections.xqy";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

let $doc := fn:doc("/source/1/doc1.xml")

(: The document that should be found is in a non-standard collection. If the match is found, then we know we're
 : looking in the right collection. :)
let $actual := matcher:find-document-matches-by-options-name($doc, $lib:XML-MATCH-OPT-NAME)

return (
  test:assert-equal(1, $actual/@total/fn:data())
)
