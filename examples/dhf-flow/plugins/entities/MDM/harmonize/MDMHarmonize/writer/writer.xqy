xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";
import module namespace auditing = "http://marklogic.com/smart-mastering/auditing"
  at "/ext/com.marklogic.smart-mastering/auditing/base.xqy";

declare namespace smart-mastering = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";
declare namespace prov = "http://www.w3.org/ns/prov#";

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
  auditing:audit-trace(
    "harmonize",
    $id,
    $id,
    let $raw-doc := map:get($options, "raw-document")
    let $source-name := fn:string(
                    fn:head(
                      $raw-doc/(es:envelope|object-node("envelope"))
                      /(es:headers|object-node("headers"))
                      /(smart-mastering:sources|array-node("sources"))
                      /(smart-mastering:source|object-node())/*:name
                    )
                  )
    let $instance := $raw-doc/(es:envelope|object-node("envelope"))/(es:instance|object-node("instance"))/*
    let $properties := if (fn:count($instance) > 1) then $instance else $instance/*
    let $generated-entity-id := $auditing:sm-prefix||$id
    let $property-related-prov :=
        for $prop in $properties
        let $value := fn:string($prop)
        where cts:contains($envelope, cts:word-query($value, ("whitespace-insensitive", "punctuation-insensitive", "case-insensitive")))
        return
        let $type := fn:string(fn:node-name($prop))
        let $hash := xdmp:sha512($value)
        let $used-entity-id := $auditing:sm-prefix || $id || $type || $hash
        return (
          element prov:entity {
            attribute prov:id {$used-entity-id},
            element prov:type {$type},
            element prov:label {$source-name || ":" || $type},
            element prov:location {$id},
            element prov:value { $value }
          },
          element prov:wasDerivedFrom {
            element prov:generatedEntity {
              attribute prov:ref { $generated-entity-id }
            },
            element prov:usedEntity {
              attribute prov:ref { $used-entity-id }
            }
          },
          element prov:wasInfluencedBy {
            element prov:influencee { attribute prov:ref { $used-entity-id }},
            element prov:influencer { attribute prov:ref { "Data Hub Harmonization" }}
          }
        )
    let $prop-prov-entities := $property-related-prov[. instance of element(prov:entity)]
    let $other-prop-prov := $property-related-prov except $prop-prov-entities
    return (
      element prov:hadMember {
        element prov:collection { attribute prov:ref { $generated-entity-id } },
        $prop-prov-entities
      },
      $other-prop-prov,
      for $agent-id in
        fn:distinct-values(
          $other-prop-prov[. instance of element(prov:wasInfluencedBy)]/
            prov:influencer/
              @prov:ref ! fn:string(.)
        )
      return element prov:softwareAgent {
        attribute prov:id {$agent-id},
        element prov:label {"Harmonization"},
        element prov:location {"FINAL DB"}
      }
    )
  ),
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
