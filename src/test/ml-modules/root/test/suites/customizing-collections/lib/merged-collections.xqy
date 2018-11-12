xquery version "1.0-ml";

module namespace merge-algorithm = "test/merge-collection-algorithm";

import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib.xqy";

declare function merge-algorithm:collections(
  $event-name as xs:string,
  $collections-by-uri as map:map,
  $event-options as element()
) {
  (
    $lib:ALGORITHM-MERGE-COLLECTION
  )
};
