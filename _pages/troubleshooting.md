---
layout: inner
title: Troubleshooting
permalink: /troubleshooting/
---

# Troubleshooting

Tips for solving problems

## How do I check whether a document has any matches? 

In Query Console, try calling the `matcher:find-document-matches-by-options-name` 
function directly, like this:

```xquery
import module namespace matcher = "http://marklogic.com/smart-mastering/matcher" 
  at "com.marklogic.smart-mastering/matcher.xqy";

matcher:find-document-matches-by-options-name(
  fn:doc("/Organizations/Source1/org1.json"),
  "org-match-options",
  fn:true(),
  cts:collection-query('Organization')
)
```
The results will show what documents matched and what properties matched in 
each. It will also show the query that was generated to look for matches. 
Review the query to make sure it's extracting the properties correctly. 

If it seems like the query is correct, but a document that you're expecting to
match isn't included in the results, it could be that it scored lower than 
expected. Consider lowering the threshold in the match options and reloading 
the options. 

## Traces available for debugging

The following traces can be enabled to aid with debugging:
  - `SM-MATCH`
  - `SM-MERGE`
  - `SM-PERFORMANCE`
