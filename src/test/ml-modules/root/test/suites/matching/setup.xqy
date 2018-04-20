xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics"
  at "/MarkLogic/semantics.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare option xdmp:mapping "false";

(: Seed the database with a block :)
let $uri1 := "/content1.xml"
let $uri2 := "/content2.xml"
return
  sem:rdf-insert(
  (
    sem:triple(sem:iri($uri1), $matcher:PRED-MATCH-BLOCK, sem:iri($uri2)),
    sem:triple(sem:iri($uri2), $matcher:PRED-MATCH-BLOCK, sem:iri($uri1))
  )
)
