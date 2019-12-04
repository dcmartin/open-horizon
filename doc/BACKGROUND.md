# `BACKGROUND.md` - background for CICD process

## A. Introduction

The expectations of this process is to automate the development, testing, and deployment processes for edge fabric patterns and their services across a large number of devices.  The primary objective is to:

+ __eliminate failure in the field__

A node that is currently operational should not fail due to an automated CI/CD process result.

The key success criteria are:
 
1. __stage everything__ - all changes to deployed systems should be staged for testing prior to release
1. __enforce testing__ - all components should provide interfaces and cases for testing
1. __automate everything__ - to the greatest degree possible, automate the process

### Stage everything
The change control system for this repository is Git which provides mechanisms to stage changes between various versions of a repository.  These versions are distinguished within a repository via branching from a parent (e.g. the trunk or _master_ branch) and then incorporating any changes through a _commit_ back to the parent.  The _push_ of the change back to the repository may be used to evaluate the state and determine if a _stage_ is ready for a build to be initiated.  

### Enforce testing
Staged changes require testing processes to automate the build process.  Each service should conform to a standard test harness with either a default or custom test script.  Standardization of the testing process enables replication and re-use of tests for the service and its required services, simplifying testing.  Additional standardization in testing should be extended to API coverage through utilization of Swagger (n.b. IBM API Connect).

### Automate everything
A combination of tools enables automation for almost every component in the CI/CD process.  However, certain activities remain the provenance of human review and oversite, including _pull requests_ and _release management_.  In addition, modification of a service _version_ is _not_ dependent on either the Git or Docker repository version information.
