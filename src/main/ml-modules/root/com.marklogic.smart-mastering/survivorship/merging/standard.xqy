xquery version "1.0-ml";

module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging";

(:
 : This is the default method of combining the set of values for a property across entities that are being merged.
 : Sample $property-spec:
 :     <merge property-name="name"  max-values="1">
 :       <length weight="8" />
 :       <source-weights>
 :         <source name="good-source" weight="2"/>
 :         <source name="better-source" weight="4"/>
 :       </source-weights>
 :     </merge>
 :
 : @param $property-name  The name of the property being merged
 : @param $all-properties  A sequence of maps, each with "name" (the name of the property), "sources" (the URIs of the
 :                         lineage docs the value came from), and "values" (a value for that property).
 : @param $property-spec  The /merging:merging/merging:merge element of merge options that corresponds to a particular property
 :
 : @return selected property value(s)
 :)
declare function merging:standard(
  $property-name as xs:QName,
  $all-properties as map:map*,
  $property-spec as element()?
)
{
  fn:subsequence(
    (
      let $length-weight :=
        fn:head((
          $property-spec/merging:length/@weight ! fn:number(.),
          0
        ))
      for $property in merging:standard-condense-properties(
                          $property-name,
                          $all-properties,
                          $property-spec
                        )
      let $prop-value := map:get($property, "values")
      let $sources := map:get($property,"sources")
      let $source-dateTime := fn:max($sources/dateTime[. castable as xs:dateTime] ! xs:dateTime(.))
      let $length-score := fn:string-length(fn:string-join($prop-value//text()," ")) * $length-weight
      let $source-score := fn:sum((
          for $source in $sources
          return
            $property-spec
              /merging:source-weights
              /merging:source[@name = $source/name]/@weight
        ))
      let $weight := $length-score + $source-score
      stable order by $weight descending, $source-dateTime descending
      return
        $property
    ),
    1,
    fn:head(
      ($property-spec/@max-values, 99)
    )
  )
};

declare function merging:standard-condense-properties(
  $property-name as xs:QName,
  $all-properties as item()*,
  $property-spec as element()?
)
{
  if (fn:count((
        ($all-properties ! map:get(., "values") ! fn:root(.)) union ()
      )) eq 1) then
    $all-properties
  else
    merging:merge-complementing-properties(
      $all-properties,
      ()
    )
};

declare function merging:merge-complementing-properties(
  $remaining-properties,
  $merged-properties
)
{
  if (fn:empty($remaining-properties)) then
    $merged-properties
  else if (fn:empty($merged-properties) and fn:count($remaining-properties) eq 1) then
    $remaining-properties
  else
    let $complementing-indexes-map := map:map()
    let $current-property := fn:head($remaining-properties)
    let $current-property-values := $current-property => map:get("values")
    let $following-properties := fn:tail($remaining-properties)
    let $is-nested := fn:count(fn:head($current-property-values)/*) eq 1 and fn:exists($current-property-values/*/*)
    let $complementing-properties :=
      for $prop at $pos in $following-properties
      let $prop-values := $prop => map:get("values")
      let $sub-values :=
        if ($is-nested) then
          $prop-values/*/*
        else
          $prop-values/*
      where
        (
          fn:empty($sub-values)
            and
          $prop-values = $current-property-values
        )
        or
        (
          fn:exists($sub-values)
            and
          (every $sub-value in $sub-values,
            $sub-value-qn in fn:node-name($sub-value),
            $counterpart-sub-value in $current-property-values/(.|*)/*[fn:node-name(.) eq $sub-value-qn]
          satisfies
            $sub-value eq ""
              or
            $counterpart-sub-value = ($sub-value, ""))
        )
      return
        let $_set-index :=
          $complementing-indexes-map => map:put("$indexes", (map:get($complementing-indexes-map, "$indexes"),$pos))
        return
          $prop
    let $merged-properties :=
      if (fn:exists($complementing-properties)) then
        let $all-complementing-values := (
          $current-property-values,
          $complementing-properties ! map:get(., "values")
        )
        let $distinct-property-names :=
          if ($is-nested) then
            fn:distinct-values($all-complementing-values/*/* ! fn:node-name(.))
          else
            fn:distinct-values($all-complementing-values/* ! fn:node-name(.))
        let $current-property-name := $current-property => map:get("name")
        return (
          $merged-properties,
          map:new((
            map:entry("sources", (
              $current-property => map:get("sources"),
              $complementing-properties ! map:get(., "sources")
            )),
            map:entry("values", (
              if ($current-property-values instance of element()+) then
                element {$current-property-name} {
                  let $selected-items :=
                    for $prop-name in $distinct-property-names
                    return
                      fn:head($all-complementing-values/(.|*)/*[fn:node-name(.) eq $prop-name][fn:normalize-space()])
                  return
                    if (fn:empty($current-property-values/*)) then
                      $current-property-values/text()
                    else if ($is-nested) then
                      element {fn:node-name(fn:head($current-property-values)/*)} {
                        $selected-items
                      }
                    else
                      $selected-items
                }
              else if ($current-property-values instance of object-node()) then
                object-node {
                  $current-property-name: (
                    xdmp:to-json(map:new((
                      for $prop-name in $distinct-property-names
                      return
                        map:entry(
                          fn:string($prop-name),
                          fn:head($all-complementing-values/*[fn:node-name(.) eq $prop-name][fn:normalize-space()])
                        )
                    ))
                    )/object-node()
                  )
                }
              else
                $all-complementing-values
            )),
            map:entry("name", $current-property-name)
          ))
        )
      else (
        $merged-properties,
        $current-property
      )
    let $complementing-indexes := $complementing-indexes-map => map:get("$indexes")
    return
      merging:merge-complementing-properties(
        if (fn:exists($complementing-indexes)) then
          $following-properties[fn:not(fn:position() = $complementing-indexes)]
        else
          $following-properties,
        $merged-properties
      )
};
