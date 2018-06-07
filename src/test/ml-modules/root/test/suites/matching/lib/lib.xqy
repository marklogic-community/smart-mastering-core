xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $URI1 := "/source/1/doc1.xml";
declare variable $URI2 := "/source/2/doc2.xml";
declare variable $URI3 := "/source/3/doc3.xml";
declare variable $URI4 := "/source/1/doc1.json";
declare variable $URI5 := "/source/2/doc2.json";
declare variable $URI6 := "/source/3/doc3.json";
declare variable $URI7 := "/source/3/doc4.xml";

declare variable $TEST-DATA :=
  map:new((
    map:entry($URI1, "doc1.xml"),
    map:entry($URI2, "doc2.xml"),
    map:entry($URI3, "doc3.xml"),
    map:entry($URI7, "doc4.xml"),
    map:entry($URI4, "doc1.json"),
    map:entry($URI5, "doc2.json"),
    map:entry($URI6, "doc3.json")
  ));

declare variable $MATCH-OPTIONS-NAME := "match-test";
declare variable $SCORE-OPTIONS-NAME := "score-options";

