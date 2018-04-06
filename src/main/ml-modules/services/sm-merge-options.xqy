xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-merge-options";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  document {
    let $options := merging:get-options(map:get($params, "name"))
    let $accept-types := map:get($context,"accept-types")
    return
      if ($accept-types = "application/json") then (
        map:put($context,"output-types", "application/json"),
        merging:options-to-json($options)
      ) else
        $options
  }
};

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
  let $options := $input/(merging:options|object-node())
  let $options :=
    if ($options instance of object-node()) then
      merging:options-from-json($options)
    else
      $options
  return
    merging:save-options(map:get($params, "name"), $options)
};

declare function delete(
  $context as map:map,
  $params  as map:map
  ) as document-node()?
{
  fn:error((), "RESTAPI-SRVEXERR", (405, "Method Not Allowed", "DELETE is not implemented"))
};
