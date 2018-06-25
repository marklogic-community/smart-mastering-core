xquery version "1.0-ml";

module namespace merging = "http://marklogic.com/smart-mastering/merging";

import module namespace impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

(:
 : Construct a merged document, but do not save it (preview).
 :
 : @param $uris  the URIs of the documents to be merged
 : @param $merge-options  XML or JSON merge options to control how properties are combined.
 : @return the merged document
 :)
declare function merging:build-merge-models-by-uri(
  $uris as xs:string*,
  $merge-options as item()?
)
{
  impl:build-merge-models-by-uri($uris, $merge-options)
};

(:
 : Construct and store a merged document.
 :
 : @param $uris  the URIs of the documents to be merged
 : @param $merge-options  XML or JSON merge options to control how properties are combined.
 : @return the merged document
 :)
declare function merging:save-merge-models-by-uri(
  $uris as xs:string*,
  $merge-options as item()?
)
{
  impl:save-merge-models-by-uri($uris, $merge-options)
};

(:
 : Unmerge a previously merged document, removing it from the searchable data set and restoring the original documents.
 :
 : @param $merged-doc-uri  the URI of the merged document that will be removed
 :)
declare function merging:rollback-merge(
  $merged-doc-uri as xs:string
) as empty-sequence()
{
  merging:rollback-merge($merged-doc-uri, fn:true())
};

(:
 : Unmerge a previously merged document, removing it from the searchable data set and restoring the original documents.
 :
 : @param $merged-doc-uri  the URI of the merged document that will be removed
 : @param $retain-rollback-info  if fn:true(), the merged document will be archived and auditing records will be kept.
 :                               If fn:false(), the merged document and auditing records of the merge and unmerge will
 :                               be deleted.
 :)
declare function merging:rollback-merge(
  $merged-doc-uri as xs:string,
  $retain-rollback-info as xs:boolean
) as empty-sequence()
{
  impl:rollback-merge($merged-doc-uri, $retain-rollback-info)
};

(:
 : Return a list of names under which merge options have been stored.
 :
 : @return a document node containing a JSON array with the names as strings
 :)
declare function merging:get-option-names()
  as document-node()
{
  impl:get-option-names($const:FORMAT-JSON)
};

(:
 : Return a list of names under which merge options have been stored.
 :
 : @param $format  either $const:FORMAT-XML or $const:FORMAT-JSON
 : @return a document node containing a JSON array with the names as strings, or a merging:options element.
 :)
declare function merging:get-option-names($format as xs:string)
{
  impl:get-option-names($format)
};

(:
 : Return all previously save merge options.
 :
 : @param $format  either $const:FORMAT-XML or $const:FORMAT-JSON
 : @return A sequence of elements with the options or a JSON array with option objects.
 :)
declare function merging:get-options($format as xs:string)
{
  impl:get-options($format)
};

(:
 : Retrieve a named set of options in a particular format.
 :
 : @param $options-name  the name under which the options were saved
 : @param $format  either $const:FORMAT-XML or $const:FORMAT-JSON
 : @return A <merging:options element or a JSON object
 :)
declare function merging:get-options($options-name, $format as xs:string)
{
  impl:get-options($options-name, $format)
};

(:
 : Accept either XML or JSON.
 :)
declare function merging:save-options(
  $name as xs:string,
  $options as node()
)
{
  impl:save-options($name, $options)
};
