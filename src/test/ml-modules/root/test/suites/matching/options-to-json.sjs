const test = require('/test/test-helper.xqy');
const matcher = require('/ext/com.marklogic.smart-mastering/matcher.xqy');

const options = matcher.getOptions("match-test");

const actual = matcher.optionsToJson(options).root;

[].concat(
  test.assertEqual("200", actual.options.tuning['max-scan'].data),
  test.assertEqual(7, actual.options['property-defs'].property.length),
  test.assertEqual(3, actual.options.algorithms.algorithm.length)
)
