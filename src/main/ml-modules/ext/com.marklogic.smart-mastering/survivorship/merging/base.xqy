xquery version "1.0-ml";

module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging";

import module namespace auditing = "http://marklogic.com/smart-mastering/auditing"
  at "../../auditing/base.xqy";
import module namespace fun-ext = "http://marklogic.com/smart-mastering/function-extension"
  at "../../function-extension/base.xqy";
import module namespace history = "http://marklogic.com/smart-mastering/auditing/history"
  at "../../auditing/history.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at  "standard.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

declare namespace smart-mastering = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";
declare namespace prov = "http://www.w3.org/ns/prov#";

declare option xdmp:mapping "false";

declare variable $retain-rollback-info := fn:false();

declare variable $MERGING-OPTIONS-DIR := "/com.marklogic.smart-mastering/options/merging/";

declare function merging:default-function-lookup(
  $name as xs:string?,
  $arity as xs:int)
{
  fn:function-lookup(
    fn:QName(
      "http://marklogic.com/smart-mastering/survivorship/merging",
      if (fn:exists($name[. ne ""])) then
        $name
      else
        "standard"
    ),
    $arity
  )
};

declare function merging:build-merging-map($merging-xml)
{
  map:new((
    for $algorithm-xml in $merging-xml//*:algorithm
    return
      map:entry(
        $algorithm-xml/@name,
        fun-ext:function-lookup(
          fn:string($algorithm-xml/@function),
          fn:string($algorithm-xml/@namespace),
          fn:string($algorithm-xml/@at),
          merging:default-function-lookup(?, 3)
        )
      )
  ))
};


declare function merging:save-merge-models-by-uri(
  $uris as xs:string*,
  $merge-options as item()?
) {
  let $merge-options :=
    if ($merge-options instance of object-node()) then
      merging:options-from-json($merge-options)
    else
      $merge-options
  let $id := sem:uuid-string()
  let $merge-uri := "/com.marklogic.smart-mastering/merged/"||$id||".xml"
  let $uris :=
    for $uri in $uris
    let $is-merged := xdmp:document-get-collections($uri) = $const:MERGED-COLL
    return
      if ($is-merged) then
        auditing:auditing-receipts-for-doc-uri($uri)
          /prov:collection/@prov:id[. ne $uri] ! fn:string(.)
      else
        $uri
  let $parsed-properties :=
      merging:parse-final-properties-for-merge(
        $uris,
        $merge-options
      )
  let $final-properties := map:get($parsed-properties, "final-properties")
  let $docs := map:get($parsed-properties, "documents")
  let $instances := map:get($parsed-properties, "instances")
  let $top-level-properties := map:get($parsed-properties, "top-level-properties")
  let $sources := map:get($parsed-properties, "sources")
  let $wrapper-qnames := map:get($parsed-properties, "wrapper-qnames")
  let $merged-document :=
    merging:build-merge-models-by-final-properties(
      $id,
      $docs,
      $wrapper-qnames,
      $final-properties,
      $merge-options
    )
  let $_audit-trail :=
    auditing:audit-trace(
      $const:MERGE-ACTION,
      $uris,
      $merge-uri,
      let $generated-entity-id := $auditing:am-prefix||$merge-uri
      let $property-related-prov :=
        for $prop in $final-properties,
          $value in map:get($prop, "values")
        let $type := fn:string(fn:node-name($value))
        let $value-text := history:normalize-value-for-tracing($value)
        let $hash := xdmp:sha512($value-text)
        let $algorithm-info := map:get($prop, "algorithm")
        let $algorithm-agent := "algorithm:"||$algorithm-info/name||";options:"||$algorithm-info/optionsReference
        for $source in map:get($prop, "sources")
        let $used-entity-id := $auditing:am-prefix || $source/documentUri || $type || $hash
        return (
          element prov:entity {
            attribute prov:id {$used-entity-id},
            element prov:type {$type},
            element prov:label {$source/name || ":" || $type},
            element prov:location {fn:string($source/documentUri)},
            element prov:value { $value-text }
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
            element prov:influencer { attribute prov:ref { $algorithm-agent }}
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
          element prov:label {fn:substring-before(fn:substring-after($agent-id,"algorithm:"), ";")},
          element prov:location {fn:substring-after($agent-id,"options:")}
        }
      )
    )
  return (
    $merged-document,
    for $uri in $uris[fn:doc-available(.)]
    return
      merging:archive-document($uri),
    xdmp:document-insert(
      $merge-uri,
      $merged-document,
      (
        xdmp:permission($const:MDM-ADMIN, "update"),
        xdmp:permission($const:MDM-USER, "read")
      ),
      ($const:CONTENT-COLL, $const:MERGED-COLL)
    )
  )
};


declare function merging:rollback-merge(
  $merged-doc-uri as xs:string
) {
  merging:rollback-merge($merged-doc-uri, fn:true())
};

declare function merging:rollback-merge(
  $merged-doc-uri as xs:string,
  $retain-rollback-info as xs:boolean
) {
  let $auditing-receipts-for-doc :=
    auditing:auditing-receipts-for-doc-uri($merged-doc-uri)
  where fn:exists($auditing-receipts-for-doc)
  return (
    for $previous-doc-uri in $auditing-receipts-for-doc/auditing:previous-uri ! fn:string(.)
    let $new-collections := (
      xdmp:document-get-collections($previous-doc-uri)[fn:not(. = $const:ARCHIVED-COLL)],
      $const:CONTENT-COLL
    )
    return
      xdmp:document-set-collections($previous-doc-uri, $new-collections),
    if ($retain-rollback-info) then (
      xdmp:document-set-collections($merged-doc-uri,
        (
          xdmp:document-get-collections($merged-doc-uri)[fn:not(. = $const:CONTENT-COLL)],
          $const:ARCHIVED-COLL
        )
      ),
      $auditing-receipts-for-doc ! auditing:audit-trace-rollback(.)
    ) else (
      xdmp:document-delete($merged-doc-uri),
      $auditing-receipts-for-doc ! xdmp:document-delete(xdmp:node-uri(.))
    )
  )
};

declare function merging:build-merge-models-by-uri(
  $uris as xs:string*,
  $merge-options as item()?
) {
  let $merge-options :=
    if ($merge-options instance of object-node()) then
      merging:options-from-json($merge-options)
    else
      $merge-options
  let $parsed-properties :=
      merging:parse-final-properties-for-merge(
        $uris,
        $merge-options
      )
  let $final-properties := map:get($parsed-properties, "final-properties")
  let $docs := map:get($parsed-properties, "documents")
  let $instances := map:get($parsed-properties, "instances")
  let $wrapper-qnames := map:get($parsed-properties, "wrapper-qnames")
  return
    merging:build-merge-models-by-final-properties(
      sem:uuid-string(),
      $docs,
      $wrapper-qnames,
      $final-properties,
      $merge-options
    )
};

declare function merging:build-merge-models-by-final-properties(
  $id as xs:string,
  $docs as node()*,
  $wrapper-qnames as xs:QName*,
  $final-properties as item()*,
  $merge-options as item()?
) {
  if ($docs instance of document-node(element())+) then
    merging:build-merge-models-by-final-properties-to-xml(
      $id,
      $docs,
      $wrapper-qnames,
      $final-properties,
      $merge-options
    )
  else
    merging:build-merge-models-by-final-properties-to-json(
      $id,
      $docs,
      $wrapper-qnames,
      $final-properties,
      $merge-options
    )
};


declare function merging:build-merge-models-by-final-properties-to-xml(
  $id as xs:string,
  $docs as node()*,
  $wrapper-qnames as xs:QName*,
  $final-properties as item()*,
  $merge-options as item()?
) {
  <es:envelope>
    <es:headers>
      <smart-mastering:id>{$id}</smart-mastering:id>
      <smart-mastering:merges>{
      $docs/es:envelope/es:headers/smart-mastering:merges/smart-mastering:document-uri,
      $docs ! element smart-mastering:document-uri { xdmp:node-uri(.) }
      }</smart-mastering:merges>
      <smart-mastering:sources>{
      $docs/es:envelope/es:headers/smart-mastering:sources/smart-mastering:source
      }</smart-mastering:sources>
    </es:headers>
    <es:instance>{
      merging:build-instance-body-by-final-properties(
        $final-properties,
        $wrapper-qnames,
        "xml"
      )
    }</es:instance>
  </es:envelope>
};

declare function merging:build-merge-models-by-final-properties-to-json(
  $id as xs:string,
  $docs as node()*,
  $wrapper-qnames as xs:QName*,
  $final-properties as item()*,
  $merge-options as item()?
) {
  object-node {
    "envelope": object-node {
      "headers": object-node {
        "id": $id,
        "merges": array-node {
          $docs/envelope/headers/merges/object-node(),
          $docs ! object-node { "document-uri": xdmp:node-uri(.) }
        },
        "sources": array-node {
          $docs/envelope/headers/sources/object-node()
        }
      },
      "instance": merging:build-instance-body-by-final-properties(
        $final-properties,
        $wrapper-qnames,
        "json"
      )
    }
  }
};

declare function merging:build-instance-body-by-final-properties(
  $final-properties as map:map*,
  $wrapper-qnames as xs:QName*,
  $type as xs:string
) {
  if ($type eq "json") then
    xdmp:to-json(
      fn:fold-left(
        function($child-object, $parent-name) {
          map:entry(fn:string($parent-name), $child-object)
        },
        fn:fold-left(
          function($map-a, $map-b) {
            $map-a + $map-b
          },
          map:map(),
          for $prop in $final-properties
          let $prop-name := $prop => map:get("name")
          let $prop-values := $prop => map:get("values")
          return
            map:entry($prop-name, $prop-values)
        ),
        $wrapper-qnames
      )
    )/object-node()
  else
    fn:fold-left(
      function($children, $parent-name) {
        element {$parent-name} {
          $children
        }
      },
      for $prop in $final-properties
      let $prop-values := $prop => map:get("values")
      return
        if ($prop-values instance of element()+) then
          $prop-values
        else
          element {($prop => map:get("name"))} {
            $prop-values
          }
      ,
      $wrapper-qnames
    )
};

declare function merging:parse-final-properties-for-merge(
  $uris as xs:string*,
  $merge-options as item()?
) {
  let $docs :=
    for $uri in $uris
    return
      fn:doc($uri)
  let $instances :=
    for $doc in $docs
    let $instance := $doc/(es:envelope|object-node("envelope"))/(es:instance|object-node("instance"))/(* except (es:info|object-node("info")))
    return
      if ($instance instance of element(MDM)) then
        $instance/*/*
      else
        $instance
  let $first-doc := fn:head($docs)
  let $first-instance := $instances[fn:root(.) is $first-doc]
  let $wrapper-qnames :=
    fn:reverse(
      ($first-instance/ancestor-or-self::*
        except
      $first-doc/(es:envelope|object-node("envelope"))/(es:instance|object-node("instance"))/ancestor-or-self::*)
      ! fn:node-name(.)
    )
  let $prop-history-info := ()
      (:for $doc-uri in fn:distinct-values($docs/(es:envelope|object-node("envelope"))
            /(es:headers|object-node("headers"))
            /(smart-mastering:merges|array-node("merges"))
            /(smart-mastering:document-uri|documentUri))
      return
        history:property-history($doc-uri, ()) ! xdmp:to-json(.)/object-node():)
  let $sources :=
    for $source in
      $docs/(es:envelope|object-node("envelope"))
            /(es:headers|object-node("headers"))
            /(smart-mastering:sources|array-node("sources"))
            /(smart-mastering:source|object-node())
    let $last-updated := $source/*:dateTime[. castable as xs:dateTime] ! xs:dateTime(.)
    order by $last-updated descending
    return
      object-node {
        "name": fn:string($source/*:name),
        "dateTime": fn:string($last-updated),
        "documentUri": xdmp:node-uri($source)
      }
  let $top-level-properties := fn:distinct-values($instances/* ! fn:node-name(.))
  let $merge-options-uri := $merge-options ! xdmp:node-uri(.)
  let $merge-options-ref :=
    if (fn:exists($merge-options-uri)) then
      $merge-options-uri
    else if (fn:exists($merge-options)) then
      xdmp:base64-encode(xdmp:describe($merge-options, (), ()))
    else
      null-node{}
  let $property-defs := $merge-options/merging:property-defs
  let $algorithms-map := merging:build-merging-map($merge-options)
  let $final-properties :=
    for $prop in $top-level-properties
    let $property-namespace := fn:namespace-uri-from-QName($prop)
    let $property-local-name := fn:local-name-from-QName($prop)
    let $property-name :=
      $property-defs
        /merging:property[@namespace = $property-namespace and @localname = $property-local-name]
        /@name
    let $property-spec :=
      $merge-options
        /merging:merging
        /merging:merge[@property-name = $property-name]
    let $algorithm-name := fn:string($property-spec/@algorithm-ref)
    let $algorithm := map:get($algorithms-map, $algorithm-name)
    let $algorithm-info :=
      object-node {
        "name": fn:head(($algorithm-name[fn:exists($algorithm)], "standard")),
        "optionsReference": $merge-options-ref
      }
    let $instance-props := $instances/*[fn:node-name(.) = $prop] ! (self::array-node()/*, . except self::array-node())
    let $instance-prop-count := fn:count($instance-props)
    return
      fn:fold-left(
        function($a as item()*, $b as item()) as item()* {
          if (
            fn:exists($a) and
            fn:deep-equal(map:get(fn:head(fn:reverse($a)),"values"), map:get($b,"values"))
          ) then
            fn:head(fn:reverse($a)) + $b
          else
            ($a, $b + map:entry("algorithm", $algorithm-info))
        },
        (),
        if (merging:properties-are-equal($instance-props, $docs)) then
          merging:wrap-revision-info($prop, $instance-props[fn:root(.) is $first-doc], $sources)
        else
          let $wrapped-properties :=
            for $doc at $pos in $docs
            let $props-for-instance := $instance-props[fn:root(.) is $doc]
            for $prop-value in $props-for-instance
            (:let $normalized-value := history:normalize-value-for-tracing($prop-value)
            let $source-details := $prop-history-info//object-node(fn:string($prop))/object-node($normalized-value)/sourceDetails
            :)
            let $lineage-uris :=
              (:if (fn:exists($source-details)) then
                $source-details/sourceLocation
              else:)
                xdmp:node-uri($doc)
            let $prop-sources := $sources[documentUri = $lineage-uris]
            where fn:exists($props-for-instance)
            return
              merging:wrap-revision-info($prop, $prop-value, $prop-sources)
          return
            if (fn:exists($algorithm)) then
              merging:execute-algorithm(
                $algorithm,
                $prop,
                $wrapped-properties,
                $property-spec
              )
            else
              merging:standard(
                $prop,
                $wrapped-properties,
                $property-spec
              )
      )
  return
    map:new((
      map:entry("instances", $instances),
      map:entry("sources", $sources),
      map:entry("documents", $docs),
      map:entry("wrapper-qnames",$wrapper-qnames),
      map:entry("final-properties", $final-properties)
    ))
};

declare function merging:wrap-revision-info($property-name as xs:QName, $properties as item()*, $sources as item()*) {
  for $prop in $properties
  return
  map:new((
    map:entry("name", $property-name),
    map:entry("sources", $sources),
    map:entry("values", $prop)
  ))
};

declare function merging:properties-are-equal(
  $properties as item()*,
  $docs as item()*
) {
  let $first-doc := fn:head($docs)
  let $first-doc-props := $properties[fn:root(.) is $first-doc]
  let $doc-1-prop-count := fn:count($first-doc-props)
  let $other-docs := fn:tail($docs)
  let $equal-count-of-properties :=
    every $doc in $other-docs
    satisfies
      fn:count($properties[fn:root(.) is $doc]) eq $doc-1-prop-count
  return
    $equal-count-of-properties
    and (
      every $doc in $other-docs
        satisfies
          every $prop1 in $first-doc-props
          satisfies
            some $prop2 in $properties[fn:root(.) is $doc]
            satisfies
              let $same-type := xdmp:type($prop1) eq xdmp:type($prop2)
              let $is-object := $prop1 instance of object-node()
              let $objects-are-equal := $same-type and $is-object and merging:objects-equal($prop1, $prop2)
              let $values-are-equal := $same-type and fn:not($is-object) and $prop1 = $prop2
              return
                $objects-are-equal or $values-are-equal
    )
};

(: Compare all keys and values between two maps :)
declare function merging:objects-equal($object1 as map:map, $object2 as map:map) {
  (:
   : $map1 - $map2: find key-value pairs that exist in $map1 but not $map2
   : $map1 + $map2: find the union of key-value pairs in the two maps
  :)
  map:count($object1 - $object2) = 0 and
    map:count($object1 + $object2) = map:count($object1)
};

declare function merging:execute-algorithm(
  $algorithm,
  $property-name,
  $properties,
  $property-spec
) {
  fun-ext:execute-function(
    $algorithm,
    map:new((
      map:entry("arg1", $property-name),
      map:entry("arg2", $properties),
      map:entry("arg4", $property-spec)
    ))
  )
};

declare function merging:get-options()
{
  cts:search(fn:collection(), cts:and-query((
      cts:collection-query($const:OPTIONS-COLL),
      cts:collection-query($const:MERGE-COLL)
  )))/merging:options
};

(:

Example merging options:

<options xmlns="http://marklogic.com/smart-mastering/survivorship/merging">
  <match-options>basic</match-options>
  <thresholds>
    <threshold label="Definitive Match" action="merge" />
    <threshold label="Likely Match" action="notify" />
  </thresholds>
  <property-defs>
    <property namespace="" localname="IdentificationID" name="ssn"/>
    <property namespace="" localname="PersonName" name="name"/>
    <property namespace="" localname="Address" name="address"/>
  </property-defs>
  <algorithms>
    <algorithm name="name" function="name"/>
    <algorithm name="address" function="address"/>
  </algorithms>
  <merging>
    <merge property-name="ssn" algorithm-ref="user-defined">
      <source-ref document-uri="docA" />
    </merge>
    <merge property-name="name"  max-values="1">
      <double-metaphone>
        <distance-threshold>50</distance-threshold>
      </double-metaphone>
      <synonyms-support>true</synonyms-support>
      <thesaurus>/mdm/config/thesauri/first-name-synonyms.xml</thesaurus>
      <length weight="8" />
    </merge>
    <merge property-name="address" algorithm-ref="address" max-values="1">
      <postal-code prefer="zip+4" />
      <length weight="8" />
      <double-metaphone>
        <distance-threshold>50</distance-threshold>
      </double-metaphone>
    </merge>
  </merging>
</options>
:)

declare function merging:get-options($options-name)
{
  fn:doc($MERGING-OPTIONS-DIR||$options-name||".xml")/merging:options
};

declare function merging:save-options(
  $name as xs:string,
  $options as node()
)
{
  xdmp:log("inserting at " || $MERGING-OPTIONS-DIR||$name||".xml"),
  xdmp:document-insert(
    $MERGING-OPTIONS-DIR||$name||".xml",
    $options,
    (xdmp:permission($const:MDM-ADMIN, "update"), xdmp:permission($const:MDM-USER, "read")),
    ($const:OPTIONS-COLL, $const:MERGE-COLL)
  )
};

declare function merging:archive-document($uri as xs:string)
{
  xdmp:document-remove-collections($uri, $const:CONTENT-COLL),
  xdmp:document-add-collections($uri, $const:ARCHIVED-COLL)
};

declare variable $options-json-config := merging:_options-json-config();

declare function merging:options-to-json($options-xml)
{
  xdmp:to-json(
    json:transform-to-json-object($options-xml, $options-json-config)
  )
};

declare function merging:options-from-json($options-json)
{
  json:transform-from-json($options-json, $options-json-config)
};

declare function merging:_options-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", ("algorithm","threshold","scoring","property", "reduce", "add", "expand")),
    map:put($config, "element-namespace", "http://marklogic.com/smart-mastering/matcher"),
    map:put($config, "element-namespace-prefix", "matcher"),
    map:put($config, "attribute-names",
      ("name","localname", "namespace", "function",
        "at", "property-name", "weight", "above", "label","algorithm-ref")
    ),
    $config
  )
};

declare function merging:get-option-names()
{
  let $options := cts:uris('', (), cts:and-query((
      cts:collection-query($const:OPTIONS-COLL),
      cts:collection-query($const:MERGE-COLL)
    )))
  let $option-names := $options ! fn:replace(
    fn:replace(., $MERGING-OPTIONS-DIR, ""),
    ".xml", ""
  )
  return
    element merging:options {
      for $name in $option-names
      return
        element merging:option { $name }
    }
};

declare variable $option-names-json-config := merging:_option-names-json-config();

declare function merging:_option-names-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", "option"),
    map:put($config, "element-namespace", "http://marklogic.com/smart-mastering/survivorship/merging"),
    map:put($config, "element-namespace-prefix", "merging"),
    $config
  )
};

declare function merging:option-names-to-json($options-xml)
{
  xdmp:to-json(
    json:transform-to-json-object($options-xml, $option-names-json-config)
  )
};
