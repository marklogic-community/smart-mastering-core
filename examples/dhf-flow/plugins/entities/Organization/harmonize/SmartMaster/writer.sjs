const con = require("/com.marklogic.smart-mastering/constants.xqy");
const process = require("/com.marklogic.smart-mastering/process-records.xqy");


/*~
 * Writer Plugin
 *
 * @param id       - the identifier returned by the collector
 * @param envelope - the final envelope
 * @param options  - an object options. Options are sent from Java
 *
 * @return - nothing
 */
function write(id, envelope, options) {
  // Make sure the incoming document is in the appropriate
  // collections. We are doing this because the incoming
  // document could have already been merged with another
  // document since this batch flow was invoked. No need
  // to run it through again.
  let docCollections =
    fn.head(
      xdmp.invokeFunction(function() {
        return xdmp.documentGetCollections(id);
      })
    );

  if (docCollections &&
      docCollections.includes(con['CONTENT-COLL']) &&
      !docCollections.includes(con['MERGED-COLL']))
  {
    // run smart mastering against the incoming document uri
    process.processMatchAndMerge(id, 'org-merge-options', cts.collectionQuery('Organization'))
  }
}

module.exports = write;
