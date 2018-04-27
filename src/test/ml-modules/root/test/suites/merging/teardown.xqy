xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics"
  at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

xdmp:directory-delete("/source/"),
xdmp:collection-delete("mdm-content"),
xdmp:collection-delete("mdm-auditing"),
xdmp:collection-delete("mdm-merged"),
sem:graph-delete(sem:iri("http://marklogic.com/semantics#default-graph"))
