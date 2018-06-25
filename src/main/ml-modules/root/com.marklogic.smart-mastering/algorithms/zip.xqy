xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

declare namespace matcher = "http://marklogic.com/smart-mastering/matcher";

declare option xdmp:mapping "false";

(:
 : Allow matches between 5- and 9-digit US ZIP codes. For each zip in $expand-values, generates a query to match values
 : that have the same first five digits. To add this algorithm to your match configuration, add XML like the following,
 : assuming that you have configured a property named "zip". Change the weights to work with your other properties. 
 :
 : <algorithms>
 :  <algorithm
 :    name="zip-code"
 :    function="zip-match"
 :    namespace="http://marklogic.com/smart-mastering/algorithms"
 :    at="/com.marklogic.smart-mastering"/>
 : </algorithms>
 : <scoring>
 :   <add property-name="zip" weight="5"/>
 :   <expand property-name="zip" algorithm-ref="zip-code">
 :     <zip origin="5" weight="3"/>
 :     <zip origin="9" weight="2"/>
 :   </expand>
 : </scoring>
 : Effect:
 :   If the original document has a 5-digit zip:
 :     A potential match with the same 5-digit zip will get 5 points.
 :     A potential match with a 9-digit zip that starts with the same five digits will get (5+3=)8 points.
 :   If the original document has a 9-digit zip:
 :     A potential match with the same 9-digit zip will get 5 points.
 :     A potential match with a 5-digit zip that matches the first five digits of the original document will get 2 points.
 :
 : @param $expand-values  the value(s) that the original document has for this property
 : @param $expand-xml  the scoring/expand element in the match options that applies this algorithm to a property
 : @param $options-xml  the complete match options
 :
 : @return a sequence of cts:querys based on the property values in the original document
 :)
declare function algorithms:zip-match(
  $expand-values as xs:string*,
  $expand-xml as element(matcher:expand),
  $options-xml as element(matcher:options)
)
  as cts:query*
{
  let $property-name := $expand-xml/@property-name
  let $property-def := $options-xml/matcher:property-defs/matcher:property[@name = $property-name]
  let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
  let $sep := "-"
  let $origin-5-weight := $expand-xml/matcher:zip[@origin = "5"]/@weight/fn:data()
  let $origin-9-weight := $expand-xml/matcher:zip[@origin = "9"]/@weight/fn:data()
  for $value in $expand-values
  return
    if (fn:string-length($value) = 5) then
      cts:element-value-query($qname, $value || $sep || "*", (), $origin-5-weight)
    else
      cts:element-value-query($qname, fn:substring($value, 1, 5), (), $origin-9-weight)
};
