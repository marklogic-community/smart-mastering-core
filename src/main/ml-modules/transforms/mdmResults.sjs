const es= require("/MarkLogic/entity-services/entity-services.xqy");

function mdmResults(context, params, content)
{
  if (context.inputType.search('json') >= 0) {
    let result = content.toObject();
    result.results = result.results.map(function(r) {
      const doc = fn.doc(r.uri);
      let res = Object.assign({}, r);
      res.content = es.instanceFromDocument(doc);
      res.collections = xdmp.documentGetCollections(r.uri);
      return res;
    });
    return result;
  } else {
    /* Pass thru for non-JSON documents */
    return content;
  }
};

exports.transform = mdmResults;
