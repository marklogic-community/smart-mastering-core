xquery version "1.0-ml";

(:
 : Test the standard survivorship algorithm, comparing different length values.
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
      <source name="good-source" weight="1"/>
      <source name="better-source" weight="2"/>
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
  "name": "good-source",
  "dateTime": fn:current-dateTime(),
  "documentUri": "/content/456.xml"
  }
let $source3 :=
  object-node {
  "name": "good-source",
  "dateTime": fn:current-dateTime(),
  "documentUri": "/content/789.xml"
  }

let $wrapped-properties := (
  merging-impl:wrap-revision-info(xs:QName("name"), <name>A</name>, $source1, (), ()),
  merging-impl:wrap-revision-info(xs:QName("name"), <name>AA</name>, $source2, (), ()),
  merging-impl:wrap-revision-info(xs:QName("name"), <name>AAA</name>, $source3, (), ())
)
let $actual :=
  std:standard(xs:QName("name"), $wrapped-properties, $property-spec)
return (
  test:assert-equal(2, fn:count($actual)),
  let $actual1 := $actual[1]
  return (
    test:assert-equal-xml(<name>AAA</name>, map:get($actual1, "values")),
    test:assert-equal-json($source3, map:get($actual1, "sources"))
  ),
  let $actual2 := $actual[2]
  return (
    test:assert-equal(<name>AA</name>, map:get($actual2, "values")),
    test:assert-equal-json($source2, map:get($actual2, "sources"))
  )
)
