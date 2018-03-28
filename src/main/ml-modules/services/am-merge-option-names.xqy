xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/am-merge-option-names";

import module namespace merging = "http://marklogic.com/agile-mastering/survivorship/merging"
  at "/ext/com.marklogic.agile-mastering/survivorship/merging/base.xqy";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  document {
    let $option-names := merging:get-option-names()
    let $accept-types := map:get($context, "accept-types")
    return
      if ($accept-types = "application/json") then (
        map:put($context,"output-types", "application/json"),
        merging:option-names-to-json($option-names)
      ) else
        $option-names
  }
};
