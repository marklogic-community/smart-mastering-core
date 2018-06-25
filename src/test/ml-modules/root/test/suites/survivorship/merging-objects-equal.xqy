xquery version "1.0-ml";

import module namespace merging-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/base.xqy";

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

let $map6 :=
  let $o := json:object()
  let $_ := (
    map:put($o, "key1", "foo"),
    map:put($o, "key2", "bar"),
    let $a := json:array()
    let $_ := (
      json:array-push($a, "1"),
      json:array-push($a, "2")
    )
    return
      map:put($o, "things", $a)
  )
  return $o

let $map7 :=
  let $o := json:object()
  let $_ := (
    map:put($o, "key2", "bar"),
    map:put($o, "key1", "foo"),
    let $a := json:array()
    let $_ := (
      json:array-push($a, "1"),
      json:array-push($a, "2")
    )
    return
      map:put($o, "things", $a)
  )
  return $o

let $map8 := json:object(
<json:object xmlns:json="http://marklogic.com/xdmp/json" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <json:entry key="PersonNameType">
    <json:value><json:object>
        <json:entry key="PersonSurName">
          <json:value>JONES</json:value>
        </json:entry>
        <json:entry key="PersonGivenName">
          <json:value>LINDSEY</json:value>
        </json:entry>
      </json:object></json:value>
  </json:entry>
</json:object>)

let $map9 := json:object(
<json:object xmlns:json="http://marklogic.com/xdmp/json" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <json:entry key="PersonNameType">
    <json:value><json:object>
        <json:entry key="PersonSurName">
          <json:value>JONES</json:value>
        </json:entry>
        <json:entry key="PersonGivenName">
          <json:value>LINDSEY</json:value>
        </json:entry>
      </json:object></json:value>
  </json:entry>
</json:object>)

return (
  test:assert-true(merging-impl:objects-equal($map1, $map5)),
  test:assert-true(merging-impl:objects-equal($map1, $map1)),
  test:assert-false(merging-impl:objects-equal($map1, $map2)),
  test:assert-false(merging-impl:objects-equal($map1, $map3)),
  test:assert-false(merging-impl:objects-equal($map1, $map4)),
  test:assert-true(merging-impl:objects-equal($map6, $map7)),
  test:assert-true(merging-impl:objects-equal($map8, $map9))
)
