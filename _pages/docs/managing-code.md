---
layout: inner
title: Managing Your Code
permalink: /docs/managing-code/
---

# Managing Your Code

You can customize Smart Mastering by implementing custom match functions, actions, and merge functions. These functions 
will be part of your normal application code. 

## Writing

When writing custom functions, you'll need to decide where your functions should be stored. The Smart Mastering 
libraries do not require your functions to be in a particular place; you can store your functions in any module that 
fits into your overall code structure. That said, a common practice is to segment your Smart Mastering custom functions
from other code. If you are using [ml-gradle] to deploy your project, including projects using the 
[Data Hub Framework][dhf], the recommendation is to put your modules under the `src/main/ml-modules/` directory. For 
instance, you might have the following paths:

- src/main/ml-modules/smart-mastering/match/my-match-algorithm-1.xqy
- src/main/ml-modules/smart-mastering/match/my-match-algorithm-2.sjs
- src/main/ml-modules/smart-mastering/action/my-action.sjs
- src/main/ml-modules/smart-mastering/merge/my-merge-algorithm.sjs

Note that this is a recommended structure, not a required one. This layout uses one file for each algorithm function,
but you have the option to group them either all together or by type. For instance, you can create a 
`match-algorithms.sjs`, as long as you give each function a distinct name. 

### XQuery

When writing XQuery functions, you will need to choose a namespace for your library modules. Smart Mastering has no 
special requirements for your namespaces. If you have established a pattern for your applications, you should follow 
that. If you haven't, you could use a pattern such as: 

> http://{company URL}/{project}/smart-mastering/{function}/{algorithm}

For example:

> http://example.com/big-hub/smart-mastering/match/favorite-color

## Using

To make use of your custom functions, you need to deploy them (assuming you are using a modules database) and then 
refer to them in your match or merge options. 

### Deploying

Deploy your Smart Mastering custom functions the same way you deploy the rest of your application code. If you are 
using [ml-gradle], running `gradle mlLoadModules` or `gradle mlReloadModules` will deploy all of your application's 
source code, including your Smart Mastering customizations. (See ml-gradle's documentation on 
[Common Tasks][common tasks].)

### Configuration

To make use of your custom functions, add them to your match or merge options. 

how to point the configuration to modules


[ml-gradle]: https://github.com/marklogic-community/ml-gradle
[common tasks]: https://github.com/marklogic-community/ml-gradle/wiki/Common-tasks
[dhf]: https://marklogic.github.io/marklogic-data-hub/
