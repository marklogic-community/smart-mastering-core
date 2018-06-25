declareUpdate();

const test = require('/test/test-helper.xqy');
const history = require('/com.marklogic.smart-mastering/auditing/history.xqy');
const con = require('/com.marklogic.smart-mastering/constants.xqy');
const merging = require('/com.marklogic.smart-mastering/merging.xqy');
const lib = require('lib/lib.xqy');

const mergedURI = cts.uris(null, "limit=1", cts.collectionQuery(con['MERGED-COLL']));
const actual = history.documentHistory(mergedURI).toObject();
const activity = actual.activities[0];

let assertions = [];

assertions.push(
  test.assertEqual('merge', activity.type),
  test.assertEqual(2, activity.wasDerivedFromUris.length)
);

// Run in a different transaction so we can see the results.
xdmp.invokeFunction(
  function() {
    merging.rollbackMerge(mergedURI, true)
  },
  lib['INVOKE_OPTIONS']
);

// check merged doc history
const postRollbackActual = history.documentHistory(mergedURI).toObject();

assertions.push(
  test.assertEqual(3, postRollbackActual.activities.length),

  test.assertEqual('rollback', postRollbackActual.activities[0].type),
  test.assertEqual(1, postRollbackActual.activities[0].wasDerivedFromUris.length),
  test.assertEqual(mergedURI, postRollbackActual.activities[0].wasDerivedFromUris[0]),
  test.assertTrue([lib.URI1, lib.URI2].includes(postRollbackActual.activities[0].resultUri)),

  test.assertEqual('rollback', postRollbackActual.activities[1].type),
  test.assertEqual(1, postRollbackActual.activities[1].wasDerivedFromUris.length),
  test.assertEqual(mergedURI, postRollbackActual.activities[1].wasDerivedFromUris[0]),
  test.assertTrue([lib.URI1, lib.URI2].includes(postRollbackActual.activities[1].resultUri))
);

// check doc1 history
const doc1Actual = history.documentHistory(lib.URI1).toObject();

assertions.push(
  test.assertEqual(2, doc1Actual.activities.length),

  test.assertEqual('rollback', doc1Actual.activities[0].type),
  test.assertEqual(1, doc1Actual.activities[0].wasDerivedFromUris.length),
  test.assertEqual(mergedURI, doc1Actual.activities[0].wasDerivedFromUris[0]),
  test.assertEqual(lib.URI1, doc1Actual.activities[0].resultUri),

  test.assertEqual('merge', doc1Actual.activities[1].type),
  test.assertEqual(2, doc1Actual.activities[1].wasDerivedFromUris.length),
  // assertSameValues doesn't currently work for JSON arrays. Add this back in when that's fixed.
  // See https://github.com/marklogic-community/ml-unit-test/issues/14
  // test.assertSameValues([lib.URI1, lib.URI2], doc1Actual.activities[1].wasDerivedFromUris),
  test.assertEqual(mergedURI, doc1Actual.activities[1].resultUri)
);

assertions
