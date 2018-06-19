xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

declare namespace smart-mastering = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

(:~
 : Create Headers Plugin
 :
 : @param $id      - the identifier returned by the collector
 : @param $content - the output of your content plugin
 : @param $options - a map containing options. Options are sent from Java
 :
 : @return - zero or more header nodes
 :)
declare function plugin:create-headers(
  $id as xs:string,
  $content as node()?,
  $options as map:map) as node()*
{
  element smart-mastering:id {sem:uuid-string()},
  element smart-mastering:sources {
    element smart-mastering:source {
      element smart-mastering:name {map:get($options, "mdm-source")},
      element smart-mastering:import-id {map:get($options, "import-id")},
      element smart-mastering:user {xdmp:get-current-user()},
      element smart-mastering:dateTime {fn:current-dateTime()}
    }
  }
};
