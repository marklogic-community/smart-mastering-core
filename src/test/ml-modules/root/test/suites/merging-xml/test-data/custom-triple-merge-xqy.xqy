xquery version "1.0-ml";

module namespace custom-merging = "http://marklogic.com/smart-mastering/merging";

declare namespace m = "http://marklogic.com/smart-mastering/merging";

declare function custom-merging:customTrips(
  $merge-options as element(m:options),
  $docs,
  $sources,
  $property-spec as element()?
) {
  let $some-param := $property-spec/*:some-param ! xs:int(.)
  return
    sem:triple(sem:iri("some-param"), sem:iri("is"), $some-param)
};
