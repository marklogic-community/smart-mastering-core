const test = require('/test/test-helper.xqy');
const lib = require('/test/suites/matching/lib/lib.xqy');
const matcher = require('/com.marklogic.smart-mastering/matcher.xqy');

/**
 * Purpose of test: Ensure matches can be made via
 *
 */

const httpOptions = {
  "credentialId": xs.unsignedLong(fn.string(test.DEFAULT_HTTP_OPTIONS.xpath('.//*:credential-id'))),
  "headers": { "Content-Type": "application/json", "Accept": "application/json"}
};

const resp = fn.head(fn.tail(test.httpPost(`v1/resources/sm-match?rs:options=${lib['MATCH-OPTIONS-NAME']}`, httpOptions, new NodeBuilder().addNode({
    "document": {
        "PersonSurName": "JONES",
        "PersonGivenName": "LYNDSEY"
      }
  }).toNode()))).toObject();

test.assertEqual(resp.results.total, "3");
