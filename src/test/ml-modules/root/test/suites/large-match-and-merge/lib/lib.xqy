xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $OPTIONS-NAME := "test-options";

declare variable $MATCH-OPTIONS-NAME := "basic";

declare variable $NUMBER-OF-MERGES as xs:integer := 10;

declare variable $MERGES-PER as xs:integer := 3;

declare variable $NUMBER-OF-NOTIFICATIONS as xs:integer := 40;

declare variable $NOTIFICATIONS-PER as xs:integer := 4;
