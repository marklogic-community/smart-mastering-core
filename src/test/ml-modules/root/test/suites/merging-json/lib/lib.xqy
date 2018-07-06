xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $INVOKE_OPTIONS :=
  <options xmlns="xdmp:eval">
    <isolation>different-transaction</isolation>
  </options>;

declare variable $TEST-DATA :=
  map:new((
    map:entry("/source/1/doc1.json", "doc1.json"),
    map:entry("/source/2/doc2.json", "doc2.json")
  ));

declare variable $OPTIONS-NAME := "test-options";
declare variable $OPTIONS-NAME-CUST-XQY := "cust-xqy-test-options";
declare variable $OPTIONS-NAME-CUST-SJS := "cust-sjs-test-options";
declare variable $OPTIONS-NAME-PATH := "path-test-options";
