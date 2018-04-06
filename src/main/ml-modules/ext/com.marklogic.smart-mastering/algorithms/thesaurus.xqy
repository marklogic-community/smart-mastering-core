xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

import module namespace thsr = "http://marklogic.com/xdmp/thesaurus"
  at "/MarkLogic/thesaurus.xqy";

declare option xdmp:mapping "false";

declare function algorithms:thesaurus($expand-values, $expand-xml, $options-xml)
{
  let $property-name := $expand-xml/@property-name
  let $property-def := $options-xml/*:property-defs/*:property[@name = $property-name]
  let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
  let $thesaurus := $expand-xml/*:thesaurus
  where fn:exists($thesaurus)
  return
    for $value in $expand-values
    let $entries := thsr:lookup($thesaurus, fn:lower-case($value))
    where fn:exists($entries)
    return
      thsr:expand(
        cts:element-value-query(
          $qname, 
          fn:lower-case($value),
          "case-insensitive",
          0
        ),
        $entries,
        $expand-xml/@weight,
        (),
        $expand-xml/*:filter/*
      )
};
