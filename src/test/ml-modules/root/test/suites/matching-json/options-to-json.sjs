const test = require('/test/test-helper.xqy');
const lib = require('/test/suites/matching/lib/lib.xqy');
const matcher = require('/com.marklogic.smart-mastering/matcher.xqy');

/**
 * Purpose of test: retrieve match options as JSON and make sure they are
 * formatted correctly.
 */

const actual = matcher.getOptionsAsJson(lib['MATCH-OPTIONS-NAME']).toObject();

let assertions = [];

assertions.push(
  test.assertEqual("200", actual.options.tuning.maxScan.toString()),
  test.assertEqual(7, actual.options.propertyDefs.property.length),
  test.assertEqual(2, actual.options.algorithms.algorithm.length),
  test.assertEqual(7, actual.options.scoring.add.length),
  test.assertEqual(2, actual.options.scoring.expand.length)
);

for (let add of actual.options.scoring.add) {
  assertions.push(test.assertExists(add.propertyName));
  if (add.propertyName === 'ssn') {
    assertions.push(
      test.assertEqual('50', add.weight)
    )
  } else if (["last-name", "first-name", "addr1", "city", "state", "zip"].includes(add.propertyName) ) {
    // all's well
  } else {
    test.fail("Unexpected scoring.add.propertyName=" + add.propertyName);
  }
}

for (let expand of actual.options.scoring.expand) {
  assertions.push(test.assertExists(expand.propertyName));
  if (expand.propertyName === 'first-name') {
    assertions.push(
      test.assertEqual('dbl-metaphone', expand.algorithmRef),
      test.assertEqual('6', expand.weight),
      test.assertEqual('name-dictionary.xml', expand.dictionary),
      test.assertEqual('10', expand.distanceThreshold)
    );
  } else if (expand.propertyName === 'last-name') {
    // all's well
  } else {
    test.fail("Unexpected scoring.expand.propertyName=" + expand.propertyName);
  }
}

assertions
