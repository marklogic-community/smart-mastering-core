const test = require('/test/test-helper.xqy');
const con = require('/ext/com.marklogic.smart-mastering/constants.xqy');
const matcher = require('/ext/com.marklogic.smart-mastering/matcher.xqy');
const notify = require('/ext/com.marklogic.smart-mastering/matcher-impl/notification-impl.xqy');
const lib = require('/test/suites/notifications/lib/lib.xqy');


const notificationXML = notify.getExistingMatchNotification(lib['LBL-LIKELY'], lib['URI-SET1']);
const notificationURI = fn.baseUri(notificationXML);
const notification = notify.notificationToJson(notificationXML);

const notifyObj = notification.toObject();

[].concat(
  test.assertEqual(lib['LBL-LIKELY'], notifyObj.thresholdLabel),
  test.assertEqual(fn.count(lib['URI-SET1']), notifyObj.uris.length),
  test.assertEqual(notificationURI, notifyObj.meta.uri),
  test.assertEqual(con['STATUS-UNREAD'], notifyObj.meta.status)
)
