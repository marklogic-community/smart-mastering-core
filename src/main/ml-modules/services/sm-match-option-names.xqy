xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-match-option-names";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  document {
    matcher:get-option-names-as-json()
  }
};
