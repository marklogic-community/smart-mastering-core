xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

declare namespace sm = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";

declare option xdmp:mapping "false";

(:~
 : Writer Plugin
 :
 : @param $id       - the identifier returned by the collector
 : @param $envelope - the final envelope
 : @param $options  - a map containing options. Options are sent from Java
 :
 : @return - nothing
 :)
declare function plugin:write(
  $id as xs:string,
  $envelope as node(),
  $options as map:map) as empty-sequence()
{
  xdmp:document-insert(
    $id,
    $envelope,
    (
      xdmp:permission("rest-reader", "read"),
      xdmp:permission("mdm-user", "read"),
      xdmp:permission("mdm-user", "update")
    ),
    map:get($options, "original-collections")
  )
};
