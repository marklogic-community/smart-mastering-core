---
layout: inner
title: Custom Merge Algorithms
permalink: /docs/custom-merge-algorithms/
---

# Custom Merge Algorithms

Smart Mastering provides out-of-the-box merging capabilities, but you may want
to customize how that merging happens. The default behavior is to grab all the values from matching documents, sort them on weight, then return the first @max-values values. If @max-values is not set, then the first 99 values are returned.

If you want to take more control over what it means for two property values to 
merge, you can do so by implementing your own algorithm in a function. 

## Customizing Merging

Sometimes data sources simply have different levels of information. Zip codes
are a good example. In the United States, an address includes a zip code, which
may have either five ("19106") or nine ("19106-2320") digits. A nine-digit zip 
code identifies a more precise location and is entirely contained within the 
area of the five-digit zip code that it starts with. [zip.xqy][zip.xqy] 
implements an algorithm that gives points if the 5-digit portion of a 9-digit
zip code matches a 5-digit zip code.

Matching looks for candidate matches for a particular document. It does this by
building a query based on configured properties and the values of those 
properties in the document. 

### JavaScript

To implement your own algorithm in Javascript, create a function with this 
signature: 

```javascript
function zipMatch(
  expandValues,
  expandXML,
  optionsXML
)
```
The `expandValues` parameter contains the value or values from the document. 
The `expandXML` parameter is the portion of `expand` element of the match 
options that corresponds to the target property. The `optionsXML` is the 
complete match options. 

Your function must return zero or more queries. You can return zero if your 
function decides that this property should not be a factor in matching (for 
instance, if the original document does not have a value for this property).

### XQuery

To implement your own algorithm in XQuery, create a function with this 
signature: 

```xquery
declare function algorithms:zip-match(
  $expand-values as xs:string*,
  $expand-xml as element(matcher:expand),
  $options-xml as element(matcher:options)
) as cts:query*
```

The `$expand-values` parameter contains the value or values from the document. 
The `$expand-xml` parameter is the portion of `expand` element of the match 
options that corresponds to the target property. The `$options-xml` is the 
complete match options. 

Your function must return zero or more queries. You can return zero if your 
function decides that this property should not be a factor in matching (for 
instance, if the original document does not have a value for this property).


[zip.xqy]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/algorithms/zip.xqy
