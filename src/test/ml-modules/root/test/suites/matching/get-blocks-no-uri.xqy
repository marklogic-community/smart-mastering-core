xquery version "1.0-ml";

(:~
 : In the scenario of looking for matches for a document not yet inserted into
 : the database, there's no URI. matcher:get-blocks needs to allow for that
 : situation.
 :)

import module namespace blocks-impl = "http://marklogic.com/smart-mastering/blocks-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/blocks-impl.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare option xdmp:mapping "false";

test:assert-equal(
  array-node {},
  matcher:get-blocks(())
)
