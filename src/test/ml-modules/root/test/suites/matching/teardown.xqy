xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics"
at "/MarkLogic/semantics.xqy";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
at "/ext/com.marklogic.smart-mastering/constants.xqy";

declare option xdmp:mapping "false";

(: Clear out any notifications :)
xdmp:collection-delete($const:NOTIFICATION-COLL),

sem:graph-delete(sem:iri("http://marklogic.com/semantics#default-graph"))
