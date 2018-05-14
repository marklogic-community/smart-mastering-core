xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/sm-history-document";

import module namespace history = "http://marklogic.com/smart-mastering/auditing/history"
  at "/ext/com.marklogic.smart-mastering/auditing/history.xqy";

declare function get(
  $context as map:map,
  $params  as map:map
  ) as document-node()*
{
  history:document-history(map:get($params,"uri"))
};
