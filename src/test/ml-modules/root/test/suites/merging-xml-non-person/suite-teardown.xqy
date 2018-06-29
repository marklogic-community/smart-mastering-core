xquery version "1.0-ml";

import module namespace merging = "http://marklogic.com/smart-mastering/survivorship/merging"
  at "/com.marklogic.smart-mastering/survivorship/merging/base.xqy";

(: Currently, there isn't a function to delete options. :)
xdmp:directory-delete($merging:MERGING-OPTIONS-DIR)
