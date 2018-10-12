xquery version "1.0-ml";

(:
 : Get the sources from JSON documents. The last-updated timestamp is in the instance, rather than the headers. We've
 : seen this come back unpopulated.
 :)

import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace merge-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare function local:assert-correct-source($actual)
{
  (
    test:assert-exists($actual/documentUri),
    let $doc := fn:doc($actual/documentUri/fn:string())
    return (
      test:assert-exists($doc),
      test:assert-equal($doc/envelope/headers/sources/name/fn:string(), $actual/name/fn:string()),
      test:assert-equal($doc/envelope/instance/Person/lastModified/fn:string(), $actual/dateTime/fn:string())
    )
  )
};

let $uris := map:keys($lib:TEST-DATA)
let $docs := $uris ! fn:doc(.)
let $options := merging:get-options($const:FORMAT-XML)
let $actual := merge-impl:get-sources($docs, $options)
return (
  test:assert-equal(fn:count($uris), fn:count($actual)),
  for $source in $actual
  return
    local:assert-correct-source($source)
)
