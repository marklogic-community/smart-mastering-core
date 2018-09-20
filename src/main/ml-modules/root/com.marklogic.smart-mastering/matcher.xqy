xquery version "1.0-ml";

(:~
 : API to find matches for a particular document. Matching is driven by a
 : match configuration. The matching process works by using the properties in a
 : document to create a query, which is then used to find other documents that
 : are potential matches. The match options include weights for the properties,
 : which become weights in the query used to find matches.
 :
 : Match functions are expected to be run against either XML documents or JSON
 : documents, not a mix. Use the $filter-query parameter to scope matching.
 :
 : This module has the following groups of functions:
 : - matching: find matches for a document
 : - options: manage match options
 : - blocks: manage match blocks between documents
 : - notifications: manage notifications
 :
 : Match options return match results as shown below.
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :
 : Match option configuration is documented here.
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/matching-options/
 :)
module namespace matcher = "http://marklogic.com/smart-mastering/matcher";

import module namespace blocks-impl = "http://marklogic.com/smart-mastering/blocks-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/blocks-impl.xqy";
import module namespace match-impl = "http://marklogic.com/smart-mastering/matcher-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/matcher-impl.xqy";
import module namespace notify-impl = "http://marklogic.com/smart-mastering/notification-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/notification-impl.xqy";
import module namespace opt-impl = "http://marklogic.com/smart-mastering/options-impl"
  at "/com.marklogic.smart-mastering/matcher-impl/options-impl.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

(: For example match options, see https://marklogic-community.github.io/smart-mastering-core/docs/matching-options/ :)

(:~
 : Starting with the specified document, look for potential matches based on the matching options saved under the
 : provided name.
 :
 : @param $document  document to find matches for
 : @param $options-name  name previously associated with match options using matcher:save-options
 : @return  the queries used for search and the search results themselves
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :)
declare function matcher:find-document-matches-by-options-name(
  $document,
  $options-name as xs:string
)
as element(results)
{
  matcher:find-document-matches-by-options(
    $document,
    matcher:get-options-as-xml($options-name),
    fn:false(),
    cts:true-query()
  )
};


(:
 : Starting with the specified document, look for potential matches based on the matching options saved under the
 : provided name.
 :
 : @param $document  document to find matches for
 : @param $options-name  name previously associated with match options using matcher:save-options
 : @param $include-matches  whether the response should list the matched properties for each potential match
 : @param $filter-query  a cts:query used to restrict matches to a set, such as a specific entity type or collection
 : @return  the queries used for search and the search results themselves
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :)
declare function matcher:find-document-matches-by-options-name(
  $document,
  $options-name as xs:string,
  $include-matches as xs:boolean,
  $filter-query as cts:query
)
  as element(results)
{
  matcher:find-document-matches-by-options($document, matcher:get-options-as-xml($options-name), $include-matches, $filter-query)
};

(:
 : Starting with the specified document, look for potential matches based on previously-saved matching options
 :
 : @param $document  document to find matches for
 : @param $options  match options saved using matcher:save-options
 : @param $include-matches  whether the response should list the matched properties for each potential match
 : @param $filter-query  a cts:query used to restrict matches to a set, such as a specific entity type or collection
 : @return the queries used for search and the search results themselves
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :)
declare function matcher:find-document-matches-by-options(
  $document,
  $options as item(), (: as (element(matcher:options)|object-node()) :)
  $include-matches as xs:boolean,
  $filter-query as cts:query
)
  as element(results)
{
  matcher:find-document-matches-by-options(
    $document,
    $options,
    1,
    fn:head((
      $options//*:max-scan ! xs:integer(.),
      200
    )),
    $include-matches,
    $filter-query
  )
};

(:
 : Starting with the specified document, look for a page of potential matches based on previously-saved matching options
 :
 : @param $document  document to find matches for
 : @param $options  match options saved using matcher:save-options
 : @param $start  starting index for potential match results (starts at 1)
 : @param $page-length  maximum number of results to return in this call
 : @param $include-matches  whether the response should list the matched properties for each potential match
 : @param $filter-query  a cts:query used to restrict matches to a set, such as a specific entity type or collection
 : @return the queries used for search and the search results themselves
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :)
declare function matcher:find-document-matches-by-options(
  $document,
  $options as item(), (: as (element(matcher:options)|object-node()) :)
  $start as xs:int,
  $page-length as xs:int,
  $include-matches as xs:boolean,
  $filter-query as cts:query
) as element(results)
{
  match-impl:find-document-matches-by-options(
    $document,
    $options,
    $start,
    $page-length,
    fn:min($options//*:thresholds/*:threshold/(@above|above) ! fn:number(.)),
    fn:false(),
    $include-matches,
    $filter-query
  )
};

(:
 : Starting with the specified document, look for a page of potential matches based on previously-saved matching options.
 :
 : @param $document  document to find matches for
 : @param $options  match options saved using matcher:save-options
 : @param $start  starting index for potential match results (starts at 1)
 : @param $page-length  maximum number of results to return in this call
 : @param $minimum-threshold  value of the lowest threshold score; the match query will require matches to score at
                              least this high to be returned
 : @param $lock-on-search  TODO
 : @param $include-matches  whether the response should list the matched properties for each potential match
 : @param $filter-query  a cts:query used to restrict matches to a set, such as a specific entity type or collection
 : @return the queries used for search and the search results themselves
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :)
declare function matcher:find-document-matches-by-options(
  $document,
  $options as item(), (: as (element(matcher:options)|object-node()) :)
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold as xs:double,
  $lock-on-search as xs:boolean,
  $include-matches as xs:boolean,
  $filter-query
) as element(results)
{
  match-impl:find-document-matches-by-options(
    $document, $options, $start, $page-length, $minimum-threshold, $lock-on-search, $include-matches, $filter-query
  )
};

(:
 : Convert match results from XML to JSON.
 : @param $results-xml  XML match results as returned from the
 :                      find-document-matches-* functions
 : @return a JSON representation of the match results
 : @see https://marklogic-community.github.io/smart-mastering-core/docs/match-results/
 :)
declare function matcher:results-to-json($results-xml)
  as object-node()?
{
  match-impl:results-to-json($results-xml)
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Functions related to match options
 :~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:
 : Retrieve names of all previously saved matcher options.
 :
 : @return  <matcher:options> element containing zero or more <matcher:option> elements
 :)
declare function matcher:get-option-names-as-xml()
  as element(matcher:options)
{
  opt-impl:get-option-names-as-xml()
};

(:
 : Retrieve names of all previously saved matcher options.
 :
 : @return  JSON array of strings
 :)
declare function matcher:get-option-names-as-json()
  as object-node()?
{
  opt-impl:get-option-names-as-json()
};

declare function matcher:get-options-as-xml($options-name as xs:string)
  as element(matcher:options)?
{
  opt-impl:get-options-as-xml($options-name)
};

declare function matcher:get-options-as-json($options-name as xs:string)
  as object-node()?
{
  opt-impl:get-options-as-json($options-name)
};

declare function matcher:save-options(
  $name as xs:string,
  $options as node()
) as empty-sequence()
{
  opt-impl:save-options($name, $options)
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Functions related to blocks. When looking for matches for a document
 : (docA), if there is a block between docA and another document (docB), the
 : matcher will not return docB as a match regardless of the score.
 :~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:
 : Return a JSON array of any URIs the that input URI is blocked from matching.
 : @param $uri  input URI
 : @return JSON array of URIs
 :)
declare function matcher:get-blocks($uri as xs:string?)
  as array-node()
{
  blocks-impl:get-blocks($uri)
};

(:
 : Block all pairs of URIs from matching.
 : If we have 4 URIs, then block (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4).
 :
 : @param uris the sequence of URIs
 : @return empty sequence
 :)
declare function matcher:block-matches($uris as xs:string*)
  as empty-sequence()
{
  blocks-impl:block-matches($uris)
};

(:
 : Remove a match block between the two input URIs.
 :
 : @param $uri1  First input URI
 : @param $uri2  Second input URI
 :
 : @error will throw xs:QName("SM-CANT-UNBLOCK") if a block is present, but it cannot be cleared
 : @return  fn:true if a block was found and cleared; fn:false if no block was found
 :)
declare function matcher:allow-match($uri1 as xs:string, $uri2 as xs:string)
{
  blocks-impl:allow-match($uri1, $uri2)
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Functions related to notifications. The notify action, configurable in
 : match options, records a document indicating that the original document
 : and one or more others have matched highly enough that they might
 : represent the same entity, but not highly enough to automatically merge.
 : The API allows applications to retrieve, count, update, create, and
 : delete notifications.
 :~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:
 : Paged retrieval of notifications.
 : @param $start  1-based index of the start position of notifications
 : @param $end  1-based index of the end position of notifications (inclusive)
 : @param $extractions  TODO
 : @param $format  either $const:FORMAT-JSON or $const:FORMAT-XML
 : @return either element(sm:notification)* or object-node()*
 :)
declare function matcher:get-notifications(
  $start as xs:int,
  $end as xs:int,
  $extractions as map:map,
  $format as xs:string
) as item()*
{
  if ($format eq $const:FORMAT-JSON) then
    notify-impl:get-notifications-as-json($start, $end, $extractions)
  else
    notify-impl:get-notifications-as-xml($start, $end, $extractions)
};

(:
 : Paged retrieval of notifications
 : @deprecated Use matcher:get-notifications instead
 :)
declare function matcher:get-notifications-as-xml($start as xs:int, $end as xs:int, $extractions as map:map)
  as element(sm:notification)*
{
  notify-impl:get-notifications-as-xml($start, $end, $extractions)
};

(:
 : Paged retrieval of notifications
 : @deprecated Use matcher:get-notifications instead
 :)
declare function matcher:get-notifications-as-json($start as xs:int, $end as xs:int, $extractions as map:map)
  as array-node()
{
  notify-impl:get-notifications-as-json($start, $end, $extractions)
};

(:
 : Return a count of all notifications
 :)
declare function matcher:count-notifications()
  as xs:int
{
  notify-impl:count-notifications()
};

(:
 : Return a count of unread notifications
 :)
declare function matcher:count-unread-notifications()
  as xs:int
{
  notify-impl:count-unread-notifications()
};

(:
 : Change the status of this notification to the new status. Default status
 : is $const:STATUS-UNREAD.
 : @param $uri  the URI(s) of the notification(s) to be updated
 : @param $status  the new status for the notification(s)
 :)
declare function matcher:update-notification-status(
  $uri as xs:string+,
  $status as xs:string
) as empty-sequence()
{
  notify-impl:update-notification-status($uri, $status)
};

(:
 : Create a new notification. If a notification document already exists for
 : this label/URIs combination, it will be replaced with the new notification.
 : @param $threshold-label  human-readable label used to indicate the
 :                          likelihood of the match
 : @param $uris  URIs of the content documents that are merge candidates
 : @return content of the newly-constructed notification
 :)
declare function matcher:save-match-notification(
  $threshold-label as xs:string,
  $uris as xs:string*
) as element(sm:notification)
{
  notify-impl:save-match-notification($threshold-label, $uris)
};

(:
 : Delete the specified notification.
 : @param $uri  URI of the notification document to be deleted
 :
 :)
declare function matcher:delete-notification($uri as xs:string)
  as empty-sequence()
{
  notify-impl:delete-notification($uri)
};

