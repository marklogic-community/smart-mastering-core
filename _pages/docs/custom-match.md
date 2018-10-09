---
layout: inner
title: Custom Match Algorithms
permalink: /docs/custom-match-algorithms/
---

# Custom Match Algorithms

Smart Mastering provides out-of-the-box matching capabilities, but you may want
to customize how that matching happens. The default behavior is simple: for a
particular property, if two documents have exactly the same values for that 
property, then the property is a match. Each property is configured with a 
weight that contributes to a match score between two documents. 

If you want to take more control over what it means for two property values to 
match, you can do so by implementing your own algorithm in a function. 

## Harmonization and Smart Mastering

Note that Smart Mastering is intended to be run after harmonization, so 
normally at the least the document structures will be the same; generally, the 
values should have been standardized as well. 

As an example, suppose your document has a "state" property, corresponding to 
the US state in which a person lives. You might have some sources that use the
state's name ("Pennsylvania"), others that use the 2-letter code ("PA"), and 
still others that use the state's official, full name ("Commonwealth of
Pennsylvania"). Your harmonization process will normally make sure that not 
only are the state values from all sources put into the same property name 
"state-code", but that the values are standardized using one format ("PA"). In
this case, it would not be necessary to use a custom algorithm to compare 
properties. 

## Customizing Matching

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

## Configuring Options to Use Custom Match Functions

To use your custom match functions, add them to the `algorithms` section of your match options. The 
`algorithm-ref`/`algorithmRef` used for the `expand` definitions refers to the name you assign in the `algorithms` 
section. 

The `algorithm` needs `name`, `at`, `function`, and for XQuery functions, `ns` in order to find your custom code. The 
`at` property is the absolute path the library module in the modules database that holds your function. `ns` is the 
namespace in an XQuery library module. `function` is the actual name of the function (not including the namespace or 
prefix for XQuery code).

### XML Options

```xml
  <algorithms>
    <algorithm 
      name="favorite-color" 
      at="/smart-mastering/match/favorite-color.xqy" 
      ns="http://example.com/big-hub/smart-mastering/match/favorite-color"
      function="favorite-color"/>
  </algorithms>
```

### JSON Options

```javascript
    "algorithms": {
      "algorithm": [
        { 
          "name": "favoriteColor", 
          "at": "/smart-mastering/match/favoriteColor.sjs"
          "function": "favoriteColor" 
        }
      ]
    },
```

[zip.xqy]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/algorithms/zip.xqy
