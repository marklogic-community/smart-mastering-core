'use strict'

function maxMerge(propertyName, properties, propertySpec) {
  const sortedProperties = properties.toArray().sort((a, b) => {
    if (a.values > b.values) return -1;
    if (a.values < b.values) return 1;
    return 0;
  });
  const maxValues = fn.head(propertySpec).getAttribute('max-values') || 99;
  return fn.subsequence(xdmp.arrayValues(sortedProperties), 1, maxValues);
}

exports.customThing = maxMerge;
