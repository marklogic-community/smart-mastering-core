xquery version "1.0-ml";

module namespace custom-merging = "http://marklogic.com/smart-mastering/merging";

declare function custom-merging:customThing(
  $property-name as xs:QName,
  $properties as map:map*,
  $property-spec as element()?
) {
  let $values :=
    for $property in $properties
    let $value := map:get($property, "values")
    order by $value descending
    return $property
  return
    fn:subsequence(
      $values,
      1,
      fn:head(($property-spec/@max-values, 99))
    )
};
