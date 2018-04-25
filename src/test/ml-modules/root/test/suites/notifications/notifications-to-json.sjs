const test = require('/test/test-helper.xqy');
const matcher = require('/ext/com.marklogic.smart-mastering/matcher.xqy');
const lib = require('/test/suites/notifications/lib/lib.xqy');


const notificationXML = matcher.getExistingMatchNotification(lib['LBL-LIKELY'], lib['URI-SET1']);
const notificationURI = fn.baseUri(notificationXML);
const notification = matcher.notificationToJson(notificationXML);

const notifyObj = notification.toObject();

[].concat(
  test.assertEqual(lib['LBL-LIKELY'], notifyObj.thresholdLabel),
  test.assertEqual(fn.count(lib['URI-SET1']), notifyObj.uris.length),
  test.assertEqual(notificationURI, notifyObj.meta.uri),
  test.assertEqual(matcher['STATUS-UNREAD'], notifyObj.meta.status)
)
