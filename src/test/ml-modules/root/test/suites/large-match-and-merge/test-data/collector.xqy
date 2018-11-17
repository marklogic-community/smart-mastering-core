xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

declare option xdmp:mapping "false";

(:~
 : Collect IDs plugin
 :
 : @param $options - a map containing options. Options are sent from Java
 :
 : @return - a sequence of ids or uris
 :)
declare function plugin:collect(
  $options as map:map) as xs:string*
{
 cts:uris((), (), cts:collection-query($const:CONTENT-COLL))
};
