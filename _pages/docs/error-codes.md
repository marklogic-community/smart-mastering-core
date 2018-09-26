---
layout: inner
title: Error Codes
lead_text: ''
permalink: /docs/error-codes/
---

# Smart Mastering Error Codes

## REST Errors

### sm-block-match
  GET 400 - Bad Request
 : * uri parameter is required

POST 400 - Bad Request
 : * uri1 and uri2 parameters are required

DELETE 400 - Bad Request
 : * uri1 and uri2 parameters are required

### sm-history-document
GET 400 - Bad Request
 : * uri parameter is required

### sm-history-properties
GET 400 - Bad Request
 : * uri parameter is required

### sm-match-options
GET 400 - Bad Request
 : * name parameter is required

POST 400 - Bad Request
 : * name parameter is required

DELETE 405 - Method Not Allowed
 : * DELETE is not implemented

### sm-match
GET 400 - Bad Request
 : * A valid uri parameter or document in the POST body is required
* A valid option parameter or option config in the POST body is required
* Your request included an invalid value for the includeMatches parameter.  A boolean value (true or false) is required

POST 400 - Bad Request
 : * A valid uri parameter or document in the POST body is required
* A valid option parameter or option config in the POST body is required
* Your request included an invalid value for the includeMatches parameter.  A boolean value (true or false) is required

DELETE 405 - Method Not Allowed
 : * DELETE is not implemented

### sm-merge-options
GET 400 - Bad Request
 : * name parameter is required

POST 400 - Bad Request
 : * name parameter is required

DELETE 405 - Method Not Allowed
 : * DELETE is not implemented

### sm-merge
POST 400 - Bad Request
 : * A valid option parameter or option config in the POST body is required
* uri parameter is required

DELETE 400 - Bad Request
 : * mergedUri parameter is required

### sm-notifications
PUT 400 - Bad Request
 : * status parameter is required
* uris parameter is required

PUT 404 - Not Found
 : * No notification available at URI

DELETE 400 - Bad Request
 : * uris parameter is required

DELETE 404 - Not Found
 : * No notification available at URI

## Module Errors
### Merging Module
SM-INVALID-FORMAT
 : Attempted to call merge-impl:get-option-names with invalid format

### Processing Module
SM-NO-MERGING-OPTIONS
 : No Merging Options are present. See: https://marklogic-community.github.io/smart-mastering-core/docs/merging-options/
