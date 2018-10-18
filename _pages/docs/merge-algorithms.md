---
layout: inner
title: Custom Merging Algorithms
permalink: /docs/merge-algorithms/
---

# <a name="intro"/> Out-of-the-Box Merge Algorithms 

Smart Mastering provides the following merge algorithms that you can use without having to write any code. A merge
algorithm determines which property values from source documents are brought into a merge document. That is, when 
merging documents A, B, and C, suppose that for a particular property, those documents had values A1, A2, B1, and C1.
A merge algorithm will determine which and how many of those values will be in the new document ABC. 

In addition to the built-in algorithm, [you can write your own custom functions](../custom-match-algorithms/). 

## Standard Algorithm

Smart Mastering currently provides a standard algorithm, which can be configured for different uses. You can use it by 
adding XML or JSON similar to the below to your merge options. 

```xml
<options xmlns="http://marklogic.com/smart-mastering/merging">
  <merging xmlns="http://marklogic.com/smart-mastering/merging">
    <merge property-name="some-property" max-values="1">
      <source-weights>
        <source name="good-source" weight="2"/>
        <source name="better-source" weight="4"/>
      </source-weights>
    </merge>
    <merge property-name="another-property" max-values="1">
      <length weight="8" />
    </merge>
  </merging>
</options>
```

```javascript
{
  "options": {
    "merging": [
      {
        "propertyName": "some-property",
        "sourceWeights": [
          { "source": { "name": "good-source", "weight": "2" } },
          { "source": { "name": "better-source", "weight": "4" } }
        ]
      },
      {
        "propertyName": "another-property",
        "maxValues": "1",
        "length": { "weight": "8" }
      }
    ]
  }
}
```

### Sorting by Source

The standard algorithm will sort the available values and keep the first `max-values`/`maxValues` other them. The sort
of the values is based on weights for individual sources (where the source is identified by the value at 
`/es:envelope/es:headers/sm:sources/sm:source/*:name` for XML and `/envelope/headers/sources/source/name` for JSON). 
To sort by source weight, provide the name of the sources from the document headers and a weight. These weights must be
castable to `xs:double`. 

### Sorting by Length

This algorithm can sort values by how long they are. Consider length here to be a proxy for more complete information. 
Use the weight setting for length to control how much influence this attribute has. 

### Sorting by Recency

If the source documents have a dateTime that indicates how recent the data is, the standard algorithm can use that sort
values. See https://marklogic-community.github.io/smart-mastering-core/docs/merging-options/#timestamp for information
on configuring this feature.

### Combining the Sort Factors

The scores for source preference and for value length will be added together. Ties are resolved by the more recent 
source, if a timestamp location is configured. 
