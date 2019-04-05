xquery version "1.0-ml";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

merging:save-options($lib:BAD-ENTITY-OPTIONS-NAME, test:get-test-file("bad-entity-merge-options.json")),
merging:save-options($lib:BAD-ENTITY-PROP-OPTIONS-NAME, test:get-test-file("bad-entity-prop-merge-options.json")),
merging:save-options($lib:OPTIONS-NAME, test:get-test-file("merge-options.json")),
matcher:save-options($lib:MATCH-OPTIONS-NAME, test:get-test-file("match-options.json")),
xdmp:document-insert(
  "/entity/PersonType.entity.json",
  test:get-test-file("PersonType.entity.json"),
  map:entry("collections", "http://marklogic.com/entity-services/models")
)
