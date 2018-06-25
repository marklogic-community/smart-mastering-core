xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test/notification" at "/test/suites/notifications/lib/lib.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

(: without extractions :)
let $options :=
  <options xmlns="xdmp:http">
    <authentication method="digest">
      <username>admin</username>
      <password>admin</password>
    </authentication>
  </options>
let $resp := test:http-get('/v1/resources/sm-notifications', $options)[2]/object-node()
let $actual := $resp/notifications
let $likely := $resp/notifications[thresholdLabel = $lib:LBL-LIKELY]
let $possible := $resp/notifications[thresholdLabel = $lib:LBL-POSSIBLE]

return (
  test:assert-equal(2, fn:count($actual)),

  test:assert-exists($likely),
  test:assert-equal(3, fn:count($likely/uris/node())),
  test:assert-same-values(
    $lib:URI-SET1,
    $likely/uris/node()/fn:string()
  ),

  test:assert-exists($possible),
  test:assert-equal(2, fn:count($possible/uris/node())),
  test:assert-same-values(
    $lib:URI-SET2,
    $possible/uris/node()/fn:string()
  )
),


(: with extractions :)
let $extractions := map:new((
  map:entry("lastName", "PersonSurName"),
  map:entry("stuff", "junk")
))
let $options :=
  <options xmlns="xdmp:http">
    <authentication method="digest">
      <username>admin</username>
      <password>admin</password>
    </authentication>
    <headers>
      <Content-Type>application/json</Content-Type>
    </headers>
    <format xmlns="xdmp:document-get">json</format>
  </options>
let $uri := test:easy-url('/v1/resources/sm-notifications')
let $resp := xdmp:http-post($uri, $options, xdmp:to-json($extractions))[2]/object-node()
let $actual := $resp/notifications
let $likely := $resp/notifications[thresholdLabel = $lib:LBL-LIKELY]
let $possible := $resp/notifications[thresholdLabel = $lib:LBL-POSSIBLE]
return (
  test:assert-equal(2, fn:count($actual)),

  test:assert-exists($likely),
  test:assert-equal(3, fn:count($likely/uris/node())),
  test:assert-same-values(
    $lib:URI-SET1,
    $likely/uris/node()/fn:string()
  ),

  test:assert-exists($possible),
  test:assert-equal(2, fn:count($possible/uris/node())),
  test:assert-same-values(
    $lib:URI-SET2,
    $possible/uris/node()/fn:string()
  ),
  test:assert-equal(3, fn:count($likely/extractions/node())),
  test:assert-equal(6, fn:count($likely/extractions/node()/node())),
  test:assert-equal("JONES", ($likely/extractions/node()/lastName/fn:string())[1]),
  test:assert-equal("JONES", ($likely/extractions/node()/lastName/fn:string())[2]),
  test:assert-equal("JONES", ($likely/extractions/node()/lastName/fn:string())[3]),
  test:assert-equal("", ($likely/extractions/node()/stuff/fn:string())[1]),
  test:assert-equal("", ($likely/extractions/node()/stuff/fn:string())[2]),
  test:assert-equal("", ($likely/extractions/node()/stuff/fn:string())[3])
),


(: TEST PUT - TOGGLE READ/UNREAD STATUS :)
let $uris := cts:uri-match("/com.marklogic.smart-mastering/matcher/notifications/*")
let $body := object-node {
  "uris": array-node { $uris },
  "status": "read"
}
let $options :=
  <options xmlns="xdmp:http">
    <authentication method="digest">
      <username>admin</username>
      <password>admin</password>
    </authentication>
    <headers>
      <Content-Type>application/json</Content-Type>
    </headers>
    <format xmlns="xdmp:document-get">json</format>
  </options>
let $uri := test:easy-url('/v1/resources/sm-notifications')
let $resp := xdmp:http-put($uri, $options, $body)
return
(),

(: do this here to force the above put to complete :)
let $options :=
  <options xmlns="xdmp:http">
    <authentication method="digest">
      <username>admin</username>
      <password>admin</password>
    </authentication>
    <headers>
      <Content-Type>application/json</Content-Type>
    </headers>
    <format xmlns="xdmp:document-get">json</format>
  </options>
let $resp := test:http-get('/v1/resources/sm-notifications', $options)[2]/object-node()
let $actual := $resp/notifications
return
  test:assert-equal(("read", "read"), $actual//*:status/fn:string())
