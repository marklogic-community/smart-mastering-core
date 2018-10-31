xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-match-and-merge";

import module namespace process = "http://marklogic.com/smart-mastering/process-records"
  at "/com.marklogic.smart-mastering/process-records.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

declare namespace rapi = "http://marklogic.com/rest-api";

declare option xdmp:mapping "false";

declare function resource:get-collector($params as map:map)
{
  let $collector-at := map:get($params, "collector-at")
  let $collector-ns := map:get($params, "collector-ns")
  let $collector-name := map:get($params, "collector-name")
  return
    if (fn:empty($collector-name)) then
      (: Caller wasn't trying to load a collector :)
      ()
    else
      (: Will thrown XDMP-MODNOTFOUND if the parameters don't point to a function. Try/catch does not catch that exception. :)
      xdmp:function(fn:QName($collector-ns, $collector-name), $collector-at)
};

declare
%rapi:transaction-mode("update")
function post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
  ) as document-node()*
{
  let $collector := resource:get-collector($params)
  let $uris :=
    if (fn:exists($collector)) then
      xdmp:apply($collector, map:map())
    else
      map:get($params, "uri")
  let $options-name :=
    let $name := map:get($params, "options")
    return
      if (fn:exists($name)) then
        $name
      else
        fn:error((),"RESTAPI-SRVEXERR",
          (400, "Bad Request",
          "'options' is a required parameter"))
  let $query :=
    let $q := map:get($params, "query")
    return
      if (fn:exists($q)) then
        try {
          cts:query(xdmp:unquote($q)/node())
        }
        catch ($e) {
          if ($e/error:code = "XDMP-NOTQUERY") then
            fn:error((),"RESTAPI-SRVEXERR",
              (400, "Bad Request",
              "'query' must be a serialized query; got " || $q))
          else
            xdmp:rethrow()
        }
      else ()
  return (
    if (xdmp:trace-enabled($const:TRACE-MATCH-RESULTS)) then
      xdmp:trace($const:TRACE-MATCH-RESULTS, "Calling process-match-and-merge with URIs [" ||
        fn:string-join($uris, "; ") ||
        "], options name=" || $options-name ||
        ", and query=" || xdmp:quote($query))
    else (),
    if (fn:exists($query)) then
      document { process:process-match-and-merge($uris, $options-name, $query) }
    else
      document { process:process-match-and-merge($uris, $options-name) }
  )
};
