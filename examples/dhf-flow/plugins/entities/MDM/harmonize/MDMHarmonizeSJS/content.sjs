'use strict'

/*
* Create Content Plugin
*
* @param id         - the identifier returned by the collector
* @param options    - an object containing options. Options are sent from Java
*
* @return - your content
*/
function createContent(id, options) {
  let doc = cts.doc(id);
  options.collections = xdmp.documentGetCollections(id).toArray();
  let source;

  // for xml we need to use xpath
  if(doc && xdmp.nodeKind(doc) === 'element' && doc instanceof XMLDocument) {
    source = doc.xpath("./*:envelope/*:instance/*");
    options.headers = doc.xpath("./*:envelope/*:headers/*");
  }
  // for json we need to return the instance
  else if(doc && doc instanceof Document) {
    source = fn.head(doc.root.envelope.instance);
    options.headers = doc.root.envelope.headers;
  }
  // for everything else
  else {
    source = doc;
  }

  return source;
}

module.exports = {
  createContent: createContent
};

