xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $URI1 := "/source/1/doc1.xml";
declare variable $URI2 := "/source/2/doc2.xml";
declare variable $URI3 := "/source/3/doc3.xml";
declare variable $URI4 := "/source/4/doc4.xml";

declare variable $CROSS-URI1 := "/source/1/cross-match-merge-doc-1.xml";
declare variable $CROSS-URI2 := "/source/2/cross-match-merge-doc-2.xml";
declare variable $CROSS-URI3 := "/source/3/cross-match-merge-doc-3.xml";
declare variable $CROSS-URI4 := "/source/4/cross-match-merge-doc-4.xml";

declare variable $TEST-DATA :=
  map:new((
    map:entry($URI1, "doc1.xml"),
    map:entry($URI2, "doc2.xml"),
    map:entry($URI3, "doc3.xml"),
    map:entry($URI4, "doc4.xml"),
    map:entry($CROSS-URI1, "cross-match-merge-doc-1.xml"),
    map:entry($CROSS-URI2, "cross-match-merge-doc-2.xml"),
    map:entry($CROSS-URI3, "cross-match-merge-doc-3.xml"),
    map:entry($CROSS-URI4, "cross-match-merge-doc-4.xml")
  ));

declare variable $MATCH-OPTIONS-NAME := "match-options";
declare variable $MERGE-OPTIONS-NAME := "merge-test";

declare variable $CROSS-MATCH-OPTIONS-NAME := "cross-match-options";
declare variable $CROSS-MERGE-OPTIONS-NAME := "cross-merge-test";

declare variable $INVOKE_OPTIONS :=
  <options xmlns="xdmp:eval">
    <isolation>different-transaction</isolation>
  </options>;
