xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

declare option xdmp:mapping "false";

declare function algorithms:standard-reduction($matching-result, $reduce-xml, $options-xml)
{
  every $property-name in $reduce-xml/*:all-match/*:property
  satisfies (
    let $property-def := $options-xml/*:property-defs/*:property[@name = $property-name]
    where fn:exists($property-def)
    return
      let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
      return fn:exists($matching-result/*:matches//*[fn:node-name(.) eq $qname])
  )
};

declare function algorithms:standard-reduction-query(
  $document
  , $reduce-xml
  , $options-xml 
) as cts:query? {
  cts:and-query((
  for $property-name in $reduce-xml/*:all-match/*:property
  return
    let $property-def := $options-xml/*:property-defs/*:property[@name = $property-name]
    where fn:exists($property-def)
    return
      let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
      let $value := $document//*[fn:node-name(.) eq $qname]
      return cts:element-value-query($qname, $value, (), -1*$reduce-xml/@weight)
  ))
};