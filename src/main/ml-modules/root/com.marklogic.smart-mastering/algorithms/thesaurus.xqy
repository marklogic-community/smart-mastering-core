xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

import module namespace thsr = "http://marklogic.com/xdmp/thesaurus"
  at "/MarkLogic/thesaurus.xqy";

declare namespace match = "http://marklogic.com/smart-mastering/matcher";

declare option xdmp:mapping "false";

(:
 : Build a query that expands on the provided name(s) in $expand-values.
 : Note that the weight for this query will be the same for the original target value and for any values that are
 : found in the thesaurus. If we use zero for the original value's weight, the resulting query doesn't end up
 : awarding points for synonym matches.
 :)
declare function algorithms:thesaurus(
  $expand-values as xs:string*,
  $expand-xml as element(match:expand),
  $options-xml as element(match:options)
)
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
          $expand-xml/@weight
        ),
        $entries,
        $expand-xml/@weight,
        (),
        $expand-xml/*:filter/*
      )
};
