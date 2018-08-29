---
layout: inner
title: Custom Merge Algorithms
permalink: /docs/custom-merge-algorithms/
---

# Custom Merge Algorithms

Smart Mastering provides out-of-the-box merging capabilities, but you may want to customize how that merging happens. 
The default behavior is to grab all the values from matching documents, sort them on weight, then return the first 
`@max-values` values (see [Matching Options](/docs/matching-options/)). If `@max-values` is not set, then the first 99 values are returned.

If you want to take more control over what it means for two property values to merge, you can do so by implementing 
your own algorithm in a function. Create a function with the signature below. Return a subset of the properties passed
into the function. 

## Customizing Merging

### Custom Merging with JavaScript

Here is the JavaScript function signature for a custom merge algorithm:

```javascript
function customMerge(
  propertyName,
  properties,
  propertySpec
)
```

The `propertyName` is simply the name of the JSON property that holds the instance property being merged. The 
`properties` parameter is a sequence of JavaScript objects that provide information about property values from the 
source documents, along with lineage information. Each object has three keys: `sources`, `values`, and `name`. The 
value for `sources` is itself an object, with keys `name` (an identifier) extracted from the source; `dateTime` (an 
`xs:dateTime`) extracted from the source, if available; and `documentUri` (identifying this particular source 
document). The `values` key connects to the property value or values from this particular source document. The `name` 
key is the name of the property value. 

The `propertySpec` parameter is the JSON obejct from the merging properties that corresponds to the property for which 
the algorithm is being used. 

### Custom Merging with XQuery

Here is the XQuery function signature for a custom merge algorithm:

```xquery
declare function custom-merging:customThing(
  $property-name as xs:QName,
  $properties as map:map*,
  $property-spec as element(merging:merge)?
)
```

The `$property-name` is simply a QName identifying the property. The `$properties` parameter is a sequence of map:maps 
that provide information about property values from the source documents, along with lineage information. Each map has
three keys: `sources`, `values`, and `name`. The value for `sources` is itself a map, with keys `name` (an identifier)
extracted from the source; `dateTime` (an `xs:dateTime`) extracted from the source, if available; and `documentUri` 
(identifying this particular source document). The `values` key connects to the property value or values from this 
particular source document. The `name` key is the name of the property value. 

The `$property-spec` parameter is the `merging:merge` element from the merging properties that corresponds to the 
property for which the algorithm is being used. 

