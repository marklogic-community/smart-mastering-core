xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

import module namespace flow = "http://marklogic.com/data-hub/flow-lib"
  at "/MarkLogic/data-hub-framework/impl/flow-lib.xqy";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

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
  let $content := $doc/es:instance/*

  let $model-mapping := plugin:get-model-mapping(
        $headers[self::sm:sources]/sm:source/sm:import-id
      )
  where fn:exists($content)
  return (
    map:put($options, "headers", $headers),
    flow:instance-to-canonical-xml(
      plugin:extract-instance-MDM(
        $content,
        $model-mapping
      )
    )
  ),
  map:put($options, "original-collections", xdmp:document-get-collections($id))
};


(:~
 : Creates a map:map instance from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a MDM
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function plugin:extract-instance-MDM(
    $source as node()?,
    $model-mapping as map:map
)
{
  (: the original source documents :)
  let $attachments := $source
  (: return the in-memory instance :)
  let $model :=
    json:object()
      =>map:with('$attachments', $attachments)
      =>map:with('$type', 'MDM')
  let $_ :=
    plugin:build-from-annotated-xml($source, $model, $model-mapping, "$.")

  return
    $model
};

declare function plugin:make-reference-object(
  $type as xs:string
) as json:object {
  json:object()
    => map:with('$type', $type||"Type")
};

declare function plugin:get-model-mapping(
  $import-id as xs:string
) as map:map {
  fn:collection($const:MODEL-MAPPER-COLL)
  /object-node()[importID = $import-id]/modelMapping
};

declare function plugin:build-from-annotated-xml(
  $node as node(),
  $model as map:map,
  $model-mapping as map:map,
  $place-in-model as xs:string
) as empty-sequence()
{
  typeswitch($node)
  case element() return (
    if (map:contains($model-mapping, fn:local-name($node))) then (
      let $full-path := map:get($model-mapping, fn:local-name($node))
      let $path-relative-to-model := fn:substring-after($full-path, $place-in-model)
      let $property-name := fn:tokenize($full-path, "\.")[fn:last()]
      let $value :=
        if (fn:exists($node//*[map:contains($model-mapping, fn:local-name(.))])) then (
          let $ref-model := plugin:make-reference-object($property-name)
          return (
            $ref-model,
            fn:map(
              plugin:build-from-annotated-xml(?, $ref-model, $model-mapping, $full-path),
              $node/*
            )
          )
        ) else
          fn:upper-case(fn:normalize-space(fn:string($node)))
      return (
        plugin:place-in-model-path($model, $value, $path-relative-to-model)
      )
    ) else
      fn:map(plugin:build-from-annotated-xml(?, $model, $model-mapping, $place-in-model), $node/*)
  )
  case document-node() return
    fn:map(plugin:build-from-annotated-xml(?, $model, $model-mapping, $place-in-model), $node/*)
  default return
    ()
};

declare function plugin:place-in-model-path(
  $model as json:object,
  $value as item()*,
  $path as xs:string
) as empty-sequence()
{
  plugin:_place-in-model-path(
    $model,
    $value,
    fn:tokenize($path, "\.")[.]
  )
};

declare function plugin:_place-in-model-path(
  $model as json:object,
  $value as item()*,
  $path-parts as xs:string*
) as empty-sequence()
{
  if (fn:count($path-parts) gt 1) then (
    let $property-name := fn:head($path-parts)
    let $ref-model :=
        map:get($model, $property-name)[. instance of json:object]
    let $ref-model :=
      if (fn:exists($ref-model)) then
        $ref-model
      else (
        let $new-ref := plugin:make-reference-object($property-name)
        return (
          map:put($model, $property-name, $new-ref),
          $new-ref
        )
      )
    return (
      plugin:_place-in-model-path($ref-model, $value, fn:tail($path-parts))
    )
  ) else if (fn:exists($path-parts)) then
    map:put(
      $model,
      fn:head($path-parts),
      (map:get($model, fn:head($path-parts)), $value)
    )
  else ()
};
