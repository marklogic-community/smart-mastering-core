---
layout: inner
title: How to Apply Smart Mastering
lead_text: ''
permalink: /how-to-use/
---

# How Do I Use It?

To use Smart Mastering in your project, start by adding it to your project as
shown in the [minimal-project example][minproject].

Define your [match](/docs/matching-options) and [merge](/docs/merging-options)
options. These will control how matches are identified and how properties are
merged into a new document.

From this point, you have a couple of choices about how to run mastering.

## Mastering Your Content

### Mastering with Data Hub Framework

If you're using the MarkLogic Data Hub Framework, you can run mastering as a
flow. See the [smart-mastering-demo for an example][sm-demo-flow]. The key part
is in the [writer][sm-demo-flow-writer], which calls
[`process:process-match-and-merge()`][match-and-merge].

### Mastering with a Trigger

Smart Mastering can be set up so that whenever a document is inserted into the
database, a trigger gets called to look for matches and merge as appropriate.
See [`match-and-merge-trigger.xqy`][trigger] for the trigger code, [Using
Triggers to Spawn Actions][trigger-doc] in the Application Developer's Guide to
learn about how triggers work, and the [ml-gradle wiki][ml-gradle-trigger] for
an example of how to deploy triggers with ml-gradle.

### Custom Approach

You can also access the Smart Mastering functionality by directly calling the
[REST API extensions](/docs/rest) or [XQuery libraries](/docs/libraries).

## Collections

Smart Mastering expects to find documents in particular collections. See the
list of collections in [`constants.xqy`][constants]. Some of the notable
collections:
- `$CONTENT-COLL`: insert any documents that should be available for merging
into this collection. When two documents get merged, they will be removed from
this collection and replaced with the new merged document. Your application
should limit searches to this collection.
- `$MERGED-COLL`: merged documents will be created in this collection. When a
merge is rolled back, the rolled document will be removed from this collection
and from the `$CONTENT-COLL`.
- `$ARCHIVED-COLL`: original documents that have been merged will be moved into
this collection.



[minproject]: https://github.com/marklogic-community/smart-mastering-core/tree/master/examples/minimal-project
[sm-demo-flow]: https://github.com/marklogic-community/smart-mastering-demo/tree/develop/examples/smart-mastering/plugins/entities/MDM/harmonize/SmartMaster
[sm-demo-flow-writer]: https://github.com/marklogic-community/smart-mastering-demo/blob/develop/examples/smart-mastering/plugins/entities/MDM/harmonize/SmartMaster/writer/writer.xqy
[match-and-merge]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/ext/com.marklogic.smart-mastering/process-records.xqy
[trigger]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/ext/com.marklogic.smart-mastering/match-and-merge-trigger.xqy
[trigger-doc]: http://docs.marklogic.com/guide/app-dev/triggers#chapter
[ml-gradle-trigger]: https://github.com/marklogic-community/ml-gradle/tree/master/examples/triggers-project
[constants]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/ext/com.marklogic.smart-mastering/constants.xqy
