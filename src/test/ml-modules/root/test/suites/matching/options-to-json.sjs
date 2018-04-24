const test = require('/test/test-helper.xqy');
const matcher = require('/ext/com.marklogic.smart-mastering/matcher.xqy');

const options = matcher.getOptions("match-test");

const actual = matcher.optionsToJson(options).root;

[].concat(
  test.assertEqual("200", actual.options.tuning['max-scan'].data)
)
