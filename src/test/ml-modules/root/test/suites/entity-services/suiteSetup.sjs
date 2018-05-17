'use strict';
declareUpdate();

const es = require('/MarkLogic/entity-services/entity-services.xqy');
const test = require('/test/test-helper.xqy');

const desc = test.getTestFile('PersonNameType.entity.json');

// Create the model
xdmp.documentInsert(
  '/es-gs/models/person-0.0.1.json', es.modelValidate(desc),
  {collections: ['http://marklogic.com/entity-services/models']}
);
