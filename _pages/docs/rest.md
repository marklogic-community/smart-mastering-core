---
layout: inner
title: REST API
lead_text: ''
permalink: /docs/rest/
---

# Smart Mastering with REST APIs

The Smart Mastering Core project includes a set of REST API extensions. Once
you have included the core in your own project and run `gradle mlDeploy`,
these REST extensions will be available to your project.

Smart Mastering functionality consists of configuration-driven mastering and
merging, as well as services to retrieve history for documents or individual
properties within merged documents. This page will show you how to access this
functionality using the REST APIs.

# Table of Contents
1. [Match Options](#match-options)
    1. [sm-match-options](#sm-match-options)
    2. [sm-match-option-names](#sm-match-option-names)
2. [Matching](#matching)
    1. [sm-match](#sm-match)
    2. [sm-block-match](#sm-block-match)
    3. [sm-notifications](#sm-notifications)
3. [Merge Options](#merge-options)
    1. [sm-merge-options](#sm-merge-options)
    2. [sm-merge-option-names](#sm-merge-option-names)
4. [Merging](#merging)
    1. [sm-merge](#sm-merge)
5. [Match and Merge Together](#match-and-merge-together)
    1. [sm-match-and-merge](#sm-match-and-merge)
6. [History](#history)
    1. [sm-history-document](#sm-history-document)
    2. [sm-history-properties](#sm-history-properties)
7. [Other Services](#other-services)
    1. [mastering-stats](#mastering-stats)
    2. [sm-dictionaries](#sm-dictionaries)
    3. [sm-entity-services](#sm-entity-services)
    4. [sm-thesauri](#sm-thesauri)

## Match Options

### sm-match-options

Manage the available match options. See [/docs/matching-options/](../matching-options/)
for documentation of the matching options themselves.

This service supports:

- GET: retrieve a set of matching options
  - parameters:
    - `rs:name` -- the name under which a set of options were stored
- PUT: create or replace a set of matching options
  - parameters:
    - `rs:name` -- the name under which the options are to be stored
    - body of message -- the options, in either XML or JSON format
- POST: identical to PUT

### sm-match-option-names

List the available matching options.

- GET: retrieve the list
  - the names will be returned as a JSON array of string values

## Matching

### sm-match

- POST: identify matches for a particular document
  - parameters
    - `rs:uri` -- the URI of the document for which matches will be identified
    - `rs:options` -- the name under which a set of options were previously
    stored
    - `rs:start` -- (optional) starting index of matches; defaults to 1
    - `rs:pageLength` -- (optional) number of potential matches to return; if
    not provided, the matching options' `max-scan` value will be used. If there
    is no `max-scan` value, defaults to 20.
    - `rs:includeMatches` -- (optional boolean) whether to include, for each
    potential match, the list of properties that were good matches. Defaults to
    `false`. 
    - body of message -- The body may include the following:
      - a content document for which matches will be identified. If XML, there
      must be an XML element with the localname of `document` (namespace is
        ignored). If JSON, there must be a top-level property called `document`.
      - matching options. If XML, there must be an XML element with a QName of
      `matching:options`. If JSON, there must be a top-level property called
      `options`.
  - response
    - The response will be a JSON array of objects representing potential
    matches.
  - usage
    - Either the `rs:uri` parameter or a document in the message body must be
    provided.
    - Either the `rs:options` parameter or a set of options in the message body
    must be provided.

### sm-block-match

Match blocks are used to manually prevent automatic merging of entities that
score highly as matches. Ideally, adjusting the match weights well enough would
solve such problems, but in practice, match blocks are available to handle
outliers.

- GET: retrieve a list of match blocks for a URI
  - parameters
    - `rs:uri` -- find match blocks that include this URI
- POST: create a match block between two URIs
  - parameters
    - `rs:uri1`
    - `rs:uri2`
- DELETE: remove a match block between two URIs
  - parameters
    - `rs:uri1`
    - `rs:uri2`

### sm-notifications

Notifications identify matches that are likely, but did not score high enough
to automatically merge. Notifications should be presented to human users for
review.

- GET: retrieve a paged list of notifications
  - parameters
    - `rs:start` -- optional; integer defaulting to 1
    - `rs:pageLength` -- optional; integer defaulting to 10
- POST: retrieve a paged list of notifications with the option to pass in a configuration  
  - parameters
    - `rs:start` -- optional; integer defaulting to 1
    - `rs:pageLength` -- optional; integer defaulting to 10
    - `post body`  
JSON object with a JSON object of "extractions"  
extractions look like:  
`{ "name": "QName" }`  
<br/>
when run, the value inside the document at QName will be returned  
in a key/value extractions section under the key "name".  
<br/>
example:  
`body => { "firstName", "PersonFirstName" }`  
<br/>
this would extract the value in the PersonFirstName field  
<br/>
`<Person><PersonFirstName>Bob</PersonFirstName><PersonLastName>Smith</PersonLastName></Person>`
<br/>
<br/>
returns:  
`{
  ...
  extractions: {
    "/uri1.xml": {
      "firstName": "Bob"
    }
  }
}`  

- PUT: update the status of a notification
  - body of message: a JSON object with two properties
    - "uris" -- an array of strings with the URIs of notifications to be updated
    - "status" -- new status for the notifications; must be either "read" or
    "unread".
- DELETE: delete a notification
  - parameters
    - `rs:uri` -- the URI of the notification to be deleted

## Merge Options

Merge options control the way property values are combined when producing a new,
merged document based on two or more original documents. For full documentation
of merging options, see the [Merging Options](../merging-options/) page.

### sm-merge-options
Manage the available merge options.

- GET: retrieve a set of merging options
  - parameters:
    - `rs:name` -- the name under which a set of options were stored
- PUT: create or replace a set of merging options
  - parameters:
    - `rs:name` -- the name under which the options are to be stored
  - body of message -- the options, in either XML or JSON format
- POST: identical to PUT

### sm-merge-option-names

List the available merging options.

- GET: retrieve the list
  - the names will be returned as a JSON array of string values

## Merging

### sm-merge

- POST: Save or preview a merge document, combining two or more other documents.
  - parameters
    - `rs:uri` -- (repeated parameter) the URIs of the documents to merge
    - `rs:options` -- the name of the merge options that will control how the
    document properties will be combined
    - `rs:preview` -- optional; if `true`, return the merged document, but do
    not persist it to the database; else save it to the database and return the
    merged document
  - body of message
    - may optionally contain a set of merging options in XML or JSON format
  - usage
    - Either the `rs:options` parameter or a set of options in the message body
    must be provided.

- DELETE: unmerge a previously merged document, restoring the original documents
  - parameters
    - `rs:mergedUri` -- the URI of the merged document
    - `rs:retainAuditTrail` -- optional; if `true`, the merged document will be
    moved to an archive collection; if `false`, the merged document will be
    deleted. Defaults to `true`.

## Match and Merge Together

Rather than calling match and merge functions separately, you can call them 
together on a set of URIs. By doing so, you ensure that both happen in the same
transaction and that the merges are consistent and non-redundant. 

### sm-match-and-merge

- POST: match and merge on a set of documents
  - parameters
    - `rs:uri` -- (repeated parameter) the URIs of the documents to merge
    - `rs:collector-name` -- the local name of a function that will return a 
    list of URIs
    - `rs:collector-ns` -- the namespace of the collector function. Skip this
    for JavaScript
    - `rs:collector-at` -- the URI in the modules database of a library module 
    that holds the collector function
    - `rs:options` -- required; the name of the merge options that will control 
    how the document properties will be combined
    - `rs:query` -- optional; a serialized query that will be used to filter 
    the set documents that are eligible for matching
  - usage
    - Either `rs:uri` or `rs:collector-name` is required. 
    - Queries can be serialized as either [JSON][serial-json] or [XML][serial-xml]. 

[serial-json]: https://docs.marklogic.com/guide/search-dev/cts_query#id_29308
[serial-xml]: https://docs.marklogic.com/guide/search-dev/cts_query#id_92772

## History

Smart Mastering Core tracks the history of what merge and unmerge operations
have been done to a document, as well as which original documents contributed
values to a merged document.

### sm-history-document

- GET: retrieve the activity history of this document
  - parameters
    - `rs:uri` -- the URI of a document in the content database (may be a merged
      document or an original source document)


### sm-history-properties

- GET: retrieve the source for each property in a merged document
  - parameters
    - `rs:uri` -- the URI of a merged document
    - `rs:property` -- zero or more property names (repeat parameter for more
      than one). If none are provided, returns information for all available
      properties.

## Other Services

### mastering-stats

- GET: convenience endpoint to gather some numbers about Smart Mastering data

### sm-dictionaries

- GET: retrieve any dictionaries used by Smart Mastering

### sm-entity-services

- GET: returns Entity Services descriptors present in the content database

### sm-thesauri

- GET: retrieve any thesauri used by Smart Mastering
