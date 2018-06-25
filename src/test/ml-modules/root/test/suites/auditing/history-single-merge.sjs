declareUpdate();

const test = require('/test/test-helper.xqy');
const history = require('/com.marklogic.smart-mastering/auditing/history.xqy');
const con = require('/com.marklogic.smart-mastering/constants.xqy');
const merging = require('/com.marklogic.smart-mastering/merging.xqy');
const lib = require('lib/lib.xqy');

const mergedURI = cts.uris(null, "limit=1", cts.collectionQuery(con['MERGED-COLL']));

const actual = history.documentHistory(mergedURI).toObject();

let assertions = [];

// Check the history on the merged document
assertions.push(
  test.assertEqual(1, actual.activities.length),
  test.assertEqual('merge', actual.activities[0].type),
  test.assertEqual(2, actual.activities[0].wasDerivedFromUris.length),
  test.assertEqual(mergedURI, actual.activities[0].resultUri)
);

// Check the history on doc1
const actual1 = history.documentHistory(lib.URI1).toObject();
assertions.push(
  test.assertEqual(1, actual1.activities.length),
  test.assertEqual('merge', actual1.activities[0].type),
  test.assertEqual(2, actual1.activities[0].wasDerivedFromUris.length),
  test.assertEqual(mergedURI, actual1.activities[0].resultUri)
);

// Check the history on doc2
const actual2 = history.documentHistory(lib.URI2).toObject();
assertions.push(
  test.assertEqual(1, actual2.activities.length),
  test.assertEqual('merge', actual2.activities[0].type),
  test.assertEqual(2, actual2.activities[0].wasDerivedFromUris.length),
  test.assertEqual(mergedURI, actual2.activities[0].resultUri)
);

assertions
