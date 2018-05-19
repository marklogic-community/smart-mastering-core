This is a "bare minimum" Gradle project that depends on smart-mastering-core.

To try it out, first ensure that you've published smart-mastering-core to your local Maven repository. See the
README file in the root of this repository for instructions on doing that.

You'll need to know the version number of smart-mastering-core that you published locally - it defaults to 0.1.DEV. 
Verify that the value in gradle.properties is correct and run a deployment:

    gradle mlDeploy
    
This deploys a new REST server to port 8800 by default. After the deployment is done, go to the following URL:

    http://localhost:8800/v1/config/resources

And you'll see all of the Smart Mastering services deployed, which verifies that this project was able to resolve the
com.marklogic.community:smart-mastering-core dependency and load all of the Smart Mastering modules into your new 
application's modules database. 
