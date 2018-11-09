---
layout: inner
title: Merging Options
permalink: /docs/merging-options/
---

# Merging Options

Smart Mastering Core offers a configuration-driven merge capability. Merging
takes two or more documents in the `mdm-content` collection (which holds the
data that is available for search), moves them to an `mdm-archive` collection,
and creates a new document combining the original two. The new combined document
will be in the `mdm-content` collection. Merge configuration includes the
properties to merge and how to combine them.

# Configuring Options

Here's an example of merge configuration options. Options may be uploaded and 
retrieved as either XML or JSON. 

```xml
<options xmlns="http://marklogic.com/smart-mastering/merging">
  <match-options>mlw-match</match-options>
  <m:property-defs
    xmlns:es="http://marklogic.com/entity-services"
    xmlns:m="http://marklogic.com/smart-mastering/merging"
    xmlns:has="has"
    xmlns="">
    <m:property namespace="" localname="IdentificationID" name="ssn"/>
    <m:property namespace="" localname="PersonName" name="name"/>
    <m:property namespace="" localname="Address" name="address"/>
    <m:property namespace="" localname="PersonBirthDate" name="dob"/>
    <m:property namespace="" localname="CaseStartDate" name="caseStartDate"/>
    <m:property namespace="" localname="IncidentCategoryCodeDate" name="incidentDate"/>
    <m:property namespace="" localname="PersonSex" name="sex"/>
    <m:property path="/es:envelope/es:headers/shallow" name="shallow"/>
    <m:property path="/es:envelope/es:headers/custom/this/has:a/deep/path" name="deep"/>
    <m:property path="/es:envelope/es:instance/Another/Deep/path" name="nested"/>
  </m:property-defs>
  <algorithms>
    <!-- config for standard algorithm -->
    <!-- any needed namespaces get defined on the std-algorithm element -->
    <std-algorithm xmlns:es="http://marklogic.com/entity-services" xmlns:sm="http://marklogic.com/smart-mastering">
      <!-- provide the path to the timestamp element to use for sorting -->
      <!-- when merging the values are sorted in recency order from newest
           to oldest based on this timestamp. If the timestamp is not
           provided then there is no recency sort -->
      <timestamp path="/es:envelope/es:headers/sm:sources/sm:source/sm:dateTime" />
    </std-algorithm>
    <!-- Optionally override how collections are applied to documents during different events -->
    <collections>
      <!-- Reference an XQuery function that takes 3 parameters
        1. event name string
        2. map:map of collections stored by document URI
        3. options element for event (e.g., on-merge element)
       -->
      <on-merge
        function="collections"
        namespace="test/merge-collection-algorithm"
        at="/test/suites/customizing-collections/lib/merged-collections.xqy"
        />
      <!-- 
        Make adjustments to the standard set of collections with add and remove collection elements.
       -->
      <on-archive>
        <remove>
          <collection>Entity</collection>
        </remove>
        <add>
          <collection>custom-archived</collection>
        </add>
      </on-archive>
      <!-- Reference a JavaScript function that takes 3 parameters
        1. event name string
        2. JSON Object of collections stored by document URI
        3. JSON representation of options element for event (e.g., Object with onMerge property)
       -->
      <on-no-match
        function="noMatchCollections"
        at="/test/suites/customizing-collections/lib/noMatchCollections.sjs"
        />
      <!-- 
        Define the full of collections that should be set on a document with set collection elements.
       -->
      <on-notification>
        <set>
          <collection>notification</collection>
        </set>
      </on-notification>
    </collections>
  </algorithms>
  <!-- Optionally override the standard collection names -->
  <collections>
    <merged>mdm-merged</merged>
    <notification>mdm-notification</notification>
    <archived>mdm-archived</archived>
    <auditing>mdm-auditing</auditing>
  </collections>
  <merging>
    <!-- Define merging strategies that can be referenced by
      merge specifications below. This can cut down on configuration for repeated patterns   -->
    <merge-strategy name="crm-source-weight" algorithm-ref="standard">
      <source-weights>
        <source name="CRM" weight="10"></source>
      </source-weights>
    </merge-strategy>
    <merge-strategy name="length-weight" algorithm-ref="standard" max-values="1">
      <length weight="10"/>
    </merge-strategy>
    <merge property-name="ssn" strategy="crm-source-weight"></merge>
    <!-- A strategy reference is not required. -->
    <merge property-name="name" max-values="1">
      <double-metaphone>
        <distance-threshold>50</distance-threshold>
      </double-metaphone>
      <synonyms-support>true</synonyms-support>
      <thesaurus>/mdm/config/thesauri/first-name-synonyms.xml</thesaurus>
      <length weight="8" />
    </merge>
    <merge property-name="address" strategy="crm-source-weight" max-values="1"></merge>
    <merge property-name="dob" max-values="1" algorithm-ref="standard">
      <source-weights>
        <source name="Oracle" weight="10"></source>
      </source-weights>
    </merge>
    <merge property-name="caseStartDate" strategy="crm-source-weight" max-values="1"></merge>
    <merge property-name="incidentDate" strategy="length-weight"></merge>
    <merge property-name="sex" strategy="length-weight"></merge>
    <!-- Define a default merge specification to apply to
    properties that haven't been assigned a merge
    specification. -->
    <merge default="true" strategy="crm-source-weight"></merge>
  </merging>
  
  <!-- 
    Define a custom xqy triple merge function
    Note that this approach differs from how you define
    property merge algorithms. This is due to the fact that
    there is only 1 triple merge function vs many algorithms
    that may need to be reusable.
   -->
  <triple-merge
    function="custom-trips"
    namespace="http://marklogic.com/smart-mastering/merging"
    at="/custom-triple-merge.xqy">

    <!--
      you can provide additional elements that are available to
      your function. Use these to pass in extra parameters to your function.
    -->
    <some-param>3</some-param>
  </triple-merge>
</options>
```

```json
{
  "options":
  {
    "matchOptions": "mlw-match",
    "propertyDefs":
    {
      "properties": [
      {
        "namespace": "",
        "localname": "IdentificationID",
        "name": "ssn"
      },
      {
        "namespace": "",
        "localname": "PersonName",
        "name": "name"
      },
      {
        "namespace": "",
        "localname": "Address",
        "name": "address"
      },
      {
        "namespace": "",
        "localname": "PersonBirthDate",
        "name": "dob"
      },
      {
        "namespace": "",
        "localname": "CaseStartDate",
        "name": "caseStartDate"
      },
      {
        "namespace": "",
        "localname": "IncidentCategoryCodeDate",
        "name": "incidentDate"
      },
      {
        "namespace": "",
        "localname": "PersonSex",
        "name": "sex"
      },
      {
        "path": "/es:envelope/es:headers/shallow",
        "name": "shallow"
      },
      {
        "path": "/es:envelope/es:headers/custom/this/has:a/deep/path",
        "name": "deep"
      },
      {
        "path": "/es:envelope/es:instance/Another/Deep/path",
        "name": "nested"
      }],
      "namespaces":
      {
        "has": "has",
        "m": "http://marklogic.com/smart-mastering/merging",
        "es": "http://marklogic.com/entity-services"
      }
    },
    "algorithms":
    {
      "stdAlgorithm":
      {
        "namespaces":
        {
          "sm": "http://marklogic.com/smart-mastering",
          "es": "http://marklogic.com/entity-services"
        },
        "timestamp":
        {
          "path": "/es:envelope/es:headers/sm:sources/sm:source/sm:dateTime"
        }
      },
      "custom": [],
      "collections": {
        "onMerge": {
          "function": "collections",
          "namespace": "test/merge-collection-algorithm",
          "at": "/test/suites/customizing-collections/lib/merged-collections.xqy"
        },
        "onArchive": {
          "remove": {
            "collection": ["Entity"]
          },
          "add": {
            "collection": ["custom-archived"]
          }
        },
        "onNoMatch": {
          "function": "noMatchCollections",
          "at": "/test/suites/customizing-collections/lib/noMatchCollections.sjs"
        },
        "onNotification": {
          "set": {
            "collection": ["notification"]
          }
        }
      }
    },
    "mergeStrategies": [
    {
      "name": "crm-source-weight",
      "algorithmRef": "standard",
      "sourceWeights":
      {
        "source":
        {
          "name": "CRM",
          "weight": "10"
        }
      }
    },
    {
      "name": "length-weight",
      "algorithmRef": "standard",
      "maxValues": "1",
      "length":
      {
        "weight": "10"
      }
    }],
    "merging": [
    {
      "propertyName": "ssn",
      "strategy": "crm-source-weight"
    },
    {
      "propertyName": "name",
      "maxValues": "1",
      "doubleMetaphone":
      {
        "distanceThreshold": "50"
      },
      "synonymsSupport": "true",
      "thesaurus": "/mdm/config/thesauri/first-name-synonyms.xml",
      "length":
      {
        "weight": "8"
      }
    },
    {
      "propertyName": "address",
      "strategy": "crm-source-weight",
      "maxValues": "1"
    },
    {
      "propertyName": "dob",
      "algorithmRef": "standard",
      "sourceWeights":
      {
        "source":
        {
          "name": "Oracle",
          "weight": "10"
        }
      },
      "maxValues": "1"
    },
    {
      "propertyName": "caseStartDate",
      "strategy": "crm-source-weight",
      "maxValues": "1"
    },
    {
      "propertyName": "incidentDate",
      "strategy": "length-weight"
    },
    {
      "propertyName": "sex",
      "strategy": "length-weight"
    },
    {
      "default": "true",
      "strategy": "crm-source-weight"
    }],
    "tripleMerge":
    {
      "function": "custom-trips",
      "namespace": "http://marklogic.com/smart-mastering/merging",
      "at": "/custom-triple-merge.xqy",
      "someParam": "3"
    }
  }
}
```

### Match Options

When calling `process:process-match-and-merge()`, match options are specified
by the merge options used in the call. The value of the `match-options` element
is the name under which a set of match options were previously stored.

Calling the `sm:merge` service or `merging:save-merge-models-by-uri` does not
require that the merge options be paired with a set of match options; the
`match-options` element may be left out. This will not affect the merging
process at all.

### Property Definitions

#### Instance Properties

When merging documents, all properties defined for an entity will be merged. The
`property-defs/property` elements specify the properties where the process of
merging values will be configured. The `namespace` and `localname` attributes
specify an XML element or JSON property. The `name` attribute provides a
nickname used to refer to this property in the rest of the configuration. The
`name` attribute values must be unique within this configuration.

#### Path Properties

In addition to properties defined for an entity, properties may also be specified by path. Paths leading into the 
headers or instance sections of documents are currently supported; that is:

- /es:envelope/es:headers (XML)
- /envelope/headers (JSON)
- /es:envelope/es:instance (XML)
- /envelope/instance (JSON)

Control of the merging process using algorithms works the same for path properties as it does for instance properties. 

Note that namespace prefixes used in the property path attributes must be 
defined on the `property-defs` element. The default namespace and any prefixed
namespaced used on `property-defs` will be used to interpret the path. 

In the example above, there are four namespace specifications on `property-defs`:

- xmlns:es="http://marklogic.com/entity-services"
- xmlns:m="http://marklogic.com/smart-mastering/merging"
- xmlns:has="has"
- xmlns=""

Because the default namespace is "", the `m:` prefix is used for 
`property-defs` and `property` elements. The values of the path attributes will 
use these namespaces. Thus in `/es:envelope/es:headers/custom/this/has:a/deep/path`, 
any `custom` elements will be in the default (blank) namespace. 

### Algorithms

As part of creating a merged document, the merge process identifies the values
the source documents have for each property, then selects which of them will be
preserved in the merged document. The `algorithms/algorithm` elements list
algorithms you can use to combine property values, in addition to the
`standard` algorithm, which implements the default behavior.

An `algorithm` element must have `name` and `function` attributes. The `name`
attribute is the name this algorithm will be referred to elsewhere in the
configuration. The `function` attribute is the localname of the function that
will be called. This element may also have an `at` attribute, indicating where
to find the source code for this function, and a `namespace` attribute.

Smart Mastering comes with a "standard" algorithm. For information about writing and configuring custom merge 
algorithms, please see the [Custom Merge Algorithms page](/docs/custom-merge-algorithms/). 

#### Standard Algorithm

A `std-algorithm` element will allow you to configure options for the standard algorithm. Supported options are:

##### Timestamp

The timestamp config informs Smart Mastering which element to use for sorting. When merging, the values are sorted in recency order from newest to oldest based on this timestamp. If the timestamp is not provided then there is no recency sort.

```xml
  <std-algorithm 
      xmlns:es="http://marklogic.com/entity-services" 
      xmlns:sm="http://marklogic.com/smart-mastering">
    <timestamp path="/es:envelope/es:headers/sm:sources/sm:source/sm:dateTime" />
  </std-algorithm
```

```json
  "stdAlgorithm": {
    "namespaces": {
      "es": "http://marklogic.com/entity-services",
      "sm": "http://marklogic.com/smart-mastering"
    },
    "timestamp": {
      "path": "/es:envelope/es:headers/sm:sources/sm:source/sm:dateTime"
    }
  }
```

Note that any namespaces used in the `@path` attribute must be defined on the <std-algorithm> element. The default namespace for evaluating the path is the empty namespace.

The timestamp path may point anywhere in the source documents. For instance, in the document below, the `lastModified` 
JSON property is part of the instance, rather than in the headers. This property refers to the last time this document was modified. 

```json
{
  "envelope": {
    "headers": {
      "sources": [
        {
          "name": "MMIS"
        }
      ]
    },
    "instance": {
      "Person": {
        "ids": "53762077-bf06-4933-be9f-4bf3fb3ad0b0",
        "first_name": "Hugo",
        "last_name": "Boldry",
        "email": "hboldry0@ezinearticles.com",
        "gender": "Male",
        "lastModified": "2018-05-25T14:24:36Z"
      }
    }
  }
}
```

The standard algorithm can use this JSON property by setting the path to

> /envelope/instance/Person/lastModified

#### Collections Algorithm

The `collections` algorithm allows the default behavior of how collections are applied to documents to be overridden during various events.

##### Collection Events

There are 4 events that can be configured to act different.

###### On Merge

The `on-merge` event determines what collections are applied to the newly created document that represents a merge of a document set. 

The default behavior is to take the union of existing collections on the original document set and add the `mdm-content` and `mdm-merged` collections.

###### On No Match

The `on-no-match` event determines what collections are applied to the newly created document that represents a merge of a document set. 

The default behavior is to take the union of existing collections on the original document and add the `mdm-content` collection.

###### On Archive

The `on-archive` event determines what collections are applied to the original document set after a merge has taken place. 

The default behavior is to take the existing collections on the original document, remove the `mdm-content` collection and add the `mdm-archived` collection.

###### On Notification

The `on-notification` event determines what collections are applied to a notification document. 

The default behavior is to set the collection to `mdm-notification`.

##### Collection Override Approaches

There are 2 approaches to overriding the behavior of how collections are applied.

###### Simple Collection Override

Simple overrides to behavior can be made with additional configuration. The `add/collection` elements can be used to add collections to the default behavior for an event. The `remove/collection` elements can be used to remove collections to the default behavior for an event. 

The `set/collection` elements can be used to directly determine the full set of collections applied, taking no account for the default collections.

###### Advanced Collection Override

Advanced overrides can be made by referencing an XQuery or JavaScript function that returns a sequence of `xs:string` or array of `String` respectively. 

For XQuery, the function arguments are as follows:
1. event name string
2. map:map of collections stored by document URI
3. options element for event (e.g., on-merge element)

For JavaScript, the function arguments look like the following:
1. event name string
2. JSON Object of collections stored by document URI
3. JSON representation of options element for event (e.g., Object with onMerge property)

### Collections

The `collections/merged` elements can override the default collection(s) applied to merged documents. If multiple `merged` elements are specified, the dataset is restricted to an intersection of those collections.

The `collections/archived` elements can override the default collection(s) applied to archived documents.

The `collections/notification` elements can override the default collection(s) applied to notification documents.

The `collections/auditing` elements can override the default collection(s) applied to auditing documents.

### Merging

The `merging/merge` elements define how values from the source documents will be combined in the merged document.

### `merge` Element

The `merge` element can have five attributes: `default`, `property-name`, `algorithm-ref`, `max-values`, and `strategy`. 
The `default` attribute accepts a boolean value that determines if the `merge` element should define the default behavior for merging. The `property-name` attribute must match the `name` attribute
of one of the `property` elements defined under `property-defs`. Use of the `default` attribute and `property-name` attribute are mutually exclusive. The
`algorithm-ref` attribute must match the `name` attribute of one of the
`algorithm` elements. The `max-values` attribute is an integer indicating how
many values for this property should be copied from source documents to the
merged document. The `strategy` attribute can reference the `name` attribute of a `merge-strategy` element. See the next session for details.

### `merge-strategy` Element

The `merge-strategy` element has only one required attribute of `name`. `merge-strategy` can additionally have any of the attributes or child elements that the `merge` element supports, with the exception of the `property-name` attribute. 

The `merge-strategy` element provides a way to reduce verbosity of the options file by adding the ability to reference repeated patterns.

#### Standard Merging

The standard algorithm will keep up to 99 values for each property. A `merge`
element can specify a different number and can control the order in which the
values are listed. The `merge` element for the standard algorithm can also
specify a weighted preference for sources and a weight by which to prefer longer
values. Any property that does not have a `merge` element or that has a `merge`
element that does not specify an `algorithm-ref` will use the standard
algorithm.

```xml
  <merge property-name="name" max-values="1" algorithm-ref="standard">
    <length weight="8" />
    <source-weights>
      <source name="good-source" weight="2"/>
      <source name="better-source" weight="4"/>
    </source-weights>
  </merge>
```

None of the elements inside the `merge` element are required.

Written as JSON, the above example looks like this:

```json
  "merging": [
    {
      "propertyName": "name", 
      "maxValues": "1", 
      "algorithmRef": "standard",
      "length": { "weight": "8" }, 
      "sourceWeights": {
        "source": { "name": "better-source", "weight": "4" }
      }
    }
  ]
```

Notice that the `property-name`, `max-values`, and `algorithm-ref` attributes
correspond to JSON properties. 

#### Custom Merging

To use a different algorithm in XML, create a `merge` element with an `algorithm-ref`
attribute that refers to one of the `algorithm` elements. The contents of the
`merge` element will be passed into the merging function.

For JSON, the object will use an `algorithmRef` property that refers to one of 
the `algorithm` objects. The merge object will be passed to the merging 
function.

See the [Custom Merge Algorithms](../custom-merge-algorithms/) section for more information.

#### Triple Merging

To use a custom function for merging triples, create a `triple-merge` element with attributes to refer to the function: `at`, `namespace`, `function`.

```xml
  <triple-merge
    function="custom-trips"
    namespace="http://marklogic.com/smart-mastering/merging"
    at="/custom-triple-merge.xqy">
    <some-param>3</some-param>
  </triple-merge>
```

**Custom Xquery code**

```xquery
xquery version "1.0-ml";

(: you can define any namespace you like :)
module namespace custom-merging = "http://marklogic.com/smart-mastering/merging";

declare namespace m = "http://marklogic.com/smart-mastering/merging";

(: A custom triples merging function
 : 
 : @param $merge-options specification of how options are to be merged
 : @param $docs  the source documents that provide the values
 : @param $sources  information about the source of the header data
 : @param $property-spec  configuration for how this property should be merged
 : @return zero or more sem:triples
 :)
declare function custom-merging:custom-trips(
  $merge-options as element(m:options),
  $docs,
  $sources,
  $property-spec as element()?
) {
  let $some-param := $property-spec/*:some-param ! xs:int(.)
  return
    sem:triple(sem:iri("some-param"), sem:iri("is"), $some-param)
};

```

For JSON, the object will use a `tripleMerge` property that refers to the function.

```json
  "tripleMerge": {
    "function": "customTrips",
    "namespace": "http://marklogic.com/smart-mastering/merging",
    "at": "/custom-triple-merge.xqy",
    "some-param": 3
  }
```

**Custom Javascript code**

```javascript
'use strict'

/* A custom triples merging function
 *
 * @param mergeOptions specification of how options are to be merged
 * @param docs  the source documents that provide the values
 * @param sources  information about the source of the header data
 * @param propertySpec  configuration for how this property should be merged
 * @return zero or more sem.triples
 */
function customTrips(mergeOptions, docs, sources, propertySpec) {
  const someParam = parseInt(propertySpec.someParam, 10);
  return sem.triple(sem.iri("some-param"), sem.iri("is"), someParam);
}

exports.customTrips = customTrips;
```
