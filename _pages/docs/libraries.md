---
layout: inner
title: Libraries
lead_text: ''
permalink: /docs/libraries/
---

# Smart Mastering with Libraries

The Smart Mastering Core project includes a set of XQuery libraries. Once
you have included the core in your own project and run `gradle mlDeploy`,
these libraries will be available to your project. Note that although they are
written in XQuery, they can be imported into JavaScript code as well.

Smart Mastering functionality consists of configuration-driven mastering and
merging, as well as services to retrieve history for documents or individual
properties within merged documents. This page will show you how to access this
functionality using the libraries.

The XQuery libraries are structured to separate the API from the implementation.
While it's possible the API will undergo some changes, it is intended to be
relatively stable. The implementation functions may change substantially,
however. Avoid importing implementation libraries.

The best source of documentation for these libraries are the JavaDoc-style
comments in the library modules. This page will give an overview of which
library modules to look in and the high-level functionality available in them.

## Matching

The [`matcher.xqy` module][matcher] provides functions to store, retrieve, 
delete, and list match options; find potential matches for a document; and to 
store, retrieve, delete, and list match blocks. To see what the results of the 
match functions look like, see [Match Results](../docs/match-results). 

## Merging

The [`merging.xqy` module][merging] provides functions to build (preview), save, or remove
merged documents and to store, retrieve, delete, and list merge options

## Process Match and Merge

The [`process-records.xqy`][process] module provides two functions to run through both
matching and merging for a particular document.

## Constants

The [`constants.xqy` module][constants] provides several XQuery variables that are used
throughout the code. Always use these variables, rather than hard-coding the
values that they refer to.

## Trigger

[`match-and-merge-trigger.xqy`][trigger] implements a trigger to process matching and
merging any time a new document is inserted into the content collection.

[matcher]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/matcher.xqy
[merging]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/merging.xqy
[process]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/process-records.xqy
[constants]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/constants.xqy
[trigger]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/root/com.marklogic.smart-mastering/match-and-merge-trigger.xqy
