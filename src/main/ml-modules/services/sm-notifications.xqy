xquery version "1.0-ml";

module namespace ext = "http://marklogic.com/rest-api/resource/sm-notifications";

import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/ext/com.marklogic.smart-mastering/matcher.xqy";

declare option xdmp:mapping "false";

declare function get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  let $start := (map:get($params, "start"), 1)[1]
  let $page-size := (map:get($params, "page-size"), 10)[1]
  let $end := $start + $page-size - 1
  let $notifications := matcher:get-notifications($start, $end)
  return
    document {
      array-node {
        for $n in $notifications
        return
          matcher:notification-to-json($n)
      }
    }
};

declare function delete(
  $context as map:map,
  $params  as map:map
) as document-node()?
{
  let $label := map:get($params, "label")
  let $uris := map:get($params, "uris")
  return
    if (fn:exists($label) and fn:exists($uris)) then
      matcher:delete-notification($label, fn:tokenize($uris, ","))
    else
      fn:error((),"RESTAPI-SRVEXERR",
        (400, "Bad Request",
        "label and uris parameters are required"))
};
