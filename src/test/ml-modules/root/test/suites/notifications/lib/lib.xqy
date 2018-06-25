xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test/notification";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace notify-impl = "http://marklogic.com/smart-mastering/notification-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/notification-impl.xqy";

declare variable $INVOKE_OPTIONS :=
  <options xmlns="xdmp:eval">
    <isolation>different-transaction</isolation>
  </options>;

declare variable $LBL-LIKELY := "Likely Match";
declare variable $LBL-POSSIBLE := "Possible Match";

declare variable $URI1 := "/content1.xml";
declare variable $URI2 := "/content2.xml";
declare variable $URI3 := "/content3.xml";
declare variable $URI4 := "/content4.xml";
declare variable $URI5 := "/content5.xml";

declare variable $URI-SET1 := ($URI1, $URI2, $URI3);
declare variable $URI-SET2 := ($URI4, $URI5);

declare variable $TEST-DATA :=
  map:new((
    map:entry($URI1, "content1.xml"),
    map:entry($URI2, "content2.xml"),
    map:entry($URI3, "content3.xml"),
    map:entry($URI4, "content4.xml"),
    map:entry($URI5, "content5.xml")
  ));

(: Get a notification without creating a lock. :)
declare function lib:get-notification($label, $uris)
{
  xdmp:invoke-function(function() { notify-impl:get-existing-match-notification($label, $uris, map:map()) }, $INVOKE_OPTIONS)
};

(: Call the save-match-nofication function in a different transaction :)
declare function lib:save-notification($label, $uris)
{
  xdmp:invoke-function(function() { matcher:save-match-notification($label, $uris) }, $INVOKE_OPTIONS)
};

(: Call the delete-nofication function in a different transaction :)
declare function lib:delete-notification($uri)
{
  xdmp:invoke-function(function() { matcher:delete-notification($uri) }, $INVOKE_OPTIONS)
};

