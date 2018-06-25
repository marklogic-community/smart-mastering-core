const test = require("/test/test-helper.xqy");

const esImpl = require("/com.marklogic.smart-mastering/impl/sm-es-impl.xqy");

const actual = esImpl.getEntityDescriptors();

const first = actual[0].toObject();

[
  test.assertEqual(1, actual.length),
  test.assertEqual('PersonName', first.entityTitle),
  test.assertEqual(4, first.properties.length)
]
