const test = require('/test/test-helper.xqy');
const lib = require('/test/suites/matching/lib/lib.xqy');
const matcher = require('/com.marklogic.smart-mastering/matcher.xqy');

/**
 * Purpose of test: Ensure our error messages are checking for required parameters.
 *
 */

let httpOptions = {
  "credentialId": xs.unsignedLong(fn.string(test.DEFAULT_HTTP_OPTIONS.xpath('.//*:credential-id'))),
  "headers": { "Content-Type": "application/json", "Accept": "application/json"}
};

let resourceExtensions = fn.head(fn.tail(test.httpGet("v1/config/resources", httpOptions))).toObject();

resourceExtensions.resources.resource.forEach((resource) => {
  if (resource.name.startsWith("sm-")) {
    resource.methods.method.forEach((method) => {
      let titleCaseMethod = method['method-name'].replace(/^(.)|\s(.)/g, ($1) => $1.toUpperCase());
      let parameters = method.parameter || [];
      let requiredParameters = parameters.filter((param) => /^xs\:([A-Za-z]+)(\+)?$/.test(param['parameter-type']));
      if (requiredParameters.length) {
        let httpResponse = fn.head(fn.tail(xdmp[`http${titleCaseMethod}`](
            test.easyUrl(`v1/resources/${resource.name}`),
            httpOptions
          ))).toObject();
        requiredParameters.forEach((param) => {
          let re = new RegExp(param['parameter-name'] + " .* required","g");
          test.assertEqual(
            `${titleCaseMethod.toUpperCase()} ${resource.name} requires parameters: true`,
            `${titleCaseMethod.toUpperCase()} ${resource.name} requires parameters: ${re.test(httpResponse.errorResponse.message)}`
          );
        });
      }
    });
  }
});

// Test additional corner cases.
// sm-match without uri or document in POST body
let httpResponse = fn.head(fn.tail(xdmp.httpPost(
    test.easyUrl(`v1/resources/sm-match`),
    httpOptions
  ))).toObject();
let re = new RegExp("valid uri .* or document .* required","g");
test.assertEqual(
  `POST sm-match requires uri or doc in body: true`,
  `POST sm-match requires uri or doc in body: ${re.test(httpResponse.errorResponse.message)}`
);
// sm-match with document in POST body
httpResponse = fn.head(fn.tail(xdmp.httpPost(
    test.easyUrl(`v1/resources/sm-match`),
    httpOptions,
    new NodeBuilder().addNode({ "document": { "test": "blah" }}).toNode()
  ))).toObject();
test.assertEqual(
  `POST sm-match requires uri or doc in body: false`,
  `POST sm-match requires uri or doc in body: ${re.test(httpResponse.errorResponse.message)}`
);
