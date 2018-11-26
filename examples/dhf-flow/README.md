# Data Hub Framework Flow Example

This example shows you how to integrate Smart Mastering with your Data Hub Flows.

## Setup

### Configure Users (if necessary)

This project is set up to create a few roles and users with minimal privileges. 
To override the passwords set in **gradle.properties**, create a file called 
**gradle-local.properties** in the same directory as this README file. In that
file, add these lines:

```
mlSecurityUsername=admin
mlSecurityPassword=admin

mlUsername=mdm-user
mlPassword=mdm-user

mlRestAdminUsername=mdm-rest-admin
mlRestAdminPassword=mdm-rest-admin

mlAppAdminUsername=mdm-admin
mlAppAdminPassword=mdm-admin

mlManageUsername=mdm-manage
mlManagePassword=mdm-manage
```

The `mlSecurityUsername` user is used to create the other users and roles, so 
it must have the `admin` role or the `security` and `manage-admin` roles, 
provided with MarkLogic. 

Change the `mlSecurityPassword` to match your `admin` user password. 

To change the usernames or passwords for the other users, change them both in
**gradle-local.properties** and in **user-config/security/users/*.json**. 

### Run the Setup Command

- Open a Terminal or Command Prompt into this folder
- Setup the Example  
  **\*nix:** `./gradlew setupExample`  
  **windows:** `gradlew.bat setupExample`  

You have just installed a Data Hub Project into MarkLogic. You also loaded 3 data sets and harmonized them. If none of that makes sense, check out our [Data Hub Framework documentation](https://marklogic.github.io/marklogic-data-hub/).

## Mastering your Data

This example runs the `sm-match-and-merge` REST endpoint via a Gradle task and uses the collector included in Smart Mastering.

### Running via Gradle

- Open a Terminal or Command Prompt into this folder
- Run the Harmonize Flow  
  **\*nix:** `./gradlew runMastering`
  **windows:** `gradlew.bat runMastering`

### What did I just do?

You just ran a Gradle task which runs a REST endpoint from the Smart Mastering code library: [sm-match-and-merge](https://marklogic-community.github.io/smart-mastering-core/docs/rest/#sm-match-and-merge).

If you like, you can read up on [how Smart Mastering works](https://marklogic-community.github.io/smart-mastering-core/how-does-it-work/).

All the other code in this project is necessary for a functioning Data Hub. We've purposely trimmed it down to bare essentials so you can focus on the Harmonization piece.

### Profiling this example

There are two profiling mechanisms available in this project. The first is the
built-in gradle profiler:

```
gradle --profile runMastering
```

This will write an HTML profile report to 
`./build/reports/profile/profile-$DATETIME.html`.

There's also a custom profiling class that prints per-task execution time to
the terminal:

```
gradle -Pprofile runMastering
```
