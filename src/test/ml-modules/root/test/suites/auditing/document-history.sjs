declareUpdate();

const test = require('/test/test-helper.xqy');
const history = require('/ext/com.marklogic.smart-mastering/auditing/history.xqy');
const con = require('/ext/com.marklogic.smart-mastering/constants.xqy');
const merging = require('/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy');
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

const postRollbackActual = history.documentHistory(mergedURI).toObject();

// Match /source/1/doc1.xml and /source/2/doc2.xml
let origDocRegEx = RegExp('/source/[0-9]/doc[0-9]\.xml');

postRollbackActual.activities.forEach(activity => {
  if (activity.type === 'merge') {
    assertions.push(
      test.assertEqual(2, activity.wasDerivedFromUris.length),
      test.assertEqual(mergedURI, activity.resultUri),
      test.assertTrue(activity.label.startsWith("merge by"))
    )
  } else if (activity.type === 'rollback') {
    // There will be two of these, one for each of the original docs that got merged
    assertions.push(
      test.assertEqual(1, activity.wasDerivedFromUris.length),
      test.assertEqual(mergedURI, activity.wasDerivedFromUris),
      test.assertTrue(origDocRegEx.test(activity.resultUri)),
      test.assertTrue(activity.label.startsWith("rollback by"))
    )
  } else {
    test.fail("activity type should be merge or rollback but is " + activity.type);
  }
});

assertions
