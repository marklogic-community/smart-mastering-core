xquery version "1.0-ml";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";

import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

xdmp:log("setup.xqy: merging"),
merging:save-merge-models-by-uri(($lib:URI1, $lib:URI2), merging:get-options($lib:OPTIONS-NAME))
