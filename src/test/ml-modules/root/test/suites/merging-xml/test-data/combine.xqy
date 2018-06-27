xquery version "1.0-ml";

module namespace combine = "http://marklogic.com/smart-mastering/merging";

declare function combine:combine(
  $property-name as xs:QName,
  $properties as map:map*,
  $property-spec as element()?
)
{
  let $values :=
    for $property in $properties
    let $value := map:get($property, "values")
    return $value
  return
    (: turn ("shallow value 1", "shallow value 2") into "shallow value 12" :)
    fn:fold-left(
      function($z, $a) {
        $z || fn:replace($a, "[^\d]+", "")
      },
      fn:head($values),
      fn:tail($values)
    )
};
