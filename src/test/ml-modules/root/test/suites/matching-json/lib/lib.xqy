xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $URI1 := "/source/1/doc1.json";
declare variable $URI2 := "/source/2/doc2.json";
declare variable $URI3 := "/source/3/doc3.json";
declare variable $URI4 := "/source/4/no-match.json";


declare variable $TEST-DATA :=
  map:new((
    map:entry($URI1, "doc1.json"),
    map:entry($URI2, "doc2.json"),
    map:entry($URI3, "doc3.json"),
    map:entry($URI4, "no-match.json")
  ));

declare variable $MATCH-OPTIONS-NAME := "match-test";
declare variable $SCORE-OPTIONS-NAME := "score-options";
declare variable $SCORE-OPTIONS-NAME2 := "score-options2";

