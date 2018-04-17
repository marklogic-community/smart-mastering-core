xquery version "1.0-ml";

module namespace ext = "http://marklogic.com/rest-api/resource/sm-block-match";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare option xdmp:mapping "false";

declare function get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  document {
    matcher:get-blocks(map:get($params, "uri"))
  }
};

declare
%rapi:transaction-mode("update")
function post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
) as document-node()*
{
  matcher:block-match(
    map:get($params, "uri1"),
    map:get($params, "uri2")
  )
};

declare function delete(
  $context as map:map,
  $params  as map:map
) as document-node()?
{
  matcher:allow-match(
    map:get($params, "uri1"),
    map:get($params, "uri2")
  )
};
