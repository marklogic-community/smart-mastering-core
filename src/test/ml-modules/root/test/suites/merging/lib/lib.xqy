xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $INVOKE_OPTIONS :=
  <options xmlns="xdmp:eval">
    <isolation>different-transaction</isolation>
  </options>;

declare variable $TEST-DATA :=
  map:new((
    map:entry("/source/1/doc1.xml", "doc1.xml"),
    map:entry("/source/2/doc2.xml", "doc2.xml")
  ));

declare variable $OPTIONS-NAME := "test-options";
