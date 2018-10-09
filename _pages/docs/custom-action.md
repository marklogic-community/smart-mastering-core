---
layout: inner
title: Custom Match Actions
permalink: /docs/custom-actions/
---

# Custom Match Actions

Smart Mastering provides two out-of-the-box matching actions, merge and notify. The merge process combines two or more
documents and archives the originals; the notify action creates a notification document listing the matching documents.

If you want to create a custom action, to do something other than merging or notifying, you can do so by implementing your own action in a function. 

### JavaScript

To implement your own algorithm in Javascript, create a function with this 
signature: 

```javascript
function yourFunctionName(uri, matches, mergeOptions) {}
```

The `uri` parameter contains the uri of the document used in the matching phase. The `matches` parameter is an array of documents that match `uri`. The `mergeOptions` is the complete merge options as a JSON object. 

The `matches` values will look like this:

```json
[
  {
    "uri": "/source/2/doc2.xml",
    "score": 70,
    "threshold": "Kinda Match"
  }
]
```

Your function should not return anything. If it does, the returned value will be ignored.

### XQuery

To implement your own algorithm in XQuery, create a function with this 
signature: 

```xquery
declare function your-namespace:your-custom-function-name(
  $uri as xs:string,
  $matches as item()*,
  $merge-options as element(merging:options)
) as empty-sequence()
```

The `$uri` parameter contains the uri of the document used in the matching phase. The `$matches` parameter is a sequence of  elements identifying documents that match `$uri`. The `$merge-options` is the complete merge options as an XML element(merging:options). 

The `$matches` will be a sequence of `result` elements that look like this:

```xml
<result uri="/source/3/doc3.json" index="1" score="79" threshold="Definitive Match" action="my-action"/>
```

## Configuring Options to Use Custom Action Functions

To use your custom action functions, add them to the `actions` section of your match options. The 
`action` used for the `threshold` definitions refers to the name you assign in the `actions` section. 

The `action` needs `name`, `at`, `function`, and for XQuery functions, `ns` in order to find your custom code. The `at` 
property is the absolute path the library module in the modules database that holds your function. `ns` is the 
namespace in an XQuery library module. `function` is the actual name of the function (not including the namespace or 
prefix for XQuery code). Note that while the attributes repeat the same name in the examples below, this is not 
required.

### XML Options

```xml
  <actions>
    <action 
      name="send-alert" 
      at="/smart-mastering/action/send-alert.xqy"
      namespace="http://marklogic.com/smart-mastering/action/send-alert" 
      function="send-alert" />
  </actions>
```

### JSON Options

```javascript
    "actions": {
      "action": {
        "name": "sendAlert",
        "at": "/smart-mastering/action/send-alert.sjs",
        "function": "sendAlert"
      }
    },
```
