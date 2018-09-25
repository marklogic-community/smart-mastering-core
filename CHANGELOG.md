# Change Log

## [v1.1.0](https://github.com/marklogic-community/smart-mastering-core/tree/v1.1.0) (2018-09-25)
[Full Changelog](https://github.com/marklogic-community/smart-mastering-core/compare/v1.0.0...v1.1.0)

**Closed issues:**

- MDMImport input flow output collections are in upper case [\#140](https://github.com/marklogic-community/smart-mastering-core/issues/140)
- deployMatchOptions FAILED [\#96](https://github.com/marklogic-community/smart-mastering-core/issues/96)

**Merged pull requests:**

- MDM-528 Enhance unit test to verfiy includeMatches option works [\#159](https://github.com/marklogic-community/smart-mastering-core/pull/159) ([ryanjdew](https://github.com/ryanjdew))
- MDM-527: record path in nested property history [\#158](https://github.com/marklogic-community/smart-mastering-core/pull/158) ([dmcassel](https://github.com/dmcassel))
- MDM-535 Check parameters and report errors [\#157](https://github.com/marklogic-community/smart-mastering-core/pull/157) ([ryanjdew](https://github.com/ryanjdew))
- update based on Sprint Review comment [\#156](https://github.com/marklogic-community/smart-mastering-core/pull/156) ([dmcassel](https://github.com/dmcassel))
- Update testing [\#155](https://github.com/marklogic-community/smart-mastering-core/pull/155) ([dmcassel](https://github.com/dmcassel))
- Mdm 526: Fix 500 error when sending match options in POST body [\#154](https://github.com/marklogic-community/smart-mastering-core/pull/154) ([ryanjdew](https://github.com/ryanjdew))
- Update examples in README.md [\#151](https://github.com/marklogic-community/smart-mastering-core/pull/151) ([ryanjdew](https://github.com/ryanjdew))
- Mdm 504 [\#150](https://github.com/marklogic-community/smart-mastering-core/pull/150) ([dmcassel](https://github.com/dmcassel))
- updated for instance path properties [\#149](https://github.com/marklogic-community/smart-mastering-core/pull/149) ([dmcassel](https://github.com/dmcassel))
- Mdm 349: control merging of nested properties [\#148](https://github.com/marklogic-community/smart-mastering-core/pull/148) ([dmcassel](https://github.com/dmcassel))
- \#146 Fix sm-match endpoint to cast rs:includeMatches param properly [\#147](https://github.com/marklogic-community/smart-mastering-core/pull/147) ([aajacobs](https://github.com/aajacobs))
- MDM-492: documenting custom function signatures [\#142](https://github.com/marklogic-community/smart-mastering-core/pull/142) ([dmcassel](https://github.com/dmcassel))
- Mdm 492: send JSON to custom actions instead of XML [\#141](https://github.com/marklogic-community/smart-mastering-core/pull/141) ([dmcassel](https://github.com/dmcassel))
- adding xqdocs to test functions [\#139](https://github.com/marklogic-community/smart-mastering-core/pull/139) ([paxtonhare](https://github.com/paxtonhare))
- updating docs.next with triple merge config info [\#138](https://github.com/marklogic-community/smart-mastering-core/pull/138) ([paxtonhare](https://github.com/paxtonhare))
- adding custom triple merge support [\#137](https://github.com/marklogic-community/smart-mastering-core/pull/137) ([paxtonhare](https://github.com/paxtonhare))
- Mdm 267: adding organizations to dhf-flow example [\#136](https://github.com/marklogic-community/smart-mastering-core/pull/136) ([dmcassel](https://github.com/dmcassel))
- updating readme to mention PROV-O schemas requirement. [\#135](https://github.com/marklogic-community/smart-mastering-core/pull/135) ([paxtonhare](https://github.com/paxtonhare))

## [v1.0.0](https://github.com/marklogic-community/smart-mastering-core/tree/v1.0.0) (2018-08-14)
[Full Changelog](https://github.com/marklogic-community/smart-mastering-core/compare/1.0.0-beta.2...v1.0.0)

**Implemented enhancements:**

- Change sm-merge REST extension to accept more than two URIs [\#120](https://github.com/marklogic-community/smart-mastering-core/issues/120)

**Fixed bugs:**

- property-history returns empty strings for simple JSON fields [\#108](https://github.com/marklogic-community/smart-mastering-core/issues/108)
- sm-match only returns one result, and no matches [\#100](https://github.com/marklogic-community/smart-mastering-core/issues/100)
- sm-history-document returns blank activities [\#99](https://github.com/marklogic-community/smart-mastering-core/issues/99)
- POSTing pseudo-document to sm-match [\#98](https://github.com/marklogic-community/smart-mastering-core/issues/98)
- Not able to add merge configuration using Rest api in minimal-project. [\#82](https://github.com/marklogic-community/smart-mastering-core/issues/82)

**Closed issues:**

- Documentation - Wrong Namespace in Merge Options [\#116](https://github.com/marklogic-community/smart-mastering-core/issues/116)
- node\(\) instead of object-node\(\) [\#102](https://github.com/marklogic-community/smart-mastering-core/issues/102)
- Documentation - required roles [\#40](https://github.com/marklogic-community/smart-mastering-core/issues/40)

**Merged pull requests:**

- use camel case for JSON matching options [\#132](https://github.com/marklogic-community/smart-mastering-core/pull/132) ([dmcassel](https://github.com/dmcassel))
- removing unused algorithms [\#131](https://github.com/marklogic-community/smart-mastering-core/pull/131) ([paxtonhare](https://github.com/paxtonhare))
- MDM-455 [\#130](https://github.com/marklogic-community/smart-mastering-core/pull/130) ([paxtonhare](https://github.com/paxtonhare))
- Ensure consistent object vs array [\#129](https://github.com/marklogic-community/smart-mastering-core/pull/129) ([dmcassel](https://github.com/dmcassel))
- Mdm 338: document JSON options format [\#128](https://github.com/marklogic-community/smart-mastering-core/pull/128) ([dmcassel](https://github.com/dmcassel))
- Fix options as json [\#127](https://github.com/marklogic-community/smart-mastering-core/pull/127) ([dmcassel](https://github.com/dmcassel))
- fixing deadlock with notifications. [\#126](https://github.com/marklogic-community/smart-mastering-core/pull/126) ([paxtonhare](https://github.com/paxtonhare))
- Mdm 395: adding more developer documentation [\#125](https://github.com/marklogic-community/smart-mastering-core/pull/125) ([dmcassel](https://github.com/dmcassel))
- updating parameter [\#124](https://github.com/marklogic-community/smart-mastering-core/pull/124) ([dmcassel](https://github.com/dmcassel))
- Mdm 94 [\#123](https://github.com/marklogic-community/smart-mastering-core/pull/123) ([paxtonhare](https://github.com/paxtonhare))
- fixing mdm-332 [\#122](https://github.com/marklogic-community/smart-mastering-core/pull/122) ([paxtonhare](https://github.com/paxtonhare))
- Mdm 466 [\#121](https://github.com/marklogic-community/smart-mastering-core/pull/121) ([dmcassel](https://github.com/dmcassel))
- Support more complex json [\#119](https://github.com/marklogic-community/smart-mastering-core/pull/119) ([ryanjdew](https://github.com/ryanjdew))
- MDM-451 add telemetry [\#118](https://github.com/marklogic-community/smart-mastering-core/pull/118) ([paxtonhare](https://github.com/paxtonhare))
- fixing json matching. newer version of marklogic no longer match json… [\#117](https://github.com/marklogic-community/smart-mastering-core/pull/117) ([paxtonhare](https://github.com/paxtonhare))
- Mdm 395: documenting the code [\#115](https://github.com/marklogic-community/smart-mastering-core/pull/115) ([dmcassel](https://github.com/dmcassel))
- adding documentation about match results [\#114](https://github.com/marklogic-community/smart-mastering-core/pull/114) ([dmcassel](https://github.com/dmcassel))
- documenting the role requirements [\#113](https://github.com/marklogic-community/smart-mastering-core/pull/113) ([dmcassel](https://github.com/dmcassel))
- Mdm 339: minimal privileges for examples [\#112](https://github.com/marklogic-community/smart-mastering-core/pull/112) ([dmcassel](https://github.com/dmcassel))
- correcting version number [\#111](https://github.com/marklogic-community/smart-mastering-core/pull/111) ([dmcassel](https://github.com/dmcassel))
- fixing build: problem in normalize-value-for-tracing [\#110](https://github.com/marklogic-community/smart-mastering-core/pull/110) ([dmcassel](https://github.com/dmcassel))
- Handle text nodes in history:normalize-value-for-tracing [\#109](https://github.com/marklogic-community/smart-mastering-core/pull/109) ([patrickmcelwee](https://github.com/patrickmcelwee))
- stating that content is expected not to be mixed [\#107](https://github.com/marklogic-community/smart-mastering-core/pull/107) ([dmcassel](https://github.com/dmcassel))
- tests for Ryan's PR [\#106](https://github.com/marklogic-community/smart-mastering-core/pull/106) ([dmcassel](https://github.com/dmcassel))
- adding information about path properties [\#105](https://github.com/marklogic-community/smart-mastering-core/pull/105) ([dmcassel](https://github.com/dmcassel))
- Fix XPath grouping to account for es:info under es:instance [\#104](https://github.com/marklogic-community/smart-mastering-core/pull/104) ([ryanjdew](https://github.com/ryanjdew))
- \#100 \#102 fixed JSON serialization of match results [\#103](https://github.com/marklogic-community/smart-mastering-core/pull/103) ([dmcassel](https://github.com/dmcassel))
- Issue 98 [\#101](https://github.com/marklogic-community/smart-mastering-core/pull/101) ([dmcassel](https://github.com/dmcassel))
- Mdm 348 [\#97](https://github.com/marklogic-community/smart-mastering-core/pull/97) ([dmcassel](https://github.com/dmcassel))
- Mdm 348 [\#95](https://github.com/marklogic-community/smart-mastering-core/pull/95) ([dmcassel](https://github.com/dmcassel))
- mdm 391 - adding docs for custom actions [\#94](https://github.com/marklogic-community/smart-mastering-core/pull/94) ([paxtonhare](https://github.com/paxtonhare))
- mdm 391 [\#93](https://github.com/marklogic-community/smart-mastering-core/pull/93) ([paxtonhare](https://github.com/paxtonhare))
- updating to talk about the optional filtering query [\#92](https://github.com/marklogic-community/smart-mastering-core/pull/92) ([paxtonhare](https://github.com/paxtonhare))
- MDM-403 [\#91](https://github.com/marklogic-community/smart-mastering-core/pull/91) ([paxtonhare](https://github.com/paxtonhare))
- Ignoring dhf-flow gradle-local.properties [\#90](https://github.com/marklogic-community/smart-mastering-core/pull/90) ([rjrudin](https://github.com/rjrudin))
- Feature/minimal project [\#89](https://github.com/marklogic-community/smart-mastering-core/pull/89) ([rjrudin](https://github.com/rjrudin))
- changes happen on develop branch now [\#88](https://github.com/marklogic-community/smart-mastering-core/pull/88) ([dmcassel](https://github.com/dmcassel))
- adding a non-person test [\#86](https://github.com/marklogic-community/smart-mastering-core/pull/86) ([paxtonhare](https://github.com/paxtonhare))
- adding profiling to the dhf-flow example [\#85](https://github.com/marklogic-community/smart-mastering-core/pull/85) ([paxtonhare](https://github.com/paxtonhare))
- MDM-397 [\#84](https://github.com/marklogic-community/smart-mastering-core/pull/84) ([paxtonhare](https://github.com/paxtonhare))
- fixing demos [\#83](https://github.com/marklogic-community/smart-mastering-core/pull/83) ([paxtonhare](https://github.com/paxtonhare))
- Updates [\#81](https://github.com/marklogic-community/smart-mastering-core/pull/81) ([dmcassel](https://github.com/dmcassel))
- adding more comments in the code [\#80](https://github.com/marklogic-community/smart-mastering-core/pull/80) ([dmcassel](https://github.com/dmcassel))

## [1.0.0-beta.2](https://github.com/marklogic-community/smart-mastering-core/tree/1.0.0-beta.2) (2018-06-25)
[Full Changelog](https://github.com/marklogic-community/smart-mastering-core/compare/v1.0.0-beta.1...1.0.0-beta.2)

**Merged pull requests:**

- removing ext from docs [\#79](https://github.com/marklogic-community/smart-mastering-core/pull/79) ([paxtonhare](https://github.com/paxtonhare))
- moving /ext/\* to /\* [\#78](https://github.com/marklogic-community/smart-mastering-core/pull/78) ([paxtonhare](https://github.com/paxtonhare))

## [v1.0.0-beta.1](https://github.com/marklogic-community/smart-mastering-core/tree/v1.0.0-beta.1) (2018-06-22)
[Full Changelog](https://github.com/marklogic-community/smart-mastering-core/compare/v0.0.7...v1.0.0-beta.1)

**Implemented enhancements:**

- Publish and depend on smart-mastering-code like ml-unit-test [\#47](https://github.com/marklogic-community/smart-mastering-core/issues/47)

**Closed issues:**

- Attribution wrong where only one value present [\#32](https://github.com/marklogic-community/smart-mastering-core/issues/32)

**Merged pull requests:**

- a couple of tweaks to the README and build.gradle for example projects [\#77](https://github.com/marklogic-community/smart-mastering-core/pull/77) ([paxtonhare](https://github.com/paxtonhare))
- adding triggers example [\#76](https://github.com/marklogic-community/smart-mastering-core/pull/76) ([paxtonhare](https://github.com/paxtonhare))
- Add dhf flow example [\#75](https://github.com/marklogic-community/smart-mastering-core/pull/75) ([paxtonhare](https://github.com/paxtonhare))
- Mdm 350 [\#74](https://github.com/marklogic-community/smart-mastering-core/pull/74) ([dmcassel](https://github.com/dmcassel))
- ensure that the results are ordered by their index attribute [\#73](https://github.com/marklogic-community/smart-mastering-core/pull/73) ([dmcassel](https://github.com/dmcassel))
- fixing incorrect merge [\#72](https://github.com/marklogic-community/smart-mastering-core/pull/72) ([dmcassel](https://github.com/dmcassel))
- Fix extractions [\#71](https://github.com/marklogic-community/smart-mastering-core/pull/71) ([paxtonhare](https://github.com/paxtonhare))
- Mdm 245 [\#70](https://github.com/marklogic-community/smart-mastering-core/pull/70) ([dmcassel](https://github.com/dmcassel))
- refactoring match response [\#69](https://github.com/marklogic-community/smart-mastering-core/pull/69) ([paxtonhare](https://github.com/paxtonhare))
- Fix build [\#68](https://github.com/marklogic-community/smart-mastering-core/pull/68) ([dmcassel](https://github.com/dmcassel))
- fixing scenario where scores get too high [\#67](https://github.com/marklogic-community/smart-mastering-core/pull/67) ([paxtonhare](https://github.com/paxtonhare))
- Merge locking [\#66](https://github.com/marklogic-community/smart-mastering-core/pull/66) ([dmcassel](https://github.com/dmcassel))
- use image to illustrate matching process [\#65](https://github.com/marklogic-community/smart-mastering-core/pull/65) ([dmcassel](https://github.com/dmcassel))
- updating based on review [\#64](https://github.com/marklogic-community/smart-mastering-core/pull/64) ([dmcassel](https://github.com/dmcassel))
- added note [\#63](https://github.com/marklogic-community/smart-mastering-core/pull/63) ([dmcassel](https://github.com/dmcassel))
- except does not preserve order, but we need that here [\#62](https://github.com/marklogic-community/smart-mastering-core/pull/62) ([dmcassel](https://github.com/dmcassel))
- added how-does-it-work [\#61](https://github.com/marklogic-community/smart-mastering-core/pull/61) ([dmcassel](https://github.com/dmcassel))
- Testing filter queries [\#60](https://github.com/marklogic-community/smart-mastering-core/pull/60) ([dmcassel](https://github.com/dmcassel))
- added reference to zip.xqy [\#59](https://github.com/marklogic-community/smart-mastering-core/pull/59) ([dmcassel](https://github.com/dmcassel))
- adding zip custom matcher with notes [\#58](https://github.com/marklogic-community/smart-mastering-core/pull/58) ([dmcassel](https://github.com/dmcassel))
- added includeMatches parameter for sm-match [\#57](https://github.com/marklogic-community/smart-mastering-core/pull/57) ([dmcassel](https://github.com/dmcassel))
- wrapped cts:walk in a control flag [\#56](https://github.com/marklogic-community/smart-mastering-core/pull/56) ([dmcassel](https://github.com/dmcassel))
- fixing json \<=\> json [\#55](https://github.com/marklogic-community/smart-mastering-core/pull/55) ([paxtonhare](https://github.com/paxtonhare))
- Overview [\#54](https://github.com/marklogic-community/smart-mastering-core/pull/54) ([dmcassel](https://github.com/dmcassel))
- verifying if json works or not [\#53](https://github.com/marklogic-community/smart-mastering-core/pull/53) ([paxtonhare](https://github.com/paxtonhare))
- adding match options page [\#52](https://github.com/marklogic-community/smart-mastering-core/pull/52) ([dmcassel](https://github.com/dmcassel))
- refactored merging functionality [\#51](https://github.com/marklogic-community/smart-mastering-core/pull/51) ([dmcassel](https://github.com/dmcassel))
- moved threshold config to matching options [\#50](https://github.com/marklogic-community/smart-mastering-core/pull/50) ([dmcassel](https://github.com/dmcassel))
- adding function-level comments [\#49](https://github.com/marklogic-community/smart-mastering-core/pull/49) ([dmcassel](https://github.com/dmcassel))
- \#47 Improved publishing and included example of depending on Smart Mastering [\#48](https://github.com/marklogic-community/smart-mastering-core/pull/48) ([rjrudin](https://github.com/rjrudin))
- History bug [\#46](https://github.com/marklogic-community/smart-mastering-core/pull/46) ([dmcassel](https://github.com/dmcassel))
- Fixing MDM-127 [\#45](https://github.com/marklogic-community/smart-mastering-core/pull/45) ([paxtonhare](https://github.com/paxtonhare))
- Refactoring [\#44](https://github.com/marklogic-community/smart-mastering-core/pull/44) ([dmcassel](https://github.com/dmcassel))
- refactored matcher.xqy to separate public API from interface [\#43](https://github.com/marklogic-community/smart-mastering-core/pull/43) ([dmcassel](https://github.com/dmcassel))
- updating files per Legal [\#42](https://github.com/marklogic-community/smart-mastering-core/pull/42) ([dmcassel](https://github.com/dmcassel))
- refactored a function for readability; expanded tests [\#41](https://github.com/marklogic-community/smart-mastering-core/pull/41) ([dmcassel](https://github.com/dmcassel))
- refactoring and added tests [\#39](https://github.com/marklogic-community/smart-mastering-core/pull/39) ([dmcassel](https://github.com/dmcassel))
- Options test [\#38](https://github.com/marklogic-community/smart-mastering-core/pull/38) ([dmcassel](https://github.com/dmcassel))
- refactoring service code to a library [\#37](https://github.com/marklogic-community/smart-mastering-core/pull/37) ([dmcassel](https://github.com/dmcassel))
- Required files [\#36](https://github.com/marklogic-community/smart-mastering-core/pull/36) ([dmcassel](https://github.com/dmcassel))
- Formatting [\#35](https://github.com/marklogic-community/smart-mastering-core/pull/35) ([dmcassel](https://github.com/dmcassel))
- updating README, added CONTRIBUTING [\#34](https://github.com/marklogic-community/smart-mastering-core/pull/34) ([dmcassel](https://github.com/dmcassel))
- \#32 Attribution bug [\#33](https://github.com/marklogic-community/smart-mastering-core/pull/33) ([dmcassel](https://github.com/dmcassel))
- fixing archived merge counts [\#31](https://github.com/marklogic-community/smart-mastering-core/pull/31) ([paxtonhare](https://github.com/paxtonhare))
- Update test [\#30](https://github.com/marklogic-community/smart-mastering-core/pull/30) ([dmcassel](https://github.com/dmcassel))
- Auto block [\#29](https://github.com/marklogic-community/smart-mastering-core/pull/29) ([dmcassel](https://github.com/dmcassel))
- MDM-234 [\#28](https://github.com/marklogic-community/smart-mastering-core/pull/28) ([paxtonhare](https://github.com/paxtonhare))
- Delete multiple [\#27](https://github.com/marklogic-community/smart-mastering-core/pull/27) ([dmcassel](https://github.com/dmcassel))
- Notification status [\#26](https://github.com/marklogic-community/smart-mastering-core/pull/26) ([dmcassel](https://github.com/dmcassel))
- change sm-notifications to include total [\#25](https://github.com/marklogic-community/smart-mastering-core/pull/25) ([dmcassel](https://github.com/dmcassel))
- paging fix [\#24](https://github.com/marklogic-community/smart-mastering-core/pull/24) ([paxtonhare](https://github.com/paxtonhare))
- Revise notfications [\#23](https://github.com/marklogic-community/smart-mastering-core/pull/23) ([dmcassel](https://github.com/dmcassel))

## [v0.0.7](https://github.com/marklogic-community/smart-mastering-core/tree/v0.0.7) (2018-04-20)
**Merged pull requests:**

- incrementing release number [\#22](https://github.com/marklogic-community/smart-mastering-core/pull/22) ([dmcassel](https://github.com/dmcassel))
- Adding notification delete service. [\#21](https://github.com/marklogic-community/smart-mastering-core/pull/21) ([dmcassel](https://github.com/dmcassel))
- Notification service [\#20](https://github.com/marklogic-community/smart-mastering-core/pull/20) ([dmcassel](https://github.com/dmcassel))
- bringing in Ryan Dew's change from the AMT repo [\#19](https://github.com/marklogic-community/smart-mastering-core/pull/19) ([dmcassel](https://github.com/dmcassel))
- adding a test [\#18](https://github.com/marklogic-community/smart-mastering-core/pull/18) ([dmcassel](https://github.com/dmcassel))
- making uri same as id [\#17](https://github.com/marklogic-community/smart-mastering-core/pull/17) ([paxtonhare](https://github.com/paxtonhare))
- incrementing version [\#16](https://github.com/marklogic-community/smart-mastering-core/pull/16) ([dmcassel](https://github.com/dmcassel))
- Block match [\#15](https://github.com/marklogic-community/smart-mastering-core/pull/15) ([dmcassel](https://github.com/dmcassel))
- allowing json requests to work from the java client api [\#14](https://github.com/marklogic-community/smart-mastering-core/pull/14) ([paxtonhare](https://github.com/paxtonhare))
- Fix spacing [\#13](https://github.com/marklogic-community/smart-mastering-core/pull/13) ([dmcassel](https://github.com/dmcassel))
- adding tests and a comment [\#12](https://github.com/marklogic-community/smart-mastering-core/pull/12) ([dmcassel](https://github.com/dmcassel))
- enhancing dashboard status MDM-171 [\#11](https://github.com/marklogic-community/smart-mastering-core/pull/11) ([paxtonhare](https://github.com/paxtonhare))
- use the target weight instead of zero [\#10](https://github.com/marklogic-community/smart-mastering-core/pull/10) ([dmcassel](https://github.com/dmcassel))
- updating search options and adding search results transform [\#9](https://github.com/marklogic-community/smart-mastering-core/pull/9) ([paxtonhare](https://github.com/paxtonhare))
- Renaming [\#8](https://github.com/marklogic-community/smart-mastering-core/pull/8) ([dmcassel](https://github.com/dmcassel))
- bumping for 0.0.3 release [\#7](https://github.com/marklogic-community/smart-mastering-core/pull/7) ([dmcassel](https://github.com/dmcassel))
- adding transform to return the es instance as json [\#6](https://github.com/marklogic-community/smart-mastering-core/pull/6) ([paxtonhare](https://github.com/paxtonhare))
- bumping to 0.0.2 [\#5](https://github.com/marklogic-community/smart-mastering-core/pull/5) ([dmcassel](https://github.com/dmcassel))
- adding mastering-stats service [\#4](https://github.com/marklogic-community/smart-mastering-core/pull/4) ([dmcassel](https://github.com/dmcassel))
- improving directions [\#3](https://github.com/marklogic-community/smart-mastering-core/pull/3) ([dmcassel](https://github.com/dmcassel))
- Adding usage instructions [\#2](https://github.com/marklogic-community/smart-mastering-core/pull/2) ([dmcassel](https://github.com/dmcassel))
- adding services code [\#1](https://github.com/marklogic-community/smart-mastering-core/pull/1) ([dmcassel](https://github.com/dmcassel))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*