const test = require('/test/test-helper.xqy');
const matcher = require('/ext/com.marklogic.smart-mastering/matcher.xqy');
const lib = require('/test/suites/notifications/lib/lib.xqy');


const notificationXML = matcher.getExistingMatchNotification(lib['LBL-LIKELY'], lib['URI-SET1']);
const notificationURI = fn.baseUri(notificationXML);
const notification = matcher.notificationToJson(notificationXML);

const notifyObj = notification.toObject();

[].concat(
  test.assertEqual(lib['LBL-LIKELY'], notifyObj.thresholdLabel),
  test.assertEqual(3, notifyObj.uris.length),
  test.assertEqual(notificationURI, notifyObj.meta.uri)
)

/*
  object-node {
      "meta": object-node {
      "dateTime": $notification/smart-mastering:meta/smart-mastering:dateTime/fn:string(),
      "user": $notification/smart-mastering:meta/smart-mastering:user/fn:string()
    },
    "thresholdLabel": $notification/smart-mastering:threshold-label/fn:string(),
    "uris": array-node {
      for $uri in $notification/smart-mastering:document-uris/smart-mastering:document-uri
      return
        object-node { "uri": $uri/fn:string() }
    }
  }


<smart-mastering:notification xmlns:smart-mastering="http://marklogic.com/smart-mastering">
  <smart-mastering:meta>
    <smart-mastering:dateTime>2018-04-20T17:49:13.4138Z</smart-mastering:dateTime>
    <smart-mastering:user>admin</smart-mastering:user>
  </smart-mastering:meta>
  <smart-mastering:threshold-label>Likely Match</smart-mastering:threshold-label>
  <smart-mastering:document-uris>
    <smart-mastering:document-uri>/Oracle/Person/5346756037.xml</smart-mastering:document-uri>
    <smart-mastering:document-uri>/com.marklogic.smart-mastering/merged/d78a0c8c-eba8-40f8-84d6-ea42420b4fb4.xml</smart-mastering:document-uri>
    <smart-mastering:document-uri>/CRM/Person/6986792174.xml</smart-mastering:document-uri>
    </smart-mastering:document-uris>
  </smart-mastering:notification>
 */
