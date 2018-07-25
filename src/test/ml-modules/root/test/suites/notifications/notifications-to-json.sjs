const test = require('/test/test-helper.xqy');
const con = require('/com.marklogic.smart-mastering/constants.xqy');
const matcher = require('/com.marklogic.smart-mastering/matcher.xqy');
const notify = require('/com.marklogic.smart-mastering/matcher-impl/notification-impl.xqy');
const lib = require('/test/suites/notifications/lib/lib.xqy');

const extractions = {
  "lastName": "PersonSurName",
  "stuff": "junk"
};

const notificationsXML = matcher.getNotifications(1, 5, extractions, con['FORMAT-XML']);

let notificationXML = null;
for (const notification of notificationsXML) {
  // Pick out the notification we're interested in
  if (fn.head(notification.xpath("/*:threshold-label/fn:string()")) === lib['LBL-LIKELY']) {
    notificationXML = notification;
  }
}

const notificationURI = fn.baseUri(notificationXML);
const notification = notify.notificationToJson(notificationXML);

const notifyObj = notification.toObject();

let assertions = [].concat(
  test.assertEqual(lib['LBL-LIKELY'], notifyObj.thresholdLabel),
  test.assertEqual(fn.count(lib['URI-SET1']), notifyObj.uris.length),
  test.assertEqual(notificationURI, notifyObj.meta.uri),
  test.assertEqual(con['STATUS-UNREAD'], notifyObj.meta.status),

  test.assertEqual(3, Object.keys(notifyObj.extractions).length)
);

for (let i = 1; i < 4; i++) {
  let extraction = notifyObj.extractions[lib['URI' + i]];
  assertions = assertions.concat(
    test.assertEqual(2, Object.keys(extraction).length),
    test.assertEqual("JONES", extraction.lastName),
    test.assertEqual("", extraction.stuff)
  );
}

assertions;
