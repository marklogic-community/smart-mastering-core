This is a "bare minimum" Gradle project that depends on MarkLogic Smart Mastering. It shows the least amount of configuration 
necessary to deploy a new application to MarkLogic that includes the Smart Mastering modules.

To try it out, just run the following command - this uses the [Gradle wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html) 
so that you don't need Gradle installed locally (just a JVM, version 1.8 or higher):

    gradle mlDeploy

This deploys a new REST server to port 8800 by default (to change the port or any other property, modify the 
gradle.properties file in this directory). After the deployment is done, go to the following URL:

    http://localhost:8800/v1/config/resources

And you'll see all of the Smart Mastering services deployed, which verifies that this project was able to resolve the
com.marklogic.community:smart-mastering-core dependency and load all of the Smart Mastering modules into your new 
application's modules database. 

The Smart Mastering modules themselves are located under ./build/mlRestApi/smart-mastering-core. The ml-gradle plugin 
handles downloading the modules package from a Maven repository and then ensuring that the modules are loaded as part of
the mlDeploy, mlLoadModules, mlReloadModules, and mlWatch tasks. 
