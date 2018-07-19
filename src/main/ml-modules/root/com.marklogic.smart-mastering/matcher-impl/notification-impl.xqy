xquery version "1.0-ml";

(:
 : This is an implementation library, not an interface to the Smart Mastering functionality.
 :)

module namespace notify-impl = "http://marklogic.com/smart-mastering/notification-impl";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
  at "/MarkLogic/json/json.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

declare function notify-impl:save-match-notification(
  $threshold-label as xs:string,
  $uris as xs:string*
) as element(sm:notification)
{
  let $existing-notification :=
    notify-impl:get-existing-match-notification(
      $threshold-label,
      $uris,
      map:map()
    )
  let $new-notification :=
    element sm:notification {
      element sm:meta {
        element sm:dateTime {fn:current-dateTime()},
        element sm:user {xdmp:get-current-user()},
        element sm:status { $const:STATUS-UNREAD }
      },
      element sm:threshold-label {$threshold-label},
      element sm:document-uris {
        notify-impl:find-notify-uris($uris, $existing-notification)
      }
    }
  return (
    $new-notification,
    if (fn:exists($existing-notification)) then (
      xdmp:node-replace(fn:head($existing-notification), $new-notification),
      for $extra-doc in fn:tail($existing-notification)
      return
        xdmp:document-delete(xdmp:node-uri($extra-doc))
    ) else
      xdmp:document-insert(
        "/com.marklogic.smart-mastering/matcher/notifications/" ||
          sem:uuid-string() || ".xml",
        $new-notification,
        (
          xdmp:default-permissions(),
          xdmp:permission($const:MDM-USER, "read"),
          xdmp:permission($const:MDM-USER, "update")
        ),
        $const:NOTIFICATION-COLL
      )
  )
};

(:
 : It may be the case that one of the URIs has already been merged with some
 : other document. In that case, replace it with the URI of the doc it was
 : merged into. This can happen when process-match-and-merge gets run multiple
 : times in a single transaction. Document merges happen in a child transaction
 : so that they will be visible here.
 :)
declare function notify-impl:find-notify-uris($uris as xs:string*, $existing-notification)
  as element(sm:document-uri)*
{
  (: check each URI to see whether it appears in a merged document :)
  let $updated-uris :=
    for $uri in $uris
    let $merged-uri :=
      cts:uris((), (),
        cts:and-query((
          cts:collection-query($const:CONTENT-COLL),
          cts:collection-query($const:MERGED-COLL),
          cts:element-value-query(xs:QName("sm:document-uri"), $uri))
        ))
    return fn:head(($merged-uri, $uri))
  let $distinct-uris :=
    fn:distinct-values((
      $updated-uris,
      $existing-notification
      /sm:document-uris
        /sm:document-uri ! fn:string(.)
    ))
  for $uri in $distinct-uris
  return
    element sm:document-uri {
      $uri
    }
};

declare function notify-impl:get-existing-match-notification(
  $threshold-label as xs:string?,
  $uris as xs:string*,
  $extractions as map:map
) as element(sm:notification)*
{
  let $keys := map:keys($extractions)
  for $notification in cts:search(fn:collection()/sm:notification,
    cts:and-query((
      if (fn:exists($threshold-label)) then
        cts:element-value-query(
          xs:QName("sm:threshold-label"),
          $threshold-label
        )
      else (),
      if (fn:exists($uris)) then
        cts:element-value-query(
          xs:QName("sm:document-uri"),
          $uris
        )
      else ()
    ))
  )
  return
    if (fn:exists($keys)) then
      notify-impl:enhance-notification-xml($notification, $extractions)
    else
      $notification
};

declare function notify-impl:enhance-notification-xml(
  $notification as element(sm:notification),
  $extractions as map:map)
as element(sm:notification)
{
  element sm:notification {
    $notification/@*,
    attribute xml:base { xdmp:node-uri($notification) },
    $notification/node(),

    (: build extractions :)
    let $keys := map:keys($extractions)
    where fn:exists($keys)
    return
      for $uri in $notification/sm:document-uris/sm:document-uri
      let $doc := fn:doc($uri)
      return
        element sm:extractions {
          attribute uri { $uri },
          for $key in map:keys($extractions)
          let $xpath := "$doc//*:" || map:get($extractions, $key)
          let $value := xdmp:value($xpath)
          return
            element sm:extraction {
              attribute name { $key },
              $value
            }
        }
  }
};


(:
 : Delete the specified notification
 : TODO: do we want to add any provenance tracking to this?
 :)
declare function notify-impl:delete-notification($uri as xs:string)
  as empty-sequence()
{
  xdmp:document-delete($uri)
};

(:
 : Translate a notifcation into JSON.
 :)
declare function notify-impl:notification-to-json(
  $notification as element(sm:notification))
  as object-node()
{
  object-node {
    "meta": object-node {
      "dateTime": $notification/sm:meta/sm:dateTime/fn:string(),
      "user": $notification/sm:meta/sm:user/fn:string(),
      "uri": fn:base-uri($notification),
      "status": $notification/sm:meta/sm:status/fn:string()
    },
    "thresholdLabel": $notification/sm:threshold-label/fn:string(),
    "uris": array-node {
      for $uri in $notification/sm:document-uris/sm:document-uri
      return
        object-node { "uri": $uri/fn:string() }
    },
    "extractions": xdmp:to-json(
      let $o := json:object()
      let $_ :=
        for $extractions in $notification/sm:extractions
        let $ee := json:object()
        let $_ :=
          for $extraction in $extractions/sm:extraction
          return
            map:put($ee, $extraction/@name, $extraction/fn:data(.))
        return
          map:put($o, $extractions/@uri, $ee)
      return $o
    )
  }
};

(:
 : Paged retrieval of notifications
 :)
declare function notify-impl:get-notifications-as-xml(
  $start as xs:int,
  $end as xs:int,
  $extractions as map:map)
as element(sm:notification)*
{
  for $n in (fn:collection($const:NOTIFICATION-COLL)[$start to $end])/sm:notification
  return
    notify-impl:enhance-notification-xml($n, $extractions)
};

(:
 : Paged retrieval of notifications
 :)
declare function notify-impl:get-notifications-as-json($start as xs:int, $end as xs:int, $extractions as map:map)
as array-node()
{
  array-node {
    notify-impl:get-notifications-as-xml($start, $end, $extractions) ! notify-impl:notification-to-json(.)
  }
};

(:
 : Return a count of all notifications
 :)
declare function notify-impl:count-notifications()
as xs:int
{
  xdmp:estimate(fn:collection($const:NOTIFICATION-COLL))
};

(:
 : Return a count of unread notifications
 :)
declare function notify-impl:count-unread-notifications()
as xs:int
{
  xdmp:estimate(
    cts:search(
      fn:collection($const:NOTIFICATION-COLL),
      cts:element-value-query(xs:QName("sm:status"), $const:STATUS-UNREAD))
  )
};

declare function notify-impl:update-notification-status(
  $uri as xs:string+,
  $status as xs:string
) as empty-sequence()
{
  xdmp:node-replace(
    fn:doc($uri)/sm:notification/sm:meta/sm:status,
    element sm:status { $status }
  )
};
