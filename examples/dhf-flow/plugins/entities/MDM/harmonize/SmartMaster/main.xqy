xquery version "1.0-ml";

(: Your plugin must be in this namespace for the DHF to recognize it:)
module namespace plugin = "http://marklogic.com/data-hub/plugins";

(:
 : This module exposes helper functions to make your life easier
 : See documentation at:
 : https://github.com/marklogic/marklogic-data-hub/wiki/dhf-lib
 :)
import module namespace dhf = "http://marklogic.com/dhf"
  at "/MarkLogic/data-hub-framework/dhf.xqy";

(: include the writer module which persists your envelope into MarkLogic :)
import module namespace writer = "http://marklogic.com/data-hub/plugins" at "writer.xqy";

declare option xdmp:mapping "false";

(:~
 : Plugin Entry point
 :
 : @param $id          - the identifier returned by the collector
 : @param $options     - a map containing options. Options are sent from Java
 :
 :)
declare function plugin:main(
  $id as xs:string,
  $options as map:map)
{
  (: we have pruned out the unimportant parts to focus on
   : the fact that Smart Mastering happens in the writer
   :)
  dhf:run-writer(xdmp:function(xs:QName("writer:write")), $id, <envelope/>, $options)
};
