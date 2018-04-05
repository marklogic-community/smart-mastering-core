
# Smart Mastering Core

This repo contains the libraries and services for a Smart Mastering capability
built on top of MarkLogic. This capability is experimental.

## Requirements

- MarkLogic 9.0-5 or higher
- gradle

## Using

To use the Smart Mastering Core in your own project, follow these instructions.
This assumes that you're using ml-gradle in your project.

_Note: be advised that this project is in its very early stages. The APIs
presented here may change significantly before stabilizing._

In your project's `build.gradle` file, add this to the `buildscript` section:

```
// Needed for smart-mastering-core dependency until it's available via jcenter()
maven {
  url {"https://dl.bintray.com/marklogic-community/Maven/"}
}
```

In the `configurations` section, add a line with `smartMasteringCore` all by
itself.

In the `dependencies` section, add this:

    smartMasteringCore "com.marklogic.community:smart-mastering-core:0.0.1"

Add this task to unzip the file that you'll get from bintray:

```
task unzip(type: Copy) {
  def zipPath = project.configurations.smartMasteringCore.files.toArray()[0]
  println zipPath
  def zipFile = file(zipPath)
  def outputDir = file("${buildDir}")

  from zipTree(zipFile)
  into outputDir
}
```

Add this task, which will handle deploying the contents of that zip file:

```
task deployCore(type: com.marklogic.gradle.task.client.LoadModulesTask) {
}
```

To make the `deployCore` task work, set `mlModulePaths` in your `gradle.properties`
file. If you already have this property, you can make it a comma-separated
list.

    mlModulePaths=build/ml-modules

Add these top-level statements to connect the task dependencies.

    tasks.deployCore.dependsOn unzip
    tasks.mlLoadModules.dependsOn deployCore
    // This dependsOn ensures that mlDeploy includes the deployCore step and runs it at the right time
    tasks.mlPostDeploy.dependsOn deployCore

## Development

### Deploy

If necessary, create a `gradle-local.properties` file and override properties in
`gradle.properties` as needed.

Run `gradle mlDeploy`

### Testing

#### UI-based
After running `gradle mlDeploy`, point a browser to `http://localhost:8042/test`.
Click the `Run Tests` button.

#### Command-line
- `gradle mlUnitTest`

### Publishing

- add these properties to your `gradle-local.properties`
  - bintray_user
  - bintray_key
- `gradle bintrayUpload`

You must be part of the marklogic-community organization on bintray in order to publish.
