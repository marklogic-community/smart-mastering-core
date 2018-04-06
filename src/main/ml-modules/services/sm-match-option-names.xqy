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
    let $option-names := matcher:get-option-names()
    let $accept-types := map:get($context, "accept-types")
    return
      if ($accept-types = "application/json") then (
        map:put($context,"output-types", "application/json"),
        matcher:option-names-to-json($option-names)
      ) else
        $option-names
  }
};
