---
layout: inner
title: Matching Options
permalink: /docs/matching-options/
---

# Matching Options

Smart Mastering Core offers a configuration-driven matching capability. The
match process starts with a document (referred to as the "candidate" document)
and looks for other documents that might describe the same entity. Match
configuration includes the properties to look for, how to compare them, and what
thresholds to use for taking action on the matches. Only the properties listed
under the `scoring` element will be used to find and score potential matches. 
The match process returns a relevance-ranked sequence of potential matches, based 
on the weights you specify.

## Configuring Options

Here's an example of match configuration options.

```
<options xmlns="http://marklogic.com/smart-mastering/matcher">
  <property-defs>
    <property namespace="" localname="IdentificationID" name="ssn"/>
    <property namespace="" localname="PersonGivenName" name="first-name"/>
    <property namespace="" localname="PersonSurName" name="last-name"/>
    <property namespace="" localname="AddressPrivateMailboxText" name="addr1"/>
    <property namespace="" localname="LocationCity" name="city"/>
    <property namespace="" localname="LocationState" name="state"/>
    <property namespace="" localname="LocationPostalCode" name="zip"/>
  </property-defs>
  <algorithms>
    <algorithm name="std-reduce" function="standard-reduction"/>
    <algorithm name="std-reduce-query" function="standard-reduction-query"/>
    <algorithm name="dbl-metaphone" function="double-metaphone"/>
  </algorithms>
  <scoring>
    <add property-name="ssn" weight="50"/>
    <add property-name="last-name" weight="8"/>
    <add property-name="first-name" weight="6"/>
    <add property-name="addr1" weight="5"/>
    <add property-name="city" weight="3"/>
    <add property-name="state" weight="1"/>
    <add property-name="zip" weight="3"/>
    <expand property-name="first-name" algorithm-ref="thesaurus" weight="6">
      <thesaurus>/mdm/config/thesauri/first-name-synonyms.xml</thesaurus>
      <distance-threshold>50</distance-threshold>
    </expand>
    <expand property-name="last-name" algorithm-ref="dbl-metaphone" weight="8">
      <dictionary>name-dictionary.xml</dictionary>
      <!--defaults to 100 distance -->
    </expand>
    <reduce algorithm-ref="std-reduce" weight="4">
      <all-match>
        <property>last-name</property>
        <property>addr1</property>
      </all-match>
    </reduce>
  </scoring>
  <actions>
    <action name="my-custom-action" function="custom-action" namespace="http://marklogic.com/smart-mastering/action" at="/custom-action.xqy" />
  </actions>
  <thresholds>
    <threshold above="30" label="Possible Match"/>
    <threshold above="50" label="Likely Match" action="notify"/>
    <threshold above="68" label="Definitive Match" action="merge"/>
    <threshold above="75" label="Custom Match" action="my-custom-action"/>
    <!-- below 25 will be NOT-A-MATCH or no category -->
  </thresholds>
  <tuning>
    <max-scan>200</max-scan>
  </tuning>
</options>
```

### Property Definitions

The `property-defs/property` elements identify the elements that will be used to
find matches for a document. Use the `namespace` and `localname` attributes to
specify an XML element or JSON property. The `name` attribute acts as a nickname
for this property in the rest of the configuration.

### Algorithms

The `algorithms/algorithm` elements list additional algorithms you can use to
compare property values. The default approach is comparing for equality. To set
up matching with your custom code, add an `algorithm` element with attributes
`name`, `function`, `namespace`, and `at`. The `name` attribute is used to refer
to this algorithm later in the configuration. The other three attributes are
used to find the code.

For an example, see [zip.xqy][zip.xqy].

### Scoring

Matches are based on how many properties match, what algorithms are used to
determine matches, and the weights placed on the properties. See the How Scoring
Works section for more information about how match scores are calculated.

#### `add` elements

This section really drives the matching process. For each `add` element, the
matcher will add this element or property to the query used to find other
documents that match the candidate document. The `property-name` attribute must
match the `name` attribute of a `property` element defined under
`property-defs`. The `weight` attribute is the number of points awarded to
a potential match if the values match.

#### `expand` elements

To apply a different matching strategy, add an `extend` element. The
`property-name` element must match the `name` attribute of a `property` element
defined under `property-defs`. The `algorithm-ref` attribute must match the
`name` attribute of an `algorithm` element under `algorithms`. Sub-elements
under the `extend` element depend on the implementation of the function.

#### `reduce` elements

In some cases, a combination of matching properties may suggest a match when
there shouldn't be one. Consider two relatives living together. When matched,
two Person records have the same family name, same street address, city, and zip
code. That might be enough points to trigger a match even though the two given
names differ.

The `reduce` element gives a way to back off the scores in such cases. The
`algorithm-ref` attribute must match the `name` attribute of an `algorithm`
element under `algorithms`. The `weight` attribute will be subtracted from the
score if the algorithm matches.

### Actions

You can provide your own custom action handler functions. Custom actions are called after merge and notify have run. These actions will be called in a separate transaction, so the results of each call will be visible to the actions called after it.

```xml
<actions>
  <action name="my-custom-action" function="custom-action" namespace="http://marklogic.com/smart-mastering/action" at="/custom-action.xqy" />
</actions>
```

Each custom action can define four properties:
- **name** - the name of the custom action
- **function** - the name of the custom function to invoke
- **namespace** - the namespace of the module containing the function
- **at** - the uri location of the module containing the function

Your custom action will be called with three parameters:

```
$uri - the uri of the document being matched
$matches - either an array (sjs) or sequence (xqy) of matches
$merge-options - the merge options as xml (for xqy) or json (for sjs)
```


### Thresholds

Smart-mastering-core can be configured to take different actions based on the
match scores. Each `threshold` element has an `above` attribute, which is the
minimum absolute score a match must have against the candidate document in order
to reach that threshold. A `threshold` element may also have a `label` attribute
and an `action` attribute. If the `action` attribute is "merge", then the
candidate document and any document that reaches this threshold will be
automatically merged. For `action="notify"`, a notification will be recorded
for a human reviewer.

### Tuning

The `max-scan` element limits the number of potential matches that get
processed. In the example configuration with `<max-scan>200</max-scan>`,
only the top 200 scoring potential matches will be merged or have notifications
recorded.

## How Scoring Works

High scores are relative to the configuration, rather than measured on an
absolute scale. The maximum possible score is the sum of the weights of all of
the weight attributes.

```
<scoring>
  <add property-name="ssn" weight="50"/>
  <add property-name="last-name" weight="8"/>
  <add property-name="first-name" weight="6"/>
  <add property-name="addr1" weight="5"/>
  <add property-name="city" weight="3"/>
  <add property-name="state" weight="1"/>
  <add property-name="zip" weight="3"/>
  <expand property-name="first-name" algorithm-ref="thesaurus" weight="6">
    <thesaurus>/mdm/config/thesauri/first-name-synonyms.xml</thesaurus>
    <distance-threshold>50</distance-threshold>
  </expand>
  <expand property-name="last-name" algorithm-ref="dbl-metaphone" weight="8">
    <dictionary>name-dictionary.xml</dictionary>
    <!--defaults to 100 distance -->
  </expand>
  <reduce algorithm-ref="std-reduce" weight="4">
    <all-match>
      <property>last-name</property>
      <property>addr1</property>
    </all-match>
  </reduce>
</scoring>
```

In the example configuration above, the maximum possible score is
50+8+6+5+3+1+3+6+8-4=86. Thresholds must be adjusted based on these values.

This process is run as a normal search, which control over the scoring. For more
information about how search works in MarkLogic, see [Understanding the Search
Process][understanding-search]. The match process uses the simple scoring
option, with the property weight controlling how much influence each should
have. To read more about how scoring works in MarkLogic, see [Relevance Scores:
Understanding and Customizing][scoring]. 

## Saving Options

Matching options may be stored before starting the matching process. Doing so
means that the client layer does not need to store and maintain the options.

### REST

To save match options using REST, POST them to `/v1/resource/sm-match-options`
with `rs:name` as a URL parameter and the options in the body of the request.

### XQuery/SJS

To save match options using XQuery, import `matcher.xqy` and call the
`matcher:save-options` function.

[zip.xqy]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/algorithms/zip.xqy
[understanding-search]: http://docs.marklogic.com/guide/performance/unfiltered#id_13165
[scoring]: http://docs.marklogic.com/guide/search-dev/relevance#chapter
