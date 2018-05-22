xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-merge-options";

import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/ext/com.marklogic.smart-mastering/merging.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare function get(
  $context as map:map,
  $params  as map:map
)
  as document-node()*
{
  document {
    merging:get-options(map:get($params, "name"), $const:FORMAT-JSON)
  }
};

declare function put(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
)
  as document-node()?
{
  post($context, $params, $input)
};

declare
%rapi:transaction-mode("update")
function post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
)
  as document-node()*
{
  merging:save-options(map:get($params, "name"), $input/(merging:options|object-node()))
};

declare function delete(
  $context as map:map,
  $params  as map:map
)
  as document-node()?
{
  fn:error((), "RESTAPI-SRVEXERR", (405, "Method Not Allowed", "DELETE is not implemented"))
};
