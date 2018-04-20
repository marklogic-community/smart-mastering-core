xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test/notification";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare variable $INVOKE_OPTIONS :=
  <options xmlns="xdmp:eval">
    <isolation>different-transaction</isolation>
  </options>;

declare variable $LBL-LIKELY := "Likely Match";
declare variable $LBL-POSSIBLE := "Possible Match";

declare variable $URI-SET1 := ("/content1.xml", "/content2.xml", "/content3.xml");
declare variable $URI-SET2 := ("/content4.xml", "/content5.xml");

(: Get a notification without creating a lock. :)
declare function lib:get-notification($label, $uris)
{
  xdmp:invoke-function(function() { matcher:get-existing-match-notification($label, $uris) }, $INVOKE_OPTIONS)
};

(: Call the save-match-nofication function in a different transaction :)
declare function lib:save-notification($label, $uris)
{
  xdmp:invoke-function(function() { matcher:save-match-notification($label, $uris) }, $INVOKE_OPTIONS)
};

(: Call the delete-nofication function in a different transaction :)
declare function lib:delete-notification($label, $uris)
{
  xdmp:invoke-function(function() { matcher:delete-notification($label, $uris) }, $INVOKE_OPTIONS)
};

