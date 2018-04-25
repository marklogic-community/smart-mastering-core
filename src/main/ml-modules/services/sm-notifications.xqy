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
  let $start := (map:get($params, "start"), 1)[1] ! xs:int(.)
  let $page-size := (map:get($params, "page-size"), 10)[1] ! xs:int(.)
  let $end := $start + $page-size - 1
  let $notifications := matcher:get-notifications($start, $end)
  return
    document {
      object-node {
      "total": matcher:count-notifications(),
      "start": $start,
      "page-size": $page-size,
      "notifications":
        array-node {
          for $n in $notifications
          return
            matcher:notification-to-json($n)
        }
      }
    }
};

(:
 : Update the status of a notification.
 : @body  JSON object with two properties: uris and status. uris is an array containing URI strings. status must
 :        use the values of $matcher:STATUS-READ or $matcher:STATUS-UNREAD.
 :)
declare function put(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
) as document-node()?
{
  let $uris as xs:string* := $input/node()/uris
  let $status as xs:string? := $input/node()/status
  return
    if (fn:empty($status)) then
      fn:error((),"RESTAPI-SRVEXERR",
        (400, "Bad Request",
        "status parameter is required"))
    else if (fn:empty($uris)) then
      fn:error((),"RESTAPI-SRVEXERR",
        (400, "Bad Request",
        "uris parameter is required"))
    else
      for $uri in $uris
      return
        if (fn:doc-available($uri)) then
          matcher:update-notification-status($uri, $status)
        else
          fn:error((),"RESTAPI-SRVEXERR",
            (404, "Not Found",
            "No notification available at URI " || $uri))
};

declare function delete(
  $context as map:map,
  $params  as map:map
) as document-node()?
{
  for $uri in map:get($params, "uri")
  return
    if (fn:exists($uri)) then
      if (fn:doc-available($uri)) then
        matcher:delete-notification($uri)
      else
        fn:error((),"RESTAPI-SRVEXERR",
          (404, "Not Found",
          "No notification available at URI " || $uri))
    else
      fn:error((),"RESTAPI-SRVEXERR",
        (400, "Bad Request",
        "uri parameter is required"))
};
