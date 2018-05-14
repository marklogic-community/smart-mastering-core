declareUpdate();

const test = require('/test/test-helper.xqy');
const history = require('/ext/com.marklogic.smart-mastering/auditing/history.xqy');
const con = require('/ext/com.marklogic.smart-mastering/constants.xqy');
const merging = require('/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy');
const lib = require('lib/lib.xqy');

const mergedURI = cts.uris(null, "limit=1", cts.collectionQuery(con['MERGED-COLL']));
const actual = history.documentHistory(mergedURI);
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

const postRollbackActual = history.documentHistory(mergedURI);
const postRollbackActivity = postRollbackActual.activities[1];

assertions.push(
  test.assertEqual('rollback', postRollbackActivity.type),
  test.assertEqual(1, postRollbackActivity.wasDerivedFromUris.length)
);

xdmp.log("assertions: " + assertions.join(","));

assertions
