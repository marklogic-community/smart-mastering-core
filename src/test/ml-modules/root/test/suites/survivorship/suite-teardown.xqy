xquery version "1.0-ml";

import module namespace merging = "http://marklogic.com/agile-mastering/survivorship/merging"
  at "/ext/com.marklogic.agile-mastering/survivorship/merging/base.xqy";

xdmp:directory-delete($merging:MERGING-OPTIONS-DIR)
