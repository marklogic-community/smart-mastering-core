xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $MERGE-OPTIONS-NAME := "test-merge-options";

declare variable $TEST-DATA :=
  map:new((
    map:entry("/content/doc1.json", "doc1.json"),
    map:entry("/content/doc2.json", "doc2.json"),
    map:entry("/content/doc3.json", "doc3.json"),
    map:entry("/content/doc4.json", "doc4.json"),
    map:entry("/content/doc5.json", "doc5.json"),
    map:entry("/content/doc6.json", "doc6.json"),
    map:entry("/content/doc7.json", "doc7.json")
  ));
