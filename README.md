
# Smart Mastering Core

This repo contains the libraries and services for a Smart Mastering capability
built on top of MarkLogic. Smart Mastering consists of matching entities in an
operational data hub, then auto-merging for high-scoring matches and recording 
a notification for a human reviewer for cases where the score indicates a 
possible, but not definite match. Match scoring rules and merging algorithms, 
thresholds and actions are configuration driven. APIs are available either 
through a set of XQuery libraries or a REST service layer. 

This capability is experimental. Be prepared for the interface and 
implementation to change significantly. We welcome your input to guide this 
development process. 

- [Requirements](#requirements)
- [Using](#using)
- [Development](#development)

## Requirements

- MarkLogic 9.0-5 or higher
- Java 8 or higher
- [Gradle](https://gradle.org/) is optional - this project has the Gradle wrapper included, and the instructions below
reference it so that you don't need to install Gradle
- Schemas Database attached to your content DB. This is required for PROV-O to work.

## Using

Documentation on how Smart Mastering Core works and how to use it is available 
at [GitHub][docs].

To use the Smart Mastering Core in your own project, follow these instructions.
This assumes that you're using ml-gradle in your project.

_Note: be advised that this project is in its very early stages. The APIs
presented here may change significantly before stabilizing._

### Examples

To view smart-mastering-core in use, see the [Smart Mastering project examples](examples).

### Need help?

If you've found a bug or would like to ask for a new capability, please [file an
issue here on GitHub][issue tracker]. If you are having trouble using 
smart-mastering-core, you can [file a question issue here on GitHub][issue tracker] 
or [ask a question on Stack Overflow with the "marklogic" tag][stackoverflow]. 
If you'd like to discuss this project with Product Management, contact 
[community-requests@marklogic.com][requests]. 

### Project Status

Smart Mastering Core is a community-supported project. Help is available by 
filing issues here on GitHub and by asking questions on Stack Overflow; 
however, we can’t promise a specific resolution or timeframe for any request. 

### Adding Smart Mastering to your project

Assuming you're using ml-gradle, you can easily integrate Smart Mastering into your application.

As this project hasn't been published to the [jcenter](https://bintray.com/bintray/jcenter) repository yet, you'll first
need to publish a copy of this project to your local Maven repository, which defaults to ~/.m2/repository. 

To do so, clone this repository and run the following command in the project's root directory:

    ./gradlew publishToMavenLocal
    
You can verify that the artifacts were published successfully by looking in the 
~/.m2/repository/com/marklogic/community/smart-mastering-core directory.

Now that you've published Smart Mastering locally, you can add it to your own application. The 
[minimal example project](examples/minimal-project) provides a simple example of doing this. You just need to add 
the following to your build.gradle (again, this depends on using ml-gradle).

First, in the repositories block, make sure you have your local Maven repository listed:

    repositories {
      mavenLocal()
    }

And then just add the following to your dependencies block:

    dependencies {
      mlRestApi "com.marklogic.community:smart-mastering-core:0.1.DEV"
    }

This assumes that the version of the artifacts you published above is 0.1.DEV. You can find the version number by 
looking at the version property in gradle.properties in your cloned copy of smart-mastering-core. 

And that's it! Now, when you run mlDeploy, the modules in Smart Mastering will be automatically loaded into your
modules database. To verify that the modules exist, you can either browse your modules database via qConsole, or you 
can go to your application's REST server and see that the Smart Mastering services have been installed:

    http://localhost:(your REST port)/v1/config/resources 

You can then run ml-gradle tasks such as `mlLoadModules` and `mlReloadModules`, 
and the Smart Mastering modules will again be loaded into your modules database. 

## Development

### Deploy

If necessary, create a `gradle-local.properties` file and override properties in
`gradle.properties` as needed.

Run `./gradlew mlDeploy`

### Testing

#### UI-based
After running `./gradlew mlDeploy`, point a browser to `http://localhost:8042/test`.
Click the `Run Tests` button.

#### Command-line
- `./gradlew mlUnitTest`

### Release

#### Publishing

- update gradle.properties with the new version number
- update the gradle.properties for the examples with the new version number
- update the UPGRADE.md file's version reference to the new version number. Add other upgrade notes as needed. 
- generate the CHANGELOG: `github_changelog_generator --token $my-github-token --future-release v1.0.0`
  - if you don't have a "/tmp/" directory (Windows), add  `--cache-file ~\tmp\github-changelog-http-cache --cache-log ~\tmp\github-changelog-logger.log`
- commit the CHANGELOG
- add these properties to your `gradle-local.properties`
  - bintray_user
  - bintray_key
- change the `version` property in `gradle.properties` to the new version number
- `./gradlew bintrayUpload`
- log in to bintray and push the publish button
- smoke test the examples to make sure they work with the latest published version
- merge the develop branch into master
- merge the docs-next branch into docs
- tag the release vx.xx
- push the tags
- add the changelog to the release page on github

You must be part of the marklogic-community organization on bintray in order to publish.

[issue tracker]: https://github.com/marklogic-community/smart-mastering-core/issues
[sm-demo]: https://github.com/marklogic-community/smart-mastering-demo/tree/develop/examples/smart-mastering
[stackoverflow]: http://stackoverflow.com/questions/ask?tags=marklogic
[requests]: mailto:community-requests@marklogic.com

### How do I uninstall?

`./gradlew mlUndeploy -Pconfirm=true`

[docs]: https://marklogic-community.github.io/smart-mastering-core/
