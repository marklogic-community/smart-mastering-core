---
layout: inner
title: Included Actions
permalink: /docs/actions/
---

# Actions

Smart Mastering consists of matching and merging. These can be called individually or together using the 
match-and-merge APIs. When using match-and-merge, the match options can control what actions are to take place with 
documents whose scores meet certain thresholds. Smart Mastering provides two actions and [the ability to create custom
actions](../custom-actions/). 

## Merge

Using `action="merge"` tells Smart Mastering that when documents match with high enough scores, they should 
automatically be merged into a new document. The original documents will be archived (moved to a different collection)
and provenance information will be captured about the merge. See the [merge options] page for details on how to control
the merging process. 

[merge-options]: https://marklogic-community.github.io/smart-mastering-core/docs/merging-options/

## Notify

Using `action="notify"` tells Smart Mastering that when documents get match scores that meet this threshold, but are lower
than the threshold for merging, the action should record a notification document for a human to review. 
