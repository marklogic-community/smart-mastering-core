---
layout: inner
title: Custom Match Actions
permalink: /docs/custom-actions/
---

# Custom Match Actions

Smart Mastering provides two out-of-the-box matching action, merge and notify. Merging runs the merge process and notify creates a notification about the matching documents.

If you want to create a custom action, to do something other than merging or notifying, you can do so by implementing your own action in a function. 

### JavaScript

To implement your own algorithm in Javascript, create a function with this 
signature: 

```javascript
function yourFunctionName(uri, matches, mergeOptions) {}
```

The `uri` parameter contains the uri of the document used in the matching phase. The `matches` parameter is an array of documents that match `uri`. The `mergeOptions` is the complete merge options as a JSON object. 

Your function should not return anything. If it does, the returned value will be ignored.

### XQuery

To implement your own algorithm in XQuery, create a function with this 
signature: 

```xquery
declare function your-namespace:your-custom-function-name(
  $uri as xs:string,
  $matched-uris as item()*,
  $merge-options as element(merging:options)
) as empty-sequence()
```

The `$uri` parameter contains the uri of the document used in the matching phase. The `$matches` parameter is a sequence of documents that match `$uri`. The `$merge-options` is the complete merge options as an XML element(merging:options). 
