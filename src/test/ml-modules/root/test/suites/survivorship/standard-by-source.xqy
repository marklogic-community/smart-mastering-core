xquery version "1.0-ml";

(:
 : Test the standard survivorship algorithm, comparing values from different sources.
 :)

import module namespace merging-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace std = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/standard.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

let $property-spec :=
  <merge property-name="name"  max-values="2" xmlns="http://marklogic.com/smart-mastering/merging">
    <length weight="8" />
    <source-weights>
      <source name="good-source" weight="4"/>
      <source name="better-source" weight="6"/>
    </source-weights>
  </merge>
let $source1 :=
  object-node {
    "name": "good-source",
    "dateTime": fn:current-dateTime(),
    "documentUri": "/content/123.xml"
  }
let $source2 :=
  object-node {
    "name": "better-source",
    "dateTime": fn:current-dateTime(),
    "documentUri": "/content/456.xml"
  }
let $source3 :=
  object-node {
    "name": "other-source",
    "dateTime": fn:current-dateTime(),
    "documentUri": "/content/789.xml"
  }

let $wrapped-properties := (
  merging-impl:wrap-revision-info(xs:QName("name"), <name>Name1</name>, $source1, (), ()),
  merging-impl:wrap-revision-info(xs:QName("name"), <name>Name2</name>, $source2, (), ()),
  merging-impl:wrap-revision-info(xs:QName("name"), <name>Name3</name>, $source3, (), ())
)
let $actual :=
  std:standard(xs:QName("name"), $wrapped-properties, $property-spec)
return (
  test:assert-equal(2, fn:count($actual)),
  let $actual1 := $actual[1]
  return (
    test:assert-equal-xml(<name>Name2</name>, map:get($actual1, "values")),
    test:assert-equal-json($source2, map:get($actual1, "sources"))
  ),
  let $actual2 := $actual[2]
  return (
    test:assert-equal(<name>Name1</name>, map:get($actual2, "values")),
    test:assert-equal-json($source1, map:get($actual2, "sources"))
  )
)
