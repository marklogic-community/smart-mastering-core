xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-merge";

import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare function put(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
  ) as document-node()?
{
  post($context, $params, $input)
};

declare
%rapi:transaction-mode("update")
function post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
  ) as document-node()*
{
  let $uris := (map:get($params, "primary-uri"),map:get($params, "secondary-uri"))
  let $options :=
    if (fn:exists($input/(*:options|object-node()))) then
      $input/(*:options|object-node())
    else
      merging:get-options(map:get($params, "options"), $const:FORMAT-XML)
  let $merge-fun :=
    if (map:get($params, "preview") = "true") then
      merging:build-merge-models-by-uri#2
    else
      merging:save-merge-models-by-uri#2
  return
    document {
      $merge-fun($uris, $options)
    }
};

declare %rapi:transaction-mode("update") function delete(
  $context as map:map,
  $params  as map:map
  ) as document-node()?
{
  merging:rollback-merge(
    map:get($params, "mergedUri"),
    fn:not(map:get($params, "retainAuditTrail") = "false")
  ),
  document {
    object-node {
      "sucess": fn:true()
    }
  }
};
