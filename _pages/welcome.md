---
layout: inner
title: Smart Mastering Framework
lead_text: ''
permalink: /
---

# Smart Mastering Framework

## Integration into MarkLogic Data Hub 5

1.3.1 is our final feature release of Smart Mastering in the Smart Mastering Core repository. As of Data Hub 5.0.0, Smart Mastering is fully integrated into [MarkLogic Data Hub](https://github.com/marklogic/marklogic-data-hub) as a built-in capability, and the recommended way to use the Smart Mastering capability is by [configuring a mastering step](https://docs.marklogic.com/datahub/flows/configure-mastering-step-using-quickstart.html) in Data Hub. Existing users should migrate their Smart Mastering configuration to MarkLogic Data Hub (see [Import Your Smart Mastering Core Projects](https://docs.marklogic.com/datahub/misc/import-smart-mastering-core-projects.html) for instructions). The integration of Smart Mastering into Data Hub offers a variety of benefits, including:

 - Built-in support for orchestrating matching and merging across documents.
 - QuickStart UI for configuration of matching and merging

MarkLogic will continue to invest in Smart Mastering as a built-in capability of Data Hub.

## What is the Smart Mastering Framework?
Smart Mastering is a product feature to match and merge entities in a data hub.
It is a capability within the Data Hub Framework that scores matches and merges
data based on configuration to de-duplicate entities.

Smart Mastering improves the quality of data in an operational data hub,
enabling better data insights.

Smart Mastering supports Agile Data Management as an iterative, integral part of
Data Integration -- not yet another siloed architecture or massive standalone
project.

## How Do I get Started?

See the [`examples/minimal-project`][min-project] directory to see how to
include smart-mastering-core in your project.

To make use of the Smart Mastering functionality, your application can either
call the REST API extensions or import XQuery libraries and call the functions
directly. 

## How Do I Ask a Question or Send Feedback?

### Have a question?
Someone else might have already asked.
1. Look at our [Stack Overflow Questions](https://stackoverflow.com/questions/tagged/marklogic-smart-mastering)
1. Look at our [GitHub Issues](https://github.com/marklogic-community/smart-mastering-core/issues)
1. Still can't find an answer? Use the [#marklogic-smart-mastering tag on StackOverflow](https://stackoverflow.com/questions/ask?tags=marklogic-smart-mastering,marklogic) to ask us.

### Found a bug? Have a comment?
[File an issue on Github](https://github.com/marklogic-community/smart-mastering-core/issues/new) and we will see it.


[min-project]: https://github.com/marklogic-community/smart-mastering-core/tree/master/examples/minimal-project
