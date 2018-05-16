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

(:

Example matcher options:

<options xmlns="http://marklogic.com/smart-mastering/matcher">
  <property-defs>
    <property namespace="" localname="IdentificationID" name="ssn"/>
    <property namespace="" localname="PersonGivenName" name="first-name"/>
    <property namespace="" localname="PersonSurName" name="last-name"/>
    <property namespace="" localname="AddressPrivateMailboxText" name="addr1"/>
    <property namespace="" localname="LocationCity" name="city"/>
    <property namespace="" localname="LocationState" name="state"/>
    <property namespace="" localname="LocationPostalCode" name="zip"/>
  </property-defs>
  <algorithms>
    <algorithm name="std-reduce" function="standard-reduction"/>
    <algorithm name="std-reduce-query" function="standard-reduction-query"/>
    <algorithm name="dbl-metaphone" function="double-metaphone"/>
  </algorithms>
  <scoring>
    <add property-name="ssn" weight="50"/>
    <add property-name="last-name" weight="8"/>
    <add property-name="first-name" weight="12"/>
    <add property-name="addr1" weight="5"/>
    <add property-name="city" weight="3"/>
    <add property-name="state" weight="1"/>
    <add property-name="zip" weight="3"/>
    <expand property-name="first-name" algorithm-ref="dbl-metaphone" weight="6">
      <dictionary>name-dictionary.xml</dictionary>
      <distance-threshold>10</distance-threshold>
    </expand>
    <expand property-name="last-name" algorithm-ref="dbl-metaphone" weight="8">
      <dictionary>name-dictionary.xml</dictionary>
      <!--defaults to 100 distance -->
    </expand>
    <reduce algorithm-ref="std-reduce" weight="4">
      <all-match>
        <property>last-name</property>
        <property>addr1</property>
      </all-match>
    </reduce>
  </scoring>
  <thresholds>
    <threshold above="30" label="Possible Match"/>
    <threshold above="50" label="Likely Match"/>
    <threshold above="75" label="Definitive Match"/>
    <!-- below 25 will be NOT-A-MATCH or no category -->
  </thresholds>
  <tuning>
    <max-scan>200</max-scan>  <!-- never look at more than 200 -->
    <initial-scan>20</initial-scan>
  </tuning>
</options>
:)

declare function matcher:find-document-matches-by-options-name($document, $options-name)
  as element(results)
{
  matcher:find-document-matches-by-options($document, matcher:get-options-as-xml($options-name))
};

declare function matcher:find-document-matches-by-options($document, $options)
  as element(results)
{
  matcher:find-document-matches-by-options(
    $document,
    $options,
    1,
    fn:head((
      $options//*:max-scan ! xs:integer(.),
      200
    ))
  )
};


declare function matcher:find-document-matches-by-options(
  $document,
  $options,
  $start,
  $page-length
) as element(results)
{
  match-impl:find-document-matches-by-options(
    $document,
    $options,
    $start,
    $page-length,
    fn:min($options//*:thresholds/*:threshold/(@above|above) ! fn:number(.)),
    fn:false()
  )
};

declare function matcher:find-document-matches-by-options(
  $document,
  $options,
  $start as xs:integer,
  $page-length as xs:integer,
  $minimum-threshold,
  $lock-on-search
) as element(results)
{
  match-impl:find-document-matches-by-options($document, $options, $start, $page-length, $minimum-threshold, $lock-on-search)
};

declare function matcher:get-option-names-as-xml()
  as element(matcher:options)
{
  opt-impl:get-option-names-as-xml()
};

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

