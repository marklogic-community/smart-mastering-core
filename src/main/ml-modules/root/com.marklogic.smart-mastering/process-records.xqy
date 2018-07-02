xquery version '1.0-ml';

module namespace process = "http://marklogic.com/smart-mastering/process-records";

import module namespace proc-impl = "http://marklogic.com/smart-mastering/process-records/impl"
  at "impl/process.xqy";

declare option xdmp:mapping "false";

(:
 : Identify matches for a target document using all available merge options.
 : Merge any documents where the match score is above the merge threshold;
 : record notification for matches above that threshold.
 :
 : @param $uri  URI of the target document
 : @return merged docs, if any, otherwise any notification documents
 :)
declare function process:process-match-and-merge($uri as xs:string)
{
  proc-impl:process-match-and-merge($uri)
};

(:
 : Identify matches for a target document. Merge any documents where the match
 : score is above the merge threshold; record notification for matches above
 : that threshold.
 :
 : @param $uri  URI of the target document
 : @param $option-name  the name of a set of merge options, which include a reference to a set of match options
 : @return merged docs, if any, otherwise any notification documents
 :)
declare function process:process-match-and-merge($uri as xs:string, $option-name as xs:string)
{
  proc-impl:process-match-and-merge($uri, $option-name, cts:and-query(()))
};

(:
 : Identify matches for a target document. Merge any documents where the match
 : score is above the merge threshold; record notification for matches above
 : that threshold.
 :
 : @param $uri  URI of the target document
 : @param $option-name  the name of a set of merge options, which include a reference to a set of match options
 : @param $filter-query  a cts:query used to filter the matched results
 : @return merged docs, if any, otherwise any notification documents
 :)
declare function process:process-match-and-merge(
  $uri as xs:string,
  $option-name as xs:string,
  $filter-query as cts:query)
{
  proc-impl:process-match-and-merge($uri, $option-name, $filter-query)
};
