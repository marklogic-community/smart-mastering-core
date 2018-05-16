xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-match";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  post($context, $params, ())
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
%rapi:transaction-mode("query")
function post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
  ) as document-node()*
{
  let $uri := map:get($params, "uri")
  let $input-root := $input/(element()|object-node())
  let $document :=
    if ($input/(*:document|object-node("document"))) then
      $input/(*:document|object-node("document"))
    else
      fn:doc($uri)
  let $options :=
    if (map:contains($params, "options")) then
      matcher:get-options-as-xml(map:get($params, "options"))
    else
      $input-root/(*:options|.[object-node("options")])
  let $start :=
    fn:head((
      map:get($params,"start") ! xs:integer(.),
      1
    ))
  let $page-length :=
    fn:head((
      map:get($params,"pageLength") ! xs:integer(.),
      $options//*:max-scan ! xs:integer(.),
      20
    ))
  let $results :=
    matcher:find-document-matches-by-options(
      $document,
      $options,
      $start,
      $page-length
    )
  return
    matcher:results-to-json($results)
};

declare function delete(
  $context as map:map,
  $params  as map:map
  ) as document-node()?
{
  fn:error((), "RESTAPI-SRVEXERR", (405, "Method Not Allowed", "DELETE is not implemented"))
};
