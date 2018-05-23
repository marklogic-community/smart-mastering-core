xquery version "1.0-ml";

import module namespace merging-impl = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/ext/com.marklogic.smart-mastering/survivorship/merging/base.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

(: Currently, there isn't a function to delete options. :)
xdmp:directory-delete($merging-impl:MERGING-OPTIONS-DIR),
xdmp:collection-delete($const:CONTENT-COLL),
xdmp:collection-delete($const:ARCHIVED-COLL)
