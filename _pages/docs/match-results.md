---
layout: inner
title: Match Results
lead_text: ''
permalink: /docs/match-results/
---

# Match Results

Calling the matching functions constructs a query based on configured 
properties and uses it to find potential matches. An application that uses
process:process-match-and-merge won't directly see the potential matches; 
rather, they will be processed automatically. Applications that call one of the
matching functions in matcher.xqy will get results that look like the response
below. 

```
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher"
  at "/com.marklogic.smart-mastering/matcher.xqy";

let $document := (: get a document :)
let $options := matcher:get-options-as-xml("my-match-options")
return
  matcher:find-document-matches-by-options(
    $document,
    $options,
    1, (: $start :)
    10, (: $page-length :)
    fn:true(), (: $include-matches :)
    cts:collection-query("Person")
  )
```

Returns:

```
  <results total="2" page-length="6" start="1">
    <boost-query>
      <cts:or-query xmlns:cts="http://marklogic.com/cts">
        <cts:element-value-query weight="50">
          <cts:element>IdentificationID</cts:element>
          <cts:text xml:lang="en">393225353</cts:text>
          <cts:option>case-insensitive</cts:option>
        </cts:element-value-query>
        <cts:element-value-query weight="8">
          <cts:element>PersonSurName</cts:element>
          <cts:text xml:lang="en">JONES</cts:text>
          <cts:option>case-insensitive</cts:option>
        </cts:element-value-query>
        <cts:element-value-query weight="12">
          <cts:element>PersonGivenName</cts:element>
          <cts:text xml:lang="en">LINDSEY</cts:text>
          <cts:option>case-insensitive</cts:option>
        </cts:element-value-query>
        <cts:element-value-query weight="5">
          <cts:element>AddressPrivateMailboxText</cts:element>
          <cts:text xml:lang="en">45</cts:text>
          <cts:option>case-insensitive</cts:option>
        </cts:element-value-query>
        <cts:element-value-query>
          <cts:element>LocationState</cts:element>
          <cts:text xml:lang="en">PA</cts:text>
          <cts:option>case-insensitive</cts:option>
        </cts:element-value-query>
        <cts:element-value-query weight="3">
          <cts:element>LocationPostalCode</cts:element>
          <cts:text xml:lang="en">18505</cts:text>
          <cts:option>case-insensitive</cts:option>
        </cts:element-value-query>
      </cts:or-query>
    </boost-query>
    <match-query>
      <cts:and-query xmlns:cts="http://marklogic.com/cts">
        <cts:collection-query>
          <cts:uri>mdm-content</cts:uri>
        </cts:collection-query>
        <cts:not-query>
          <cts:document-query>
            <cts:uri>/source/2/doc2.xml</cts:uri>
          </cts:document-query>
        </cts:not-query>
        <cts:or-query>
          <cts:element-value-query weight="0">
            <cts:element>IdentificationID</cts:element>
            <cts:text xml:lang="en">393225353</cts:text>
            <cts:option>case-insensitive</cts:option>
          </cts:element-value-query>
        </cts:or-query>
      </cts:and-query>
    </match-query>
    <result uri="/source/3/doc3.xml" index="3" score="75" threshold="Definitive Match" action="merge">
      <matches>
        <PersonSurName>JONES</PersonSurName>
        <PersonGivenName>LINDSEY</PersonGivenName>
        <LocationState>PA</LocationState>
        <AddressPrivateMailboxText>45</AddressPrivateMailboxText>
        <LocationPostalCode>18505</LocationPostalCode>
        <IdentificationID>393225353</IdentificationID>
      </matches>
    </result>
    <result uri="/source/1/doc1.xml" index="5" score="70" threshold="Likely Match" action="notify">
      <matches>
        <PersonSurName>JONES</PersonSurName>
        <PersonGivenName>LINDSEY</PersonGivenName>
        <IdentificationID>393225353</IdentificationID>
      </matches>
    </result>
  </results>
```

The matches elements can be included or skipped, based on the 
`$include-matches` parameter. 

In some cases, it may be more convenient to have the results formatted as JSON. In that case, pass the XML to the `matcher:results-to-json` function (illustrated here using [SJS][sjs], but works the same in XQuery):

```
const matcher = require("/com.marklogic.smart-mastering/matcher.xqy");

const document = // get a document
const options = matcher.getOptionsAsXml("my-match-options");

matcher:resultsToJson(
  matcher.findDocumentMatchesByOptions(
    document,
    options,
    1, // start
    10, // pageLength
    true, // includeMatches
    cts.collectionQuery("Person")
  )
)
```

The JSON result looks like this:

```
{
  "results": {
    "total": "2",
    "page-length": "6",
    "start": "1",
    "boost-query": {
      "or-query": {
        "queries": [
          {
            "element-value-query": {
              "weight": 50,
              "element": ["IdentificationID"],
              "text": [{"lang": "en", "_value": "393225353"}],
              "option": ["case-insensitive"]
            }
          },
          {
            "element-value-query": {
              "weight": 8,
              "element": ["PersonSurName"],
              "text": [{"lang": "en", "_value": "JONES"}],
              "option": ["case-insensitive"]
            }
          },
          {
            "element-value-query": {
              "weight": 12, 
              "element": ["PersonGivenName"],
              "text": [{"lang": "en", "_value": "LINDSEY"}],
              "option": ["case-insensitive"]
            }
          },
          {
            "element-value-query": {
              "weight": 5,
              "element": ["AddressPrivateMailboxText"],
              "text": [{"lang": "en", "_value": "45"}],
              "option": ["case-insensitive"]
            }
          },
          {
            "element-value-query": {
              "element": ["LocationState"],
              "text": [{"lang": "en", "_value": "PA"}],
              "option": ["case-insensitive"]
            }
          },
          {
            "element-value-query": {
              "weight": 3,
              "element": ["LocationPostalCode"],
              "text": [{"lang": "en", "_value": "18505"}],
              "option": ["case-insensitive"]
            }
          }
        ]
      }
    },
    "match-query": {
      "and-query": {
        "queries": [
          {"collection-query": {"uri": "mdm-content"}},
          {"not-query": {"document-query": {"uri": "/source/2/doc2.xml"}}},
          {
            "or-query": {
              "queries": [
                {
                  "element-value-query": {
                    "weight": 0,
                    "element": ["IdentificationID"],
                    "text": [{"lang": "en", "_value": "393225353"}],
                    "option": ["case-insensitive"]
                  }
                }
              ]
            }
          }
        ]
      }
    },
    "result": [
      {
        "uri": "/source/3/doc3.xml",
        "index": "3",
        "score": "75",
        "threshold": "Definitive Match",
        "action": "merge",
        "matches": [
          {
            "PersonSurName": "JONES",
            "PersonGivenName": "LINDSEY",
            "LocationState": "PA",
            "AddressPrivateMailboxText": "45",
            "LocationPostalCode": "18505",
            "IdentificationID": "393225353"
          }
        ]
      },
      {
        "uri": "/source/1/doc1.xml",
        "index": "5",
        "score": "70",
        "threshold": "Likely Match",
        "action": "notify",
        "matches": [
          {
            "PersonSurName": "JONES",
            "PersonGivenName": "LINDSEY",
            "IdentificationID": "393225353"
          }
        ]
      }
    ]
  }
}
```

[sjs]: http://docs.marklogic.com/guide/jsref/language#chapter
