xquery version "1.0-ml";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

let $map1 := map:new((
  map:entry("key1", "foo"),
  map:entry("key2", "bar")
))
let $map2 := map:new((
  map:entry("key1", "blah"),
  map:entry("key2", "asdf")
))
let $map3 := map:new((
  map:entry("key1", "foo"),
  map:entry("key2", "bar"),
  map:entry("key3", "extra")
))
let $map4 := map:new((
  map:entry("key4", "foo"),
  map:entry("key5", "bar")
))
let $map5 := map:new((
  map:entry("key1", "foo"),
  map:entry("key2", "bar")
))

return (
  test:assert-true(merging:objects-equal($map1, $map5)),
  test:assert-true(merging:objects-equal($map1, $map1)),
  test:assert-false(merging:objects-equal($map1, $map2)),
  test:assert-false(merging:objects-equal($map1, $map3)),
  test:assert-false(merging:objects-equal($map1, $map4))
)
