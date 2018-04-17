xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-merge-option-names";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  document {
    let $option-names := merging:get-option-names()
    return
      merging:option-names-to-json($option-names)
  }
};
