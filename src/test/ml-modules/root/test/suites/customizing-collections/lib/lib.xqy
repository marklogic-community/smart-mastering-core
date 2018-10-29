xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/smart-mastering/test";

declare variable $INVOKE_OPTIONS :=
  <options xmlns="xdmp:eval">
    <isolation>different-transaction</isolation>
  </options>;

declare variable $XML-TEST-DATA :=
  map:new((
    map:entry("/source/1/doc1.xml", "doc1.xml"),
    map:entry("/source/2/doc2.xml", "doc2.xml")
  ));

declare variable $JSON-TEST-DATA :=
  map:new((
    map:entry("/source/1/doc1.json", "doc1.json"),
    map:entry("/source/2/doc2.json", "doc2.json")
  ));

declare variable $XML-MATCH-OPT-NAME := "match-options-xml";
declare variable $XML-MATCH-OPT-NAME-NO-COLL := "match-options-no-coll-xml";
declare variable $XML-MATCH-OPT-NAME-MULT-COLLS := "match-options-mult-colls-xml";

declare variable $JSON-MATCH-OPT-NAME := "match-options-json";
declare variable $JSON-MATCH-OPT-NAME-NO-COLL := "match-options-no-coll-json";
declare variable $JSON-MATCH-OPT-NAME-MULT-COLLS := "match-options-mult-colls-json";

declare variable $MATCH-OPTIONS :=
  map:new((
    map:entry($XML-MATCH-OPT-NAME, "match-options.xml"),
    map:entry($XML-MATCH-OPT-NAME-NO-COLL, "match-options-no-coll.xml"),
    map:entry($XML-MATCH-OPT-NAME-MULT-COLLS, "match-options-mult-colls.xml"),
    map:entry($JSON-MATCH-OPT-NAME, "match-options.json"),
    map:entry($JSON-MATCH-OPT-NAME-NO-COLL, "match-options-no-coll.json"),
    map:entry($JSON-MATCH-OPT-NAME-MULT-COLLS, "match-options-mult-colls.json")
  ));

declare variable $XML-MERGE-OPT-NAME := "merge-options-xml";
declare variable $XML-MERGE-OPT-NAME-NO-COLL := "merge-options-no-coll-xml";
declare variable $XML-MERGE-OPT-NAME-MULT-COLLS := "merge-options-mult-colls-xml";

declare variable $JSON-MERGE-OPT-NAME := "merge-options-json";
declare variable $JSON-MERGE-OPT-NAME-NO-COLL := "merge-options-no-coll-json";
declare variable $JSON-MERGE-OPT-NAME-MULT-COLLS := "merge-options-mult-colls-json";

declare variable $MERGE-OPTIONS :=
  map:new((
    map:entry($XML-MERGE-OPT-NAME, "merge-options.xml"),
    map:entry($XML-MERGE-OPT-NAME-NO-COLL, "merge-options-no-coll.xml"),
    map:entry($XML-MERGE-OPT-NAME-MULT-COLLS, "merge-options-mult-colls.xml"),
    map:entry($JSON-MERGE-OPT-NAME, "merge-options.xml"),
    map:entry($JSON-MERGE-OPT-NAME-NO-COLL, "merge-options-no-coll.xml"),
    map:entry($JSON-MERGE-OPT-NAME-MULT-COLLS, "merge-options-mult-colls.xml")
  ));


declare variable $COLL-NAMES := map:new((
  map:entry("content", "my-content-collection"),
  map:entry("dictionary", "my-dictionary-collection"),
  map:entry("options", "my-options-collection"),
  map:entry("match-options", "my-match-options-collection"),
  map:entry("merge-options", "my-merge-collection"),
  map:entry("merged", "my-merged-collection"),
  map:entry("model-mapper", "my-model-mapper-collection"),
  map:entry("notification", "my-notification-collection")
));
