xquery version "1.0-ml";

module namespace constants = "http://marklogic.com/agile-mastering/constants";

(: Collections :)
declare variable $ALGORITHM-COLL := "mdm-algorithm";
declare variable $ARCHIVED-COLL := "mdm-archived";
declare variable $AUDITING-COLL := "mdm-auditing";
declare variable $CONTENT-COLL := "mdm-content";
declare variable $DICTIONARY-COLL := "mdm-dictionary";
declare variable $MATCH-OPTIONS-COLL := "mdm-match-options";
declare variable $MERGE-COLL := "mdm-merge";
declare variable $MERGED-COLL := "mdm-merged";
declare variable $MODEL-MAPPER-COLL := "mdm-model-mapper";
declare variable $NOTIFICATION-COLL := "mdm-notification";
declare variable $OPTIONS-COLL := "mdm-options";

(: Roles :)
declare variable $MDM-USER := "mdm-user";
declare variable $MDM-ADMIN := "mdm-admin";

(: Actions :)
declare variable $MERGE-ACTION := "merge";
declare variable $NOTIFY-ACTION := "notify";
