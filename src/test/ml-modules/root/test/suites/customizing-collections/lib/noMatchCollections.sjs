'use strict';

const lib = require('lib.xqy');

function noMatchCollections(eventName, collectionsByUri, eventOptions) {
  return [
    lib['ALGORITHM-NO-MATCH-COLLECTION']
  ];
}

exports.noMatchCollections = noMatchCollections;
