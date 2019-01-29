# Upgrading Smart Mastering Core

This document describes steps needed when upgrading Smart Mastering Core from one version to another. 

## v1.2.0 to v1.2.3

No known incompatibilities. 

## v1.1.1 to v1.2.0

### Get Options Names as JSON

In v1.1.1, retrieving match option names as JSON from the XQuery function would return a document with a JSON array. 
The equivalent merge option names function was broken for JSON. Both functions now work and return a JSON array that is
not in a document node. 

### Deprecated Functions

The following functions are deprecated. Use the indicated replacement. 

- `matcher:get-option-names-as-xml()` => `matcher:get-option-names($const:FORMAT-XML)`
- `matcher:get-option-names-as-json()` => `matcher:get-option-names($const:FORMAT-JSON)`
- `matcher:get-options-as-xml($options-name)` => `matcher:get-options($options-name, $const:FORMAT-XML)`
- `matcher:get-options-as-json($options-name)` => `matcher:get-options($options-name, $const:FORMAT-JSON)`
- `matcher:get-notifications-as-xml($start, $end, $extractions)` => `matcher:get-notifications($start, $end, $extractions, $const:FORMAT-XML)`
- `matcher:get-notifications-as-json($start, $end, $extractions)` => `matcher:get-notifications($start, $end, $extractions, $const:FORMAT-JSON)`

## v1.1.0 to v1.1.1

No known incompatibilities. 

## v1.0.0 to v1.1.0

### Custom JavaScript actions matches parameter

Custom JavaScript actions have a `matches` parameter. In v1.0.0, it would get a JSON array that held an XML string, 
like this:

    ["<result uri=\"/source/2/doc2.xml\" index=\"1\" score=\"70\" threshold=\"Kinda Match\" action=\"custom-action\"/>"]

The `matches` parameter now gets JSON data:

    [
      {
        "uri": "/source/2/doc2.xml",
        "score": 70,
        "threshold": "Kinda Match"
      }
    ]

### Nested Property History by Clark Notation path

Merging properties can be configured at the property level or by specifying a path under `/es:envelope/es:instance`. 
The response from calling `history:property-history` generally uses property names as the keys, but in the case of 
path-specified merging, the full path using Clark Notation will be used for the key. Example:

```javascript
{
  "{http://marklogic.com/entity-services}envelope/{http://marklogic.com/entity-services}instance/TopProperty/{nested}LowerProperty1/EvenLowerProperty/LowestProperty1": {
    "another string": {
      "details": {
        "influencers": {
          "options": "/com.marklogic.smart-mastering/options/merging/nested-options.xml",
          "algorithm": "standard"
        },
        "propertyID": "http://marklogic.com/smart-mastering/auditing#/nested/doc2.xmlLowestProperty1410f7993f53b148c5b439c8e48fd5083860d648a00ff7579b0046257822c35658591bddc662ea8bda650cd729f1f3f876038240fa0422a811cc00eeff170e500",
        "sourceLocation": "/nested/doc2.xml",
        "sourceName": "sample2"
      },
      "count": 1
    }
  },
  "RegularProperty3": {
    "another string": {
      "details": {
        "influencers": {
          "options": "/com.marklogic.smart-mastering/options/merging/nested-options.xml",
          "algorithm": "standard"
        },
        "propertyID": "http://marklogic.com/smart-mastering/auditing#/nested/doc2.xmlLowestProperty3410f7993f53b148c5b439c8e48fd5083860d648a00ff7579b0046257822c35658591bddc662ea8bda650cd729f1f3f876038240fa0422a811cc00eeff170e500",
        "sourceLocation": "/nested/doc2.xml",
        "sourceName": "sample2"
      },
      "count": 1
    }
  }
```
