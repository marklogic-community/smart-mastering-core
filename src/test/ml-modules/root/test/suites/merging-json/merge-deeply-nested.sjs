declareUpdate();

const con = require("/com.marklogic.smart-mastering/constants.xqy");

const test = require("/test/test-helper.xqy");
const lib = require("lib/lib.xqy");

let uris = [];
for (uri in lib['NESTED-DATA']) { uris.push(uri); }
let uriStr = uris.join('##');

// Merge the nested docs
let mergedDoc =
  fn.head(xdmp.xqueryEval(
    `
      import module namespace merging = "http://marklogic.com/smart-mastering/merging"
        at "/com.marklogic.smart-mastering/merging.xqy";
      import module namespace const = "http://marklogic.com/smart-mastering/constants"
        at "/com.marklogic.smart-mastering/constants.xqy";
      declare variable $uri-str as xs:string external;
      declare variable $uris as xs:string* := fn:tokenize($uri-str, "##");
      declare variable $options-name as xs:string external;

      let $options as element() := merging:get-options($options-name, $const:FORMAT-XML)
      return
        merging:save-merge-models-by-uri(
          $uris,
          $options)
    `,
    {
      "uri-str": uriStr,
      "options-name": lib['NESTED-OPTIONS']
    },
    {
      "isolation": "different-transaction"
    }
  ));

[].concat(
  test.assertEqual("another string", mergedDoc.envelope.instance.TopProperty.LowerProperty1.EvenLowerProperty.LowestProperty1.toString()),
  test.assertEqual("some string", mergedDoc.envelope.instance.TopProperty.LowerProperty1.EvenLowerProperty.LowestProperty2.toString()),
  // test.assertEqual("another string", mergedDoc.envelope.instance.TopProperty.LowerProperty1.EvenLowerProperty.LowestProperty3.toString()),
  test.assertEqual(123, mergedDoc.envelope.instance.TopProperty.EntityReference.PropValue.valueOf())
)
