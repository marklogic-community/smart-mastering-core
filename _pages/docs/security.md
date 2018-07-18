---
layout: inner
title: Security
lead_text: ''
permalink: /docs/security/
---

# Security

Installing and running Smart Mastering with the Data Hub Framework requires a 
number of different privileges. While a single, powerful role can hold all 
these privileges and thus do everything, best practice is to use the Principle
of Least Privilege -- only grant what is necessary to accomplish what is 
allowed.

Note that much of the documentation on this page applies to either ml-gradle 
projects generally or to the MarkLogic Data Hub Framework. 

## Creating the Roles and Users

Setup will also require a user with the admin role, or at least a role with 
sufficient privileges to create users and roles. Use the `mlSecurityUsername`
and `mlSecurityPassword` properties in your gradle-local.properties file to 
configure this user. 

## Running Smart Mastering

The [examples/dhf-flow][dhf-flow] and [examples/triggers][triggers] projects 
include the roles and users needed to deploy and run Smart Mastering. There are 
four such roles:

- mdm-admin: this role name is specified in the source code and will have 
update access to merged documents
- mdm-manage: interacts with the Management API to configure the application
- mdm-rest-admin: does most of the work to run a mastering flow
- mdm-user: a role for application users that will have read access to the 
merged documents

If your application users should have both read and update permission on merged
documents, give them both mdm-admin and mdm-user. 

[dhf-flow]: https://github.com/marklogic-community/smart-mastering-core/tree/develop/examples/dhf-flow
[triggers]: https://github.com/marklogic-community/smart-mastering-core/tree/develop/examples/triggers
