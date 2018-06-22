xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

declare namespace sm = "http://marklogic.com/smart-mastering";

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
  element sm:id {sem:uuid-string()},
  element sm:sources {
    element sm:source {
      element sm:name {fn:replace($id, "/([^/]+)/.+", "$1")},
      element sm:import-id {map:get($options, "import-id")},
      element sm:user {xdmp:get-current-user()},
      element sm:dateTime {fn:current-dateTime()}
    }
  }
};
