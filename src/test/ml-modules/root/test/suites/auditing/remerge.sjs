declareUpdate();

// Testing this scenario:
// - docs 1 and 2 get merged (done by setup.xqy)
// - docs 3 and 4 get merged
// - docs 1 and 2 get unmerged
// - doc 2 and doc 3/4 get merged
// - doc 1 shows doc 2/3/4 in history

const test = require('/test/test-helper.xqy');
const history = require('/com.marklogic.smart-mastering/auditing/history.xqy');
const con = require('/com.marklogic.smart-mastering/constants.xqy');
const merging = require('/com.marklogic.smart-mastering/merging.xqy');
const lib = require('lib/lib.xqy');

const docUriQname = fn.QName('http://marklogic.com/smart-mastering', 'document-uri');

let assertions = [];

function findMergedDoc(uris) {
  return fn.head(cts.uris(null, null,
    cts.andQuery([
      cts.collectionQuery('mdm-merged'),
      uris.map(uri => cts.elementValueQuery(docUriQname, uri))
    ])
  ))
}

const doc12URI = findMergedDoc([lib.URI1, lib.URI2]);

xdmp.invokeFunction(
  function() { merging.saveMergeModelsByUri([lib.URI3, lib.URI4], merging.getOptions(lib.OPTIONSNAME, con.FORMATXML)) },
  lib.INVOKE_OPTIONS
);

const doc34URI = findMergedDoc([lib.URI3, lib.URI4]);

xdmp.invokeFunction(
  function() { merging.rollbackMerge(doc12URI, true) },
  lib.INVOKE_OPTIONS
);

xdmp.invokeFunction(
  function() { merging.saveMergeModelsByUri([lib.URI2, doc34URI], merging.getOptions(lib.OPTIONSNAME, con.FORMATXML)) },
  lib.INVOKE_OPTIONS
);

// examine doc1's history
const doc1History = history.documentHistory(lib.URI1).toObject();

// activities are in reverse chronological order (most recent first)
assertions.push(
  test.assertEqual(2, doc1History.activities.length),
  test.assertEqual("merge", doc1History.activities[1].type),
  // assertSameValues doesn't currently work for JSON arrays. Add this back in when that's fixed.
  // test.assertSameValues([lib.URI1, lib.URI2], doc1History.activities[1].wasDerivedFromUris),
  test.assertEqual("rollback", doc1History.activities[0].type),
  test.assertEqual(lib.URI1, doc1History.activities[0].resultUri)
);

assertions.push(test.success());

assertions
