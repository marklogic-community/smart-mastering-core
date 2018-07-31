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

Here's an example of merge configuration options.

```
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
  </m:property-defs>
  <algorithms>
    <algorithm name="name" function="name"/>
    <algorithm name="address" function="address"/>

    <!-- config for standard algorithm -->
    <!-- any needed namespaces get defined on the std-algorithm element -->
    <std-algorithm xmlns:es="http://marklogic.com/entity-services" xmlns:sm="http://marklogic.com/smart-mastering">
      <!-- provide the path to the timestamp element to use for sorting -->
      <!-- when merging the values are sorted in recency order from newest
           to oldest based on this timestamp. If the timestamp is not
           provided then there is no recency sort -->
      <timestamp path="/es:envelope/es:headers/sm:sources/sm:source/sm:dateTime" />
    </std-algorithm>
  </algorithms>
  <merging>
    <merge property-name="ssn" algorithm-ref="user-defined">
      <source-ref document-uri="docA" />
    </merge>
    <merge property-name="name"  max-values="1">
      <double-metaphone>
        <distance-threshold>50</distance-threshold>
      </double-metaphone>
      <synonyms-support>true</synonyms-support>
      <thesaurus>/mdm/config/thesauri/first-name-synonyms.xml</thesaurus>
      <length weight="8" />
    </merge>
    <merge property-name="address" algorithm-ref="standard" max-values="1">
      <source-weights>
        <source name="CRM" weight="10"></source>
      </source-weights>
    </merge>
    <merge property-name="dob" algorithm-ref="standard" max-values="1">
      <source-weights>
        <source name="Oracle" weight="10"></source>
      </source-weights>
    </merge>
    <merge property-name="caseStartDate" algorithm-ref="standard" max-values="1">
      <source-weights>
        <source name="CRM" weight="10"></source>
      </source-weights>
    </merge>
    <merge property-name="incidentDate" algorithm-ref="standard" max-values="1">
      <length weight="10"/>
    </merge>
    <merge property-name="sex" algorithm-ref="standard" max-values="1">
      <length weight="10"/>
    </merge>
  </merging>
</options>
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

In addition to properties defined for an entity, properties may also be 
specified by path. The presence of a path attribute indicates that the property
is not part of the entity instance definition. Currently, only paths starting
with /es:envelope/es:headers (for XML) or /envelope/headers (for JSON) are 
supported. Control of the merging process using algorithms works the same for
path properties as it does for instance properties. 

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

A `std-algorithm` element will allow you to configure options for the standard algorithm. Supported options are:

#### Timestamp

The timestamp config informs Smart Mastering which element to use for sorting. When merging, the values are sorted in recency order from newest to oldest based on this timestamp. If the timestamp is not provided then there is no recency sort.

```
  <std-algorithm xmlns:es="http://marklogic.com/entity-services" xmlns:sm="http://marklogic.com/smart-mastering">
    <timestamp path="/es:envelope/es:headers/sm:sources/sm:source/sm:dateTime" />
  </std-algorithm
```

Note that any namespaces used in the @path attribute must be defined on the <std-algorithm> element. The default namespace for evaluating the path is the empty namespace.

### Merging

The `merging/merge` elements define how values from the source documents will
be combined in the merged document.

### `merge` Element

The `merge` element can have three attributes: `property-name`, `algorithm-ref`,
and `max-values`. The `property-name` attribute must match the `name` attribute
of one of the `property` elements defined under `property-defs`. The
`algorithm-ref` attribute must match the `name` attribute of one of the
`algorithm` elements. The `max-values` attribute is an integer indicating how
many values for this property should be copied from source documents to the
merged document.

#### Standard Merging

The standard algorithm will keep up to 99 values for each property. A `merge`
element can specify a different number and can control the order in which the
values are listed. The `merge` element for the standard algorithm can also
specify a weighted preference for sources and a weight by which to prefer longer
values. Any property that does not have a `merge` element or that has a `merge`
element that does not specify an `algorithm-ref` will use the standard
algorithm.

```
  <merge property-name="name" max-values="1">
    <length weight="8" />
    <source-weights>
      <source name="good-source" weight="2"/>
      <source name="better-source" weight="4"/>
    </source-weights>
  </merge>
```

None of the elements inside the `merge` element are required.

#### Custom Merging

To use a different algorithm, create a `merge` element with an `algorithm-ref`
attribute that refers to one of the `algorithm` elements. The contents of the
`merge` element will be passed into the merging function.
