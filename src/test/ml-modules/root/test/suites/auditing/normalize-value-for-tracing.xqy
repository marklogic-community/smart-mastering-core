xquery version "1.0-ml";

import module namespace history = "http://marklogic.com/smart-mastering/auditing/history"
  at "/com.marklogic.smart-mastering/auditing/history.xqy";
import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

(: Property with a numeric value :)
test:assert-equal(
  "46",
  history:normalize-value-for-tracing(
    object-node {"Age": 46}
  )
),

(: Property with a boolean value :)
test:assert-equal(
  "true",
  history:normalize-value-for-tracing(
    object-node {"Something": fn:true() }
  )
),

(: Property that has multiple text nodes :)
test:assert-equal(
  "LINDSEY JONES",
  history:normalize-value-for-tracing(
    object-node {"PersonNameType": object-node {"PersonSurName":"JONES", "PersonGivenName":"LINDSEY"}}
  )
),

(: Property that has several text nodes :)
test:assert-equal(
  "72980 LONDONDERRY SPRINGFIELD 45505 OH",
  history:normalize-value-for-tracing(
    object-node {
      "AddressType": object-node{
        "LocationState":"OH",
        "AddressPrivateMailboxText":"72980",
        "AddressSecondaryUnitText":"LONDONDERRY",
        "LocationPostalCode":"45505",
        "LocationCityName":"SPRINGFIELD"
      }
    }
  )
),

(: Simple property :)
test:assert-equal(
  "F",
  history:normalize-value-for-tracing(
    object-node {
      "PersonSex": "F"
    }
  )
),

(: Simple element :)
test:assert-equal(
  "6270654339",
  history:normalize-value-for-tracing(
    <id xmlns="">6270654339</id>
  )
),

(: Nested element :)
test:assert-equal(
  "393225353",
  history:normalize-value-for-tracing(
    <PersonSSNIdentification xmlns="">
      <PersonSSNIdentificationType>
        <IdentificationID>393225353</IdentificationID>
      </PersonSSNIdentificationType>
    </PersonSSNIdentification>
  )
),

(: should not return empty for text nodes :)
test:assert-equal(
  "textValue",
  history:normalize-value-for-tracing(
    text{'textValue'}
  )
)
