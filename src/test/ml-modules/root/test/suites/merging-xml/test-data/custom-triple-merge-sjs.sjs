'use strict'

function customTrips(mergeOptions, docs, sources, propertySpec) {
  const someParam = parseInt(propertySpec.someParam, 10);
  return sem.triple(sem.iri("some-param"), sem.iri("is"), someParam);
}

exports.customTrips = customTrips;
