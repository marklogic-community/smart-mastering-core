xquery version "1.0-ml";

module namespace matcher = "http://marklogic.com/smart-mastering/matcher";

import module namespace blocks-impl = "http://marklogic.com/smart-mastering/blocks-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/blocks-impl.xqy";
import module namespace match-impl = "http://marklogic.com/smart-mastering/matcher-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/matcher-impl.xqy";
import module namespace notify-impl = "http://marklogic.com/smart-mastering/notification-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/notification-impl.xqy";
import module namespace opt-impl = "http://marklogic.com/smart-mastering/options-impl"
  at "/ext/com.marklogic.smart-mastering/matcher-impl/options-impl.xqy";

declare namespace sm = "http://marklogic.com/smart-mastering";

declare option xdmp:mapping "false";

(: For example match options, see https://marklogic-community.github.io/smart-mastering-core/docs/matching-options/ :)

(:
 : Starting with the specified document, look for potential matches based on the matching options saved under the
 : provided name.
 :
 : @param $document  document to find matches for
 : @param $options-name  name previously associated with match options using matcher:save-options
 : @return  the queries used for search and the search results themselves
 :)
declare function matcher:find-document-matches-by-options-name(
  $document,
  $options-name as xs:string
)
as element(results)
{
  matcher:find-document-matches-by-options($document, matcher:get-options-as-xml($options-name), fn:false())
};


(:
 : Starting with the specified document, look for potential matches based on the matching options saved under the
 : provided name.
 :
 : @param $document  document to find matches for
 : @param $options-name  name previously associated with match options using matcher:save-options
 : @param $include-matches  whether the response should list the matched properties for each potential match
 : @return  the queries used for search and the search results themselves
 :)
declare function matcher:find-document-matches-by-options-name(
  $document,
  $options-name as xs:string,
  $include-matches as xs:boolean
)
  as element(results)
{
  matcher:find-document-matches-by-options($document, matcher:get-options-as-xml($options-name), $include-matches)
};

(:
 : Starting with the specified document, look for potential matches based on previously-saved matching options
 :
 : @param $document  document to find matches for
 : @param $options  match options saved using matcher:save-options
 : @param $include-matches  whether the response should list the matched properties for each potential match
 : @return the queries used for search and the search results themselves
 :)
declare function matcher:find-document-matches-by-options(
  $document,
  $options as element(matcher:options),
  $include-matches as xs:boolean
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
    $include-matches
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
 : @return the queries used for search and the search results themselves
 :)
declare function matcher:find-document-matches-by-options(
  $document,
  $options as element(matcher:options),
  $start as xs:int,
  $page-length as xs:int,
  $include-matches as xs:boolean
) as element(results)
{
  match-impl:find-document-matches-by-options(
    $document,
    $options,
    $start,
    $page-length,
    fn:min($options//*:thresholds/*:threshold/(@above|above) ! fn:number(.)),
    fn:false(),
    $include-matches
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
 : @return the queries used for search and the search results themselves
 :)
declare function matcher:find-document-matches-by-options(
  $document,
  $options as element(matcher:options),
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold as xs:double,
  $lock-on-search as xs:boolean,
  $include-matches as xs:boolean
) as element(results)
{
  match-impl:find-document-matches-by-options(
    $document, $options, $start, $page-length, $minimum-threshold, $lock-on-search, $include-matches
  )
};

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

declare function matcher:results-to-json($results-xml)
  as object-node()?
{
  match-impl:results-to-json($results-xml)
};


(:
 : Return a JSON array of any URIs the that input URI is blocked from matching.
 : @param $uri  input URI
 : @return JSON array of URIs
 :)
declare function matcher:get-blocks($uri as xs:string)
  as array-node()
{
  blocks-impl:get-blocks($uri)
};

(:
 : Block all pairs of URIs from matching.
 : If we have 4 URIs, then we need to block (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4). This function will
 : start with URI #1 and call matcher:block-match with it each of the remaining URIs. It then recurses on the
 : tail, repeating the process of blocking URI #2 from matching with the remaining URIs (3, 4). This stops when
 : there are zero or one URIs remaining.
 : No return type specified to allow tail call optimization.
 :
 : @param uris the sequence of URIs
 : @return empty sequence
 :)
declare function matcher:block-matches($uris as xs:string*)
{
  blocks-impl:block-matches($uris)
};

(:
 : Clear a match block between the two input URIs.
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

(:
 : Paged retrieval of notifications
 :)
declare function matcher:get-notifications-as-xml($start as xs:int, $end as xs:int)
  as element(sm:notification)*
{
  notify-impl:get-notifications-as-xml($start, $end)
};

(:
 : Paged retrieval of notifications
 :)
declare function matcher:get-notifications-as-json($start as xs:int, $end as xs:int)
  as array-node()
{
  notify-impl:get-notifications-as-json($start, $end)
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

declare function matcher:update-notification-status(
  $uri as xs:string+,
  $status as xs:string
)
{
  notify-impl:update-notification-status($uri, $status)
};

declare function matcher:save-match-notification(
  $threshold-label as xs:string,
  $uris as xs:string*
)
{
  notify-impl:save-match-notification($threshold-label, $uris)
};

(:
 : Delete the specified notification
 :)
declare function matcher:delete-notification($uri as xs:string)
{
  notify-impl:delete-notification($uri)
};

