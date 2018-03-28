
# Smart Mastering Core

This repo contains the libraries and services for a Smart Mastering capability 
built on top of MarkLogic. This capability is experimental. 

## Requirements

- MarkLogic 9.0-5 or higher
- gradle

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
