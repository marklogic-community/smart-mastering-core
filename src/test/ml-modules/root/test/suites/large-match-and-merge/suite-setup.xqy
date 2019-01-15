xquery version "1.0-ml";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";
import module namespace merging = "http://marklogic.com/smart-mastering/merging"
  at "/com.marklogic.smart-mastering/merging.xqy";
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace lib = "http://marklogic.com/smart-mastering/test" at "lib/lib.xqy";

declare option xdmp:mapping "false";

merging:save-options($lib:OPTIONS-NAME, test:get-test-file("merge-options.json")),
matcher:save-options($lib:MATCH-OPTIONS-NAME, test:get-test-file("match-options.json")),

test:load-test-file("collector.xqy", xdmp:modules-database(), "/collector.xqy"),

let $insert-options := <options xmlns="xdmp:document-insert">
      <permissions>{xdmp:default-permissions()}</permissions>
      <collections>
        <collection>{$const:CONTENT-COLL}</collection>
      </collections>
    </options>
let $people-csv := test:get-test-file("people.csv")
let $current-time := fn:current-dateTime()
let $people-lines := fn:tokenize($people-csv,"[&#10;&#13;]+")
let $end-of-notifications := $lib:NUMBER-OF-NOTIFICATIONS
for $person at $pos in fn:tail($people-lines)
let $cols := fn:tokenize($person, ",")
let $doc := object-node {
  "envelope": object-node {
    "headers": object-node {
      "sources": array-node {
        object-node {
          "name": "A"
        }
      },
      "ingestDateTime": $current-time + xdmp:elapsed-time()
    },
    "instance": object-node {
      "person": object-node {
        "id": fn:number($cols[1]),
        "firstName": $cols[2],
        "lastName": $cols[3],
        "email": $cols[4],
        "gender": $cols[5]
      }
    }
  }
}
let $person := $doc/envelope/instance/person
let $additional-docs := (if ($pos le $lib:NUMBER-OF-MERGES) then (
    for $i in (1 to $lib:MERGES-PER)
    return
      object-node {
        "envelope": object-node {
          "headers": object-node {
            "sources": array-node {
              object-node {
                "name": "A-merge-"||$i
              }
            },
            "ingestDateTime": $current-time + xdmp:elapsed-time()
          },
          "instance": object-node {
            "person": object-node {
              "id": $person/id * ($i * 10),
              "firstName": $person/firstName,
              "lastName": $person/lastName,
              "email": $person/email,
              "gender": $person/gender
            }
          }
        }
      }
  ) else (), if ($pos le $end-of-notifications) then (
    for $i in (1 to $lib:NOTIFICATIONS-PER)
    return
      object-node {
        "envelope": object-node {
          "headers": object-node {
            "sources": array-node {
              object-node {
                "name": "A-notify-"||$i
              }
            },
            "ingestDateTime": $current-time + xdmp:elapsed-time()
          },
          "instance": object-node {
            "person": object-node {
              "id": $person/id * ($i * 10),
              "firstName": "otherName-" || $i,
              "lastName": $person/lastName,
              "email": $person/email,
              "gender": $person/gender
            }
          }
        }
      }
  ) else ())
return (
    xdmp:document-insert('/person-' || $pos || '.json',
      $doc,
      $insert-options
    ),
    for $additional-doc at $add-pos in $additional-docs
    return
      xdmp:document-insert('/person-' || $pos || "-" || $add-pos || '.json',
        $additional-doc,
        $insert-options
      )
  )
