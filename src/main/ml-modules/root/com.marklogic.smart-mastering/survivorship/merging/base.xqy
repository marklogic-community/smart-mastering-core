xquery version "1.0-ml";

module namespace merge-impl = "http://marklogic.com/smart-mastering/survivorship/merging";

import module namespace auditing = "http://marklogic.com/smart-mastering/auditing"
  at "../../auditing/base.xqy";
import module namespace fun-ext = "http://marklogic.com/smart-mastering/function-extension"
  at "../../function-extension/base.xqy";
import module namespace history = "http://marklogic.com/smart-mastering/auditing/history"
  at "../../auditing/history.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";
import module namespace merge-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at  "standard.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";
import module namespace sem = "http://marklogic.com/semantics"
  at "/MarkLogic/semantics.xqy";

declare namespace merging = "http://marklogic.com/smart-mastering/merging";
declare namespace sm = "http://marklogic.com/smart-mastering";
declare namespace es = "http://marklogic.com/entity-services";
declare namespace prov = "http://www.w3.org/ns/prov#";
declare namespace host = "http://marklogic.com/xdmp/status/host";

declare option xdmp:mapping "false";

declare variable $retain-rollback-info := fn:false();

declare variable $MERGING-OPTIONS-DIR := "/com.marklogic.smart-mastering/options/merging/";

declare variable $MERGED-DIR := "/com.marklogic.smart-mastering/merged/";

declare function merge-impl:default-function-lookup(
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

declare function merge-impl:build-merging-map($merging-xml)
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
          merge-impl:default-function-lookup(?, 3)
        )
      )
  ))
};

(:
 : Check whether all the URIs are already write-locked. If they are, they have been updated.
 : ASSUMPTION: If a content doc has been updated, it's because it was archived, which means that it was already merged.
 : Therefore, we don't want it to get merged into something else.
 : Scenario this is here to prevent is doing match-and-merge on multiple documents within the same transaction:
 : - docA -- docB is a good match, archive docA and docB; create docAB
 : - docB -- docA is a good match. docA and docB are already archived, don't create docBA.
 :
 : @param $uris list of URIs to be checked
 : @return fn:true() if this transaction already has write locks on ALL of the URIs
 :)
declare function merge-impl:all-merged($uris as xs:string*) as xs:boolean
{
  let $locks := xdmp:transaction-locks()/host:write/fn:string()
  return
    fn:fold-left(
      function($z, $a) {$z and $a},
      fn:true(),
      for $uri in $uris
      return $uri = $locks
    )
};

(:~
 : Merge the documents as specified by the merge options and update the
 : involved files in the database.
 : @param $uris URIs of the source documents that will be merged
 : @param $merge-options specification of how options are to be merged
 : @return in-memory copy of the merge result
 :)
declare function merge-impl:save-merge-models-by-uri(
  $uris as xs:string*,
  $merge-options as item()?
)
{
  if (merge-impl:all-merged($uris)) then
    xdmp:log("Skipping merge because all uris to be merged (" || fn:string-join($uris, ", ") ||
      ") were already write-locked", "debug")
  else
    let $merge-options :=
      if ($merge-options instance of object-node()) then
        merge-impl:options-from-json($merge-options)
      else
        $merge-options
    let $id := sem:uuid-string()
    let $merge-uri := $MERGED-DIR||$id||".xml"
    let $merged-uris := $uris[xdmp:document-get-collections(.) = $const:MERGED-COLL]
    let $uris :=
      for $uri in $uris
      let $is-merged := $uri = $merged-uris
      return
        if ($is-merged) then
          auditing:auditing-receipts-for-doc-uri($uri)
            /prov:collection/@prov:id[. ne $uri] ! fn:string(.)
        else
          $uri
    let $parsed-properties :=
        merge-impl:parse-final-properties-for-merge(
          $uris,
          $merge-options
        )
    let $final-properties := map:get($parsed-properties, "final-properties")
    let $final-headers := map:get($parsed-properties, "final-headers")
    let $header-ns-map := map:get($parsed-properties, $PROPKEY-HEADERS-NS-MAP)
    let $docs := map:get($parsed-properties, "documents")
    let $instances := map:get($parsed-properties, "instances")
    let $top-level-properties := map:get($parsed-properties, "top-level-properties")
    let $sources := map:get($parsed-properties, "sources")
    let $wrapper-qnames := map:get($parsed-properties, "wrapper-qnames")
    let $merged-document :=
      merge-impl:build-merge-models-by-final-properties(
        $id,
        $docs,
        $wrapper-qnames,
        $final-properties,
        $final-headers,
        $header-ns-map,
        $merge-options
      )
    let $_audit-trail :=
      auditing:audit-trace(
        $const:MERGE-ACTION,
        $uris,
        $merge-uri,
        let $generated-entity-id := $auditing:sm-prefix ||$merge-uri
        let $property-related-prov :=
          for $prop in $final-properties,
            $value in map:get($prop, "values")
          let $type := fn:string(fn:node-name($value))
          let $value-text := history:normalize-value-for-tracing($value)
          let $hash := xdmp:sha512($value-text)
          let $algorithm-info := map:get($prop, "algorithm")
          let $algorithm-agent := "algorithm:"||$algorithm-info/name||";options:"||$algorithm-info/optionsReference
          for $source in map:get($prop, "sources")
          let $used-entity-id := $auditing:sm-prefix || $source/documentUri || $type || $hash
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
      let $distinct-uris := fn:distinct-values(($uris, $merged-uris))[fn:doc-available(.)]
      let $collections := (
        $const:CONTENT-COLL,
        $const:MERGED-COLL,
        fn:distinct-values(
          $distinct-uris ! xdmp:document-get-collections(.)[fn:not(fn:starts-with(.,"mdm-"))]
        )
      )
      (: Can't archive these documents in the child transaction because this
       : transaction (the parent) already has read locks on them. We do the
       : merge in a child transaction so that for any notifications that get
       : generated, we can check whether the docs have been merged already and
       : have the notification report the new URI.
       :)
      let $_ := $distinct-uris ! merge-impl:archive-document(.)
      return
        xdmp:invoke-function(
          function() {
            merge-impl:record-merge($merge-uri, $merged-document, $collections)
          },
          map:new((map:entry("isolation", "different-transaction"), map:entry("update", "true")))
        )
    )
};

(:~
 : Insert the merged document into the database.
 : @param $merge-uri  the URI for the merged document
 : @param $merged-document  merged content
 : @param $merged-doc-collections  collections for the merged document
 : @return  ()
 :)
declare function merge-impl:record-merge($merge-uri, $merged-document, $merged-doc-collections)
  as empty-sequence()
{
  xdmp:document-insert(
    $merge-uri,
    $merged-document,
    (
      xdmp:permission($const:MDM-ADMIN, "update"),
      xdmp:permission($const:MDM-USER, "read")
    ),
    $merged-doc-collections
  )
};

declare function merge-impl:rollback-merge(
  $merged-doc-uri as xs:string
) as empty-sequence()
{
  merge-impl:rollback-merge($merged-doc-uri, fn:true())
};

declare function merge-impl:rollback-merge(
  $merged-doc-uri as xs:string,
  $retain-rollback-info as xs:boolean
) as empty-sequence()
{
  let $auditing-receipts-for-doc :=
    auditing:auditing-receipts-for-doc-uri($merged-doc-uri)
  where fn:exists($auditing-receipts-for-doc)
  return (
    let $uris := $auditing-receipts-for-doc/auditing:previous-uri ! fn:string(.)
    let $prevent-auto-match := matcher:block-matches($uris)
    for $previous-doc-uri in $uris
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

(:~
 : Construct a merged document from the given URIs, but do not update the
 : database.
 : @param $uris  URIs of the source documents that will be merged
 : @param $merge-options  specification of how options are to be merged
 : @return in-memory copy of the merge result
 :)
declare function merge-impl:build-merge-models-by-uri(
  $uris as xs:string*,
  $merge-options as item()?
)
{
  let $merge-options :=
    if ($merge-options instance of object-node()) then
      merge-impl:options-from-json($merge-options)
    else
      $merge-options
  let $parsed-properties :=
      merge-impl:parse-final-properties-for-merge(
        $uris,
        $merge-options
      )
  let $final-properties := map:get($parsed-properties, "final-properties")
  let $final-headers := map:get($parsed-properties, "final-headers")
  let $headers-ns-map := map:get($parsed-properties, $PROPKEY-HEADERS-NS-MAP)
  let $docs := map:get($parsed-properties, "documents")
  let $instances := map:get($parsed-properties, "instances")
  let $wrapper-qnames := map:get($parsed-properties, "wrapper-qnames")
  return
    merge-impl:build-merge-models-by-final-properties(
      sem:uuid-string(),
      $docs,
      $wrapper-qnames,
      $final-properties,
      $final-headers,
      $headers-ns-map,
      $merge-options
    )
};

declare function merge-impl:build-merge-models-by-final-properties(
  $id as xs:string,
  $docs as node()*,
  $wrapper-qnames as xs:QName*,
  $final-properties as item()*,
  $final-headers as item()*,
  $headers-ns-map as map:map,
  $merge-options as item()?
)
{
  if ($docs instance of document-node(element())+) then
    merge-impl:build-merge-models-by-final-properties-to-xml(
      $id,
      $docs,
      $wrapper-qnames,
      $final-properties,
      $final-headers,
      $headers-ns-map,
      $merge-options
    )
  else
    (: TODO: use final-headers in JSON :)
    merge-impl:build-merge-models-by-final-properties-to-json(
      $id,
      $docs,
      $wrapper-qnames,
      $final-properties,
      $final-headers,
      $merge-options
    )
};


declare function merge-impl:build-merge-models-by-final-properties-to-xml(
  $id as xs:string,
  $docs as node()*,
  $wrapper-qnames as xs:QName*,
  $final-properties as item()*,
  $final-headers as item()*,
  $headers-ns-map as map:map,
  $merge-options as item()?
)
{
  let $uris := $docs ! xdmp:node-uri(.)
  return
    <es:envelope>
      {
        merge-impl:build-headers($id, $docs, $uris, $final-headers, $headers-ns-map, $const:FORMAT-XML)
      }
      <es:triples>{
        sem:sparql(
          'construct { ?s ?p ?o } where { ?s ?p ?o }',
          (), "map",
          sem:store((), cts:document-query($uris))
        )
      }</es:triples>
      <es:instance>{
        merge-impl:build-instance-body-by-final-properties(
          $final-properties,
          $wrapper-qnames,
          "xml"
        )
      }</es:instance>
    </es:envelope>
};

(:~
 : Construct the <es:headers> element using merged values.
 : @param $id  identifier for the merged document
 : @param $docs  source documents; merged doc values drawn from these
 : @param $uris  URIs of the source documents
 : @param $final-headers  the result of merging headers from the source documents
 : @param $headers-ns-map  map of namespace prefixes to namespace URIs; used to
 :                         interpret paths in $final-headers
 : @param $format  $const:FORMAT-XML or $const:FORMAT-JSON
 : @return constructed <es:headers> element or object-node
 :)
declare function merge-impl:build-headers(
  $id as xs:string,
  $docs as node()*,
  $uris as xs:string*,
  $final-headers as item()*,
  $headers-ns-map as map:map?,
  $format as xs:string
)
{
  (: Combine the merged non-Smart-Mastering namespace headers. Some will be
    : configured and merged; some will not be configured and will just get
    : copied over. :)

  let $is-xml := $format = $const:FORMAT-XML
  (: remove "/*:envelope/*:headers" from the paths; already accounted for :)
  let $configured-paths := $final-headers ! map:get(., "path") ! fn:replace(., "/.*headers(/.*)", "$1")
  (: Identify the full and partial paths of the configured paths. Record in
    : a map for quick access. :)
  let $anc-path-map := map:new(merge-impl:config-paths-and-ancestors($configured-paths) ! map:entry(., 1))
  (: Identify the non-Smart-Mastering headers from the source documents.
   : Anything else will either be passed through to the merged document or
   : replaced by merged values. :)
  let $non-sm-headers :=
    if ($is-xml) then
      $docs/es:envelope/es:headers/*[fn:empty(self::sm:*)]
    else
      let $sm-keys := ("id", "sources")
      let $sm-map := fn:data($docs/object-node("envelope")/object-node("headers"))
      return
        let $m := map:map()
        let $_ :=
          for $map in $sm-map
          for $key in map:keys($map)
          where fn:not($key = $sm-keys)
          return map:put($m, $key, (map:get($m, $key), map:get($map, $key)))
        return $m
  (: Build a map that combines the unconfigured (pass-through) values from the
   : source docs with the merged values. :)
  let $combined :=
    let $m := map:map()
    let $populate :=
      if ($is-xml) then
        merge-impl:prep-unconfigured-xml("", $anc-path-map, $configured-paths, $non-sm-headers, $m)
      else
        merge-impl:prep-unconfigured-json("", $anc-path-map, $configured-paths, $non-sm-headers, $m)
    let $add-merged-values := merge-impl:add-merged-values($final-headers, $m)
    return $m
  (: Having built a map of XPaths -> elements, generate a properly-nested
   : list of XML elements or JSON properties. :)
  return
    if ($is-xml) then
      <es:headers>
        <sm:id>{$id}</sm:id>
        <sm:merges>{
          $docs/es:envelope/es:headers/sm:merges/sm:document-uri,
          $uris ! element sm:document-uri { . }
        }</sm:merges>
        <sm:sources>{
          $docs/es:envelope/es:headers/sm:sources/sm:source
        }</sm:sources>
        {
          merge-impl:map-to-xml($headers-ns-map, $combined)
        }
      </es:headers>
    else
      xdmp:to-json(
        map:new((
          map:entry("id", $id),
          map:entry("merges", array-node {
            $docs/envelope/headers/merges/object-node(),
            $uris ! object-node { "document-uri": . }
          }),
          map:entry("sources", array-node {
            $docs/envelope/headers/sources
          }),
          merge-impl:map-to-json($combined)
        ))
      )/object-node()
};

(:~
 : Examines a sequence of paths and returns a set of distinct paths and their
 : ancestors. For instance, given ("/a/b/c", "/a/b/d/e"), returns
 : ("/a", "/a/b", "/a/b/c", "/a/b/d", "/a/b/d/e")
 :)
declare function merge-impl:config-paths-and-ancestors($paths as xs:string*) as xs:string*
{
  fn:distinct-values(
    for $path in $paths
    let $parts := fn:tokenize($path, "/")[fn:not(.="")]
    let $count := fn:count($parts)
    for $i in (1 to $count)
    return "/" || fn:string-join($parts[1 to $i], "/")
  )
};

(:~
 : Work through the original header properties recursively. Properties that weren't
 : configured for merging pass through and will become part of the merged
 : document. Any property that conflicts with a configured path will be skipped.
 :
 : The $m parameter will have keys that are property names and values that
 : are either JSON to be included in the merged document, or another map:map.
 : This structure allows us to combine overlapping XPaths.
 : @param $path  current path being processed, relative to /envelope/headers
 : @param $anc-path-map  "ancestor path map"; used to quickly determine whether
 :                       the current path is part of a configured path
 : @param $configured-paths  sequence of full configured paths
 : @param $headers  all the non-Smart Mastering header objects from the source
 :                  documents
 : @param $m  recursive map:map where the keys are property names and the values
 :            are either map:maps (for the next level of properties down) or
 :            values to include in the merged document
 : @return ()  (no "as" clause to allow for tail call optimization)
 :)
declare function merge-impl:prep-unconfigured-json(
  $path as xs:string,
  $anc-path-map as map:map,
  $configured-paths as xs:string*,
  $headers as map:map*,
  $m as map:map
)
{
  for $header in $headers
  for $key in map:keys($header)
  let $curr-path := $path || "/" || $key
  let $current := map:get($header, $key)
  return
    if (fn:not(map:get($anc-path-map, $curr-path))) then
      (: This path is not related to any configured path, so we can just pass
        : any elements through. :)
      map:put($m, $key, (map:get($m, $key), $current))
    else if ($curr-path = $configured-paths) then
      (: Any elements here will be replaced by the calculated merged elements :)
      ()
    else
      if (fn:exists($current)) then
        let $child-map := map:map()
        let $populate :=
          merge-impl:prep-unconfigured-json($curr-path, $anc-path-map, $configured-paths, $current, $child-map)
        return
          if (map:keys($child-map)) then
            map:put(
              $m, $key,
              if (map:contains($m, $key)) then map:get($m, $key) + $child-map
              else $child-map
            )
          else ()
      else
        map:put($m, $key, (map:get($m, $key), $current))

};

(:~
 : Work through the original header elements recursively. Elements that weren't
 : configured for merging pass through and will become part of the merged
 : document. Any element that conflicts with a configured path will be skipped.
 :
 : The map:map parameter will have keys that are element names and values that
 : are either XML to be included in the merged document, or another map:map.
 : This structure allows us to combine overlapping XPaths.
 : @param $path  current path being processed, relative to /es:envelope/es:headers
 : @param $anc-path-map  "ancestor path map"; used to quickly determine whether
 :                       the current path is part of a configured path
 : @param $configured-paths  sequence of full configured paths
 : @param $headers  all the non-Smart Mastering header elements from the source
 :                  documents
 : @param $m  recursive map:map where the keys are element names and the values
 :            are either map:maps (for the next level of elements down) or
 :            values to include in the merged document
 : @return ()  (no "as" clause to allow for tail call optimization)
 :)
declare function merge-impl:prep-unconfigured-xml(
  $path as xs:string,
  $anc-path-map as map:map,
  $configured-paths as xs:string*,
  $headers,
  $m as map:map
)
{
  for $current in $headers
  let $curr-path := $path || "/" || fn:node-name($current)
  let $key := xdmp:key-from-QName(fn:node-name($current))
  return
    if (fn:not(map:get($anc-path-map, $curr-path))) then
      (: This path is not related to any configured path, so we can just pass
        : any elements through. :)
      map:put($m, $key, (map:get($m, $key), $current))
    else if ($curr-path = $configured-paths) then
      (: Any elements here will be replaced by the calculated merged elements :)
      ()
    else
      let $children := $current/element()
      return
        if (fn:exists($children)) then
          let $child-map := map:map()
          let $populate := merge-impl:prep-unconfigured-xml($curr-path, $anc-path-map, $configured-paths, $children, $child-map)
          return
            if (map:keys($child-map)) then
              map:put(
                $m, $key,
                if (map:contains($m, $key)) then map:get($m, $key) + $child-map
                else $child-map
              )
            else ()
        else
          map:put($m, $key, (map:get($m, $key), $current))
};

(:~
 : Helper function for add-merged-values.
 : @param $m  a map:map where the keys are element names and the values are
 :            nested maps or elements to be put in the merged document
 : @param $path-parts  the path to an element, tokenized by "/"
 : @param $value  the merged value for this header
 : @return ()  no "as" clause to allow for tail call optimization
 :)
declare function merge-impl:add-merged-part(
  $m as map:map,
  $path-parts as xs:string*,
  $value
)
{
  let $key := fn:head($path-parts)
  return
    if (map:contains($m, $key)) then
      let $present := map:get($m, $key) (: value is a map :)
      return
        if (fn:tail($path-parts)) then
          merge-impl:add-merged-part($present, fn:tail($path-parts), $value)
        else
          () (: won't happen :)
    else
      if (fn:tail($path-parts)) then
        let $child-map := map:map()
        let $populate := merge-impl:add-merged-part($child-map, fn:tail($path-parts), $value)
        return
          map:put($m, $key, $child-map)
      else
        map:put($m, $key, $value)
};

(:~
 : Combine the calculated merged header elements with those that are being
 : passed through.
 : @param $final-headers  a sequence of maps having "path" and "values"
 : @param $m  a map:map where the keys are element names and the values are
 :            nested maps or elements to be put in the merged document
 : @return ()  works by modifying $m
 :)
declare function merge-impl:add-merged-values($final-headers, $m as map:map)
{
  for $header in $final-headers
  (: remove "/*:envelope/*:headers" from the paths; already accounted for :)
  let $key := fn:replace(map:get($header, "path"), "/.*headers(/.*)", "$1")
  return
    merge-impl:add-merged-part($m, fn:tokenize($key, "/")[fn:not(. = "")], map:get($header, "values"))
};

(:~
 : Converts a map to XML, where the keys are XPaths and the values are elements.
 : @param $ns-map a map of namespace prefixes to namespace URIs
 : @param $m the map with XPath -> element mappings
 : @return a sequence of elements (no "as" clause to allow tail call optimization)
 :)
declare function merge-impl:map-to-xml($ns-map as map:map, $m as map:map)
{
  for $path in map:keys($m)
  let $value := map:get($m, $path)
  return
    if ($value instance of map:map) then
      if (map:contains($value, "sources") and map:contains($value, "values") and map:contains($value, "name")) then
        map:get($value, "values")
      else
        element { xdmp:with-namespaces($ns-map, xs:QName($path)) } {
          merge-impl:map-to-xml($ns-map, $value)
        }
    else if ($value instance of object-node()+) then (
      $value/values
    )
    else
      $value
};

(:~
 : The incoming structure is a nested set of map:maps, where the leaf nodes
 : contain the name of a property, the values for it, and the sources where
 : those values came from. Return a map:map that simplifies the leaf nodes to
 : just the values.
 :)
declare function merge-impl:map-to-json($m as map:map)
{
  if (map:contains($m, "sources") and map:contains($m, "values") and map:contains($m, "name")) then
    (: Extract the values and return those :)
    map:get($m, "values")
  else
    map:new(
      for $key in map:keys($m)
      let $value := map:get($m, $key)
      return
        if ($value instance of map:map) then
          map:entry($key, merge-impl:map-to-json($value))
        else
          (: Unconfigured values :)
          map:entry($key, $value)
    )
};

declare function merge-impl:build-merge-models-by-final-properties-to-json(
  $id as xs:string,
  $docs as node()*,
  $wrapper-qnames as xs:QName*,
  $final-properties as item()*,
  $final-headers as item()*,
  $merge-options as item()?
)
{
  let $uris := $docs ! xdmp:node-uri(.)
  return
    object-node {
      "envelope": object-node {
        "headers": merge-impl:build-headers($id, $docs, $uris, $final-headers, (), $const:FORMAT-JSON),
        "triples": array-node {
          sem:sparql(
            'construct { ?s ?p ?o } where { ?s ?p ?o }',
            (), "map",
            sem:store((), cts:document-query($uris))
          )
        },
        "instance": merge-impl:build-instance-body-by-final-properties(
          $final-properties,
          $wrapper-qnames,
          "json"
        )
      }
    }
};

declare function merge-impl:build-instance-body-by-final-properties(
  $final-properties as map:map*,
  $wrapper-qnames as xs:QName*,
  $type as xs:string
)
{
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
          let $prop-name := fn:string($prop => map:get("name"))
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

declare function merge-impl:get-instances($docs)
{
  for $doc in $docs
  let $instance := $doc/(es:envelope|object-node("envelope"))/(es:instance|object-node("instance"))/(*|object-node() except (es:info|object-node("info")))
  return
    if ($instance instance of element(MDM)) then
      $instance/*/*
    else if (fn:node-name($instance) eq xs:QName("MDM")) then
      $instance/object-node()/object-node()
    else
      $instance
};

declare function merge-impl:get-sources($docs)
  as object-node()*
{
  for $source in
    $docs/(es:envelope|object-node("envelope"))
    /(es:headers|object-node("headers"))
    /(sm:sources|array-node("sources"))
    /(sm:source|object-node())
  let $last-updated := $source/*:dateTime[. castable as xs:dateTime] ! xs:dateTime(.)
  order by $last-updated descending
  return
    object-node {
      "name": fn:string($source/*:name),
      "dateTime": fn:string($last-updated),
      "documentUri": xdmp:node-uri($source)
    }

};

declare variable $PROPKEY-HEADERS-NS-MAP := "headers-ns-map";

(:~
 : Extract the instance parts from the source documents and pass them to
 : functions that will do the property and header merges. Return a map with
 : that data.
 : @param $uris  URIs of the source documents
 : @param $merge-options  these control how the source data get merged together
 : @return map:map with merged information from the source docs
 :)
declare function merge-impl:parse-final-properties-for-merge(
  $uris as xs:string*,
  $merge-options as item()?
) as map:map
{
  let $docs :=
    for $uri in $uris
    return
      fn:doc($uri)
  let $instances := merge-impl:get-instances($docs)
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
            /(sm:merges|array-node("merges"))
            /(sm:document-uri|documentUri))
      return
        history:property-history($doc-uri, ()) ! xdmp:to-json(.)/object-node():)
  let $sources := get-sources($docs)
  let $final-properties := merge-impl:build-final-properties(
    $merge-options,
    $instances,
    $docs,
    $sources)
  let $final-headers := merge-impl:build-final-headers(
    $merge-options,
    $docs,
    $sources
  )
  return
    map:new((
      map:entry("instances", $instances),
      map:entry("sources", $sources),
      map:entry("documents", $docs),
      map:entry("wrapper-qnames",$wrapper-qnames),
      map:entry("final-properties", $final-properties),
      map:entry($PROPKEY-HEADERS-NS-MAP, fn:head($final-headers)),
      map:entry("final-headers", fn:tail($final-headers))
    ))
};

(:~
 : Build a sequence of maps that contain, for each configured header, the
 : algorithm used to do the merging, the merged values, and the sources of
 : those values (embedded in the values).
 : @param $merge-options  an element or object containing the merge options
 : @param $docs  the source documents the header values will be drawn from
 : @param $sources  information about the source of the header data
 : @return sequence of maps. First map is the mapping from namespace prefixes
 :         to namespace URIs, as configured on the property-defs element. The
 :         rest of the maps are final header values.
 :)
declare function merge-impl:build-final-headers(
  $merge-options as element(merging:options),
  $docs,
  $sources
) as map:map*
{
  let $property-defs := $merge-options/merging:property-defs/merging:property[fn:exists(@path)]
  let $algorithms-map := merge-impl:build-merging-map($merge-options)
  let $merge-options-uri := $merge-options ! xdmp:node-uri(.)
  let $merge-options-ref :=
    if (fn:exists($merge-options-uri)) then
      $merge-options-uri
    else if (fn:exists($merge-options)) then
      xdmp:base64-encode(xdmp:describe($merge-options, (), ()))
    else
      null-node{}
  let $ns-map :=
    map:new(
      let $parent := $merge-options/merging:property-defs
      for $prefix in fn:in-scope-prefixes($parent)
      return map:entry($prefix, fn:namespace-uri-for-prefix($prefix, $parent))
    )
  return (
    $ns-map,
    for $property in $property-defs
    let $prop-name as xs:string := $property/@name
    let $property-spec :=
      $merge-options/merging:merging/merging:merge[@property-name = $prop-name]
    let $algorithm-name := fn:string($property-spec/@algorithm-ref)
    let $algorithm := map:get($algorithms-map, $algorithm-name)
    let $algorithm-info :=
      object-node {
        "name": fn:head(($algorithm-name[fn:exists($algorithm)], "standard")),
        "optionsReference": $merge-options-ref
      }
    let $raw-values := merge-impl:get-raw-values($docs, $property, $sources, $ns-map)
    return
      if (fn:exists($raw-values)) then
        map:new((
          map:entry("algorithm", $algorithm-info),
          map:entry("values",
            (: get the merged values :)
            if (fn:exists($algorithm)) then
              merge-impl:execute-algorithm(
                $algorithm,
                map:get(fn:head($raw-values), "name"),
                $raw-values,
                $property-spec
              )
            else
              merge-impl:standard(
                map:get(fn:head($raw-values), "name"),
                $raw-values,
                $property-spec
              )
          ),
          map:entry("path", $property/@path/fn:string())
        ))
      else ()
  )
};

(:~
 : Identify and merge any headers whose paths are given in the merge options.
 : @param $docs  the source documents
 : @param $property  the property specification, which includes the path to
 :                   look for source values
 : @param $sources  structure reflecting the origin of the data
 : @param $ns-map maps from namespace prefixes to namespace URIs
 : @return a sequence of maps, one for each value of this property found in a
 :         source document
 :)
declare function merge-impl:get-raw-values(
  $docs,
  $property as element(merging:property),
  $sources,
  $ns-map as map:map?
) as map:map*
{
  let $wrapped := map:map()
  let $path := $property/@path/fn:string()
  let $path-tail := fn:replace($path, "(.*/)", "")
  let $prop-qname := fn:resolve-QName($path-tail, $property)
  for $doc in $docs
  let $values := xdmp:unpath($path, $ns-map, $doc)
  let $curr-uri := xdmp:node-uri($doc)
  let $prop-sources := $sources[documentUri = $curr-uri]
  return
    if (fn:exists($values)) then
      merge-impl:wrap-revision-info(
        $prop-qname,
        $values,
        $prop-sources
      )
    else ()
};

(:
 : Returns a sequence of map:maps, one for each top-level property. Each map has the following keys:
 : - "algorithm" -- object-node with the name and optionsReference of the algorithm used for this property
 : - "sources" -- one or more object-nodes indicating which of the original docs the surviving value(s) came from
 : - "values" -- the surviving property values
 :)
declare function merge-impl:build-final-properties(
  $merge-options,
  $instances,
  $docs,
  $sources
) as map:map*
{
  let $top-level-properties := fn:distinct-values($instances/* ! fn:node-name(.))
  let $property-defs := $merge-options/merging:property-defs[fn:exists(merging:property/@localname)]
  let $algorithms-map := merge-impl:build-merging-map($merge-options)
  let $merge-options-uri := $merge-options ! xdmp:node-uri(.)
  let $merge-options-ref :=
    if (fn:exists($merge-options-uri)) then
      $merge-options-uri
    else if (fn:exists($merge-options)) then
      xdmp:base64-encode(xdmp:describe($merge-options, (), ()))
    else
      null-node{}
  let $first-doc := fn:head($docs)
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
  let $instance-props :=
    for $instance-prop in $instances/*[fn:node-name(.) = $prop]
    (: require the property to have a value :)
    where fn:normalize-space(fn:string-join(($instance-prop|$instance-prop//node()) ! fn:string())) ne ""
    return ($instance-prop/self::array-node()/*, $instance-prop except $instance-prop/self::array-node())
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
      if (merge-impl:properties-are-equal($instance-props, $docs)) then
        merge-impl:wrap-revision-info($prop, $instance-props[fn:root(.) is $first-doc], $sources)
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
            merge-impl:wrap-revision-info($prop, $prop-value, $prop-sources)
        return
          if (fn:exists($algorithm)) then
            merge-impl:execute-algorithm(
              $algorithm,
              $prop,
              $wrapped-properties,
              $property-spec
            )
          else
            merge-impl:standard(
              $prop,
              $wrapped-properties,
              $property-spec
            )
    )
};

declare function merge-impl:wrap-revision-info($property-name as xs:QName, $properties as item()*, $sources as item()*)
  as map:map*
{
  for $prop in $properties
  return
  map:new((
    map:entry("name", $property-name),
    map:entry("sources", $sources),
    map:entry("values", $prop)
  ))
};

declare function merge-impl:properties-are-equal(
  $properties as item()*,
  $docs as item()*
)
{
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
              let $objects-are-equal := $same-type and $is-object and merge-impl:objects-equal($prop1, $prop2)
              let $values-are-equal := $same-type and fn:not($is-object) and $prop1 = $prop2
              return
                $objects-are-equal or $values-are-equal
    )
};

(: Compare all keys and values between two maps :)
declare function merge-impl:objects-equal($object1 as map:map, $object2 as map:map) as xs:boolean
{
  merge-impl:objects-equal-recursive($object1, $object2)
};

declare function merge-impl:objects-equal-recursive($object1, $object2)
{
  typeswitch($object1)
    case map:map return
      let $k1 := map:keys($object1)
      let $k2 := map:keys($object2)
      let $counts-equal := fn:count($k1) eq fn:count($k2)
      let $maps-equal :=
        for $key in map:keys($object1)
        let $v1 := map:get($object1, $key)
        let $v2 := map:get($object2, $key)
        return
          merge-impl:objects-equal-recursive($v1, $v2)
      return $counts-equal and fn:not($maps-equal = fn:false())
    case json:array return
      let $counts-equal := fn:count($object1) = fn:count($object2)
      let $items-equal :=
        let $o1 := json:array-values($object1)
        let $o2 := json:array-values($object2)
        for $item at $i in $o1
        return
          merge-impl:objects-equal-recursive($item, $o2[$i])
      return
        $counts-equal and fn:not($items-equal = fn:false())
    default return
      $object1 = $object2
};

declare function merge-impl:execute-algorithm(
  $algorithm,
  $property-name,
  $properties,
  $property-spec
)
{
  if (fn:ends-with(xdmp:function-module($algorithm), "sjs")) then
    let $properties := json:to-array($properties)
    let $property-spec := merge-impl:propertyspec-to-json($property-spec)
    return
      xdmp:apply($algorithm, $property-name, $properties, $property-spec)
  else
    xdmp:apply($algorithm, $property-name, $properties, $property-spec)
};

declare function merge-impl:get-options($format as xs:string)
{
  let $options :=
    cts:search(fn:collection(), cts:and-query((
        cts:collection-query($const:OPTIONS-COLL),
        cts:collection-query($const:MERGE-COLL)
    )))/merging:options
  return
    if ($format eq $const:FORMAT-XML) then
      $options
    else
      array-node { $options ! merge-impl:options-to-json(.) }
};

(:

Example merging options:

<options xmlns="http://marklogic.com/smart-mastering/merging">
  <match-options>basic</match-options>
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

declare function merge-impl:get-options($options-name, $format as xs:string)
{
  let $options := fn:doc($MERGING-OPTIONS-DIR||$options-name||".xml")/merging:options
  return
    if ($format eq $const:FORMAT-XML) then
      $options
    else
      merge-impl:options-to-json($options)
};

declare function merge-impl:save-options(
  $name as xs:string,
  $options as node()
)
{
  let $options :=
    if ($options instance of object-node()) then
      merge-impl:options-from-json($options)
    else
      $options
  return
    xdmp:document-insert(
      $MERGING-OPTIONS-DIR||$name||".xml",
      $options,
      (xdmp:permission($const:MDM-ADMIN, "update"), xdmp:permission($const:MDM-USER, "read")),
      ($const:OPTIONS-COLL, $const:MERGE-COLL)
    )
};

declare function merge-impl:archive-document($uri as xs:string)
{
  xdmp:document-remove-collections($uri, $const:CONTENT-COLL),
  xdmp:document-add-collections($uri, $const:ARCHIVED-COLL)
};

declare variable $options-json-config := merge-impl:_options-json-config();

(: Removes whitespace nodes to keep the output json from options-to-json clean :)
declare function merge-impl:remove-whitespace($xml)
{
  for $x in $xml
  return
    typeswitch($x)
      case element() return
        element { fn:node-name($x) } {
          merge-impl:remove-whitespace(($x/@*, $x/node()))
        }
      case text() return
        if (fn:string-length(fn:normalize-space($x)) > 0) then
          $x
        else ()
      default return $x
};

declare function merge-impl:options-to-json($options-xml)
{
  if (fn:exists($options-xml)) then
    xdmp:to-json(
      json:transform-to-json-object(
        merge-impl:remove-whitespace($options-xml), $options-json-config)
    )/node()
  else ()
};

declare function merge-impl:options-from-json($options-json)
{
  json:transform-from-json($options-json, $options-json-config)
};

declare function merge-impl:_options-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", ("algorithm","threshold","scoring","property", "reduce", "add", "expand")),
    map:put($config, "element-namespace", "http://marklogic.com/smart-mastering/merging"),
    map:put($config, "element-namespace-prefix", "merging"),
    map:put($config, "attribute-names",
      ("name","localname", "namespace", "function",
        "at", "property-name", "weight", "above", "label","algorithm-ref")
    ),
    map:put($config, "camel-case", fn:true()),
    map:put($config, "whitepsace", "ignore"),
    $config
  )
};

declare function merge-impl:get-option-names($format as xs:string)
{
  if ($format eq $const:FORMAT-XML) then
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
  else if ($format eq $const:FORMAT-JSON) then
    merge-impl:option-names-to-json(merge-impl:get-option-names($const:FORMAT-XML))
  else
    fn:error(xs:QName("SM-INVALID-FORMAT"), "Attempted to call merge-impl:get-option-names with invalid format: " || $format)
};

declare variable $option-names-json-config := merge-impl:_option-names-json-config();

declare function merge-impl:_option-names-json-config()
{
  let $config := json:config("custom")
  return (
    map:put($config, "array-element-names", "option"),
    map:put($config, "element-namespace", "http://marklogic.com/smart-mastering/survivorship/merging"),
    map:put($config, "element-namespace-prefix", "merging"),
    $config
  )
};

declare function merge-impl:option-names-to-json($options-xml)
{
  xdmp:to-json(
    json:transform-to-json-object($options-xml, $option-names-json-config)
  )
};

declare function merge-impl:propertyspec-to-json($property-spec as element(merging:merge)) as object-node()
{
  let $config := json:config("custom")
    => map:with("camel-case", fn:true())
    => map:with("whitespace", "ignore")
    => map:with("ignore-element-names", xs:QName("merging:merge"))
  return
    json:transform-to-json($property-spec, $config)/*:merge
};
