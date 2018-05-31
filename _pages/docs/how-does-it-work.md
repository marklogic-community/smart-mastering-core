---
layout: inner
title: How Does it Work?
lead_text: ''
permalink: /docs/how-does-it-work/
---

# How Does it Work?

Smart Mastering consists of configuration-driven matching and merging. While
the [How To Use][how-to-use] page will show you how to access this
functionality, this page describes the matching and merging processes that
make up Smart Mastering.

The Smart Mastering process focuses on one document at a time, identifying
any other documents that appear to represent the same entity (Matching) and
then combining the values in those documents to create a new document (Merging).

## Collections

Smart Mastering Core uses collections to separate types of content. Applications
should use [`constants.xqy`][constants] for the names of the collections. The
most important collection is `$CONTENT-COLL`, which contains the current set of
entities that should be used by an application. When a set of documents get
merged, they are moved out of that collection and into the `$ARCHIVED-COLL`
collection. The generated merged document will be in the `$CONTENT-COLL` and
`$MERGED-COLL` collections. 

## Matching

The matching process begins with a document, which we'll call the "original"
document. This document may be selected because it's just been inserted into the
database, or because a process is cycling through all content.

The original document contains a set of properties, each with values. The
[match configuration][match-config] specifies what properties are to be used
for matching. The heart of the matching process is using these property values
to construct a query to be run against the other entity documents in the
database. Each property that is involved in matching turns into a `cts:query`;
these queries are bundled together and used to run a search to find potential
matches.

The assembled query has two parts: a match query and a boost query. The boost
query consists of queries for all properties, with their respective weights. The
match query is a subset of all the queries, chosen to ensure that any potential
match that gets returned will have a score of at least the lowest threshold
configured in the match options.

The combined query will be run once, generating a score-ordered sequence of
potential matches, each of which is labeled according to a threshold of match
probability. A match response will look like this:

    <results uri="/source/3/doc3.json" index="1" total="5" score="79" threshold="Definitive Match" action="merge">

### Matching Algorithms

The default query to look for documents with property values that match the
original document is a `cts:element-value-query`, looking for the exact same
value that the original document has. In some cases, you might want to provide
more flexibility in defining what a match is. For those cases, you can specify
an algorithm.

A matching algorithm function takes the value(s) of a single property from the
original document, along with the match configuration, and uses that to generate
a query to find other documents that have relevant values for the same property.
This function will be run once for each original document. This is a normal
XQuery or SJS function, so it can make database queries, call out to third-party
services, or do anything else needed to generate that query.

To see an example of a matching algorithm function, see [zip.xqy][zip.xqy].

## Merging

Merging takes a set of documents and creates a new document to represent the
combination. The structure of the document will match the originals, which are
assumed to have been harmonized. The merge configuration controls how property
values from the input documents are preserved in the new document.

When two or more documents get merged, they are removed from the
[`$CONTENT-COLL`][constants]. A new document is added to the
[`$CONTENT-COLL`][constants] and to the [`$MERGED-COLL`][constants]. Smart
Mastering Core will record that these documents were combined into the new one,
including the source for each property value in the merged document. This allows
an application to observe the history of a document and its properties, as well
as to undo a merge.

### Merging Algorithms

There is a standard algorithm available to combine properties, which is
described on the [Merging Options][merge-config] page.

Smart Mastering Core also supports custom merge algorithms. This function takes
the `xs:QName` for a property, values from the input documents, and the
`merging/merge` configuration of this property (see
[merging options][merge-config]). The function returns an ordered list of
property values, with the length of the sequence and the ordering defined by the
algorithm. Note that the algorithm does not need to only gather or choose among
values from the input documents; it may choose to aggregate those values.

To see examples of custom algorithms, see the unit tests in the [`merging` test
suite][merging-suite].


[how-to-use]: /docs/how-to-use/
[match-config]: /docs/matching-options/
[zip.xqy]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/ext/com.marklogic.smart-mastering/algorithms/zip.xqy
[merge-config]: /docs/merging-options/
[constants]: https://github.com/marklogic-community/smart-mastering-core/blob/master/src/main/ml-modules/ext/com.marklogic.smart-mastering/constants.xqy
[merging-suite]: https://github.com/marklogic-community/smart-mastering-core/tree/master/src/test/ml-modules/root/test/suites/merging
