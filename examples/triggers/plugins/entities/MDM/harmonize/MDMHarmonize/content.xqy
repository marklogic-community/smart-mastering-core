xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

declare namespace es = "http://marklogic.com/entity-services";
declare namespace sm = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

(:~
 : Create Content Plugin
 :
 : @param $id          - the identifier returned by the collector
 : @param $options     - a map containing options. Options are sent from Java
 :
 : @return - your transformed content
 :)
declare function plugin:create-content(
  $id as xs:string,
  $options as map:map) as item()?
{
  let $doc := fn:doc($id)/es:envelope
  let $headers := $doc/es:headers/*
  return (
    (: preserve the existing headers :)
    map:put($options, "headers", $headers),

    (:
     : return the original content
     : normally you would do more to harmonize,
     : but we are keeping it simple to focus on the
     : smart mastering bits in the SmartMaster flow
     :)
    $doc/es:instance/*
  ),

  (: preserve the existing collections :)
  map:put($options, "original-collections", xdmp:document-get-collections($id))
};
