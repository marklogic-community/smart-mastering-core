xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $URI1 := "/source/1/org1.json";
declare variable $URI2 := "/source/2/orgA.json";


declare variable $TEST-DATA :=
  map:new((
    map:entry($URI1, "org1.json"),
    map:entry($URI2, "orgA.json")
  ));

declare variable $MATCH-OPTIONS-NAME := "org-match-options";

declare variable $ORG-COLL := "Organization";
