xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-match-options";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  document {
    let $options := matcher:get-options(map:get($params, "name"))
    return
      matcher:options-to-json($options)
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
  let $options := $input/(matcher:options|object-node())
  let $options :=
    if ($options instance of object-node()) then
      matcher:options-from-json($options)
    else
      $options
  return
    matcher:save-options(map:get($params, "name"), $options)
};

declare function delete(
  $context as map:map,
  $params  as map:map
  ) as document-node()?
{
  fn:error((), "RESTAPI-SRVEXERR", (405, "Method Not Allowed", "DELETE is not implemented"))
};
