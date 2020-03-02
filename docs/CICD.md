# `CICD.md` - CI/CD for Open Horizon
This document provides an introduction to the process and tooling utilized in this [repository][repository] to achieve continuous integration and delivery of [Open Horizon][open-horizon] services and patterns to the edge.  The CI/CD process demonstrated in this repository enables the automated building, testing, pushing, publishing, and deploying edge fabric services to devices for the purposes of development and testing.  Release management and production deployment are out-of-scope.

Open Horizon edge fabric provides method and apparatus to run multiple Docker containers on edge nodes.  These nodes are LINUX devices running the Docker virtualization engine, the Open Horizon edge fabric client, and registered with an Open Horizon exchange.  The edge fabric enables multiple containers, networks, and physical sensors to be woven into a pattern designed to meet a given need with a set of capabilities.  The only limitation of the fabric are the edge devices' capabilities; for example one device may have a camera attached and another may have a GPU.

<hr>

##  &#10071; Intended Audience
It is presumed that the reader is a software engineer with familiarity in the following:

+ **LINUX** - The free, open-source, UNIX-like, operating system, e.g. [Ubuntu][get-ubuntu] or [Raspbian][get-raspbian]
+ **HTTP** - The HyperText Transfer Protocol and tooling; see [here][curl-intro] and [here][socat-intro]
+ **Make** - Build pipeline automation; see [here][gnu-make]
+ **Git** - Software change management; [github.com](http://github.com)
+ **Travis** - Continuous integration and deployment; [travis-ci.org](http://travis-ci.org)
+ **JSON** - JavaScript Object Notation and tooling

Within the following scenario:

+ A single developer
+ One (1) Docker registry with one (1) namespace
+ One (1) Open Horizon exchange with one (1) organization
+ Public [github.com](http://github.com), [docker.io](http://hub.docker.com), [travis-ci.org](http://travis-ci.org), and [microbadger.com][microbadger]
+ One (1) repository with three (3) branches:

	+ `master` - the stable and clean branch; push/publish to _production_ exchange and registry
	+ `develop` - the integration and QA branch; push/publish to _staging_ exchange/registry
	+ `exp` - the feature development and testing branch; private to developer; push/publish to _developer_ exchange/registry

Please refer to [`TERMINOLOGY.md`][terminology-md] for important terms and definitions.

## &#10004; What Will Be Learned

The reader will learn how to perform the following:


A. Setup environment

 + Copy, configure, and use a Git repository
 + Configure for Docker and Open Horizon

B. Build and test services and patterns

 + Build, test, and publish  _service_: { `cpu`,`hal`,`wan`,`yolo`,`yolo2msghub` }
 + Publish and test _pattern_: `yolo2msgub`

C. Change management practices

 + Setup a _branch_
 + Update a _service_
 + Update a _pattern_
 + Merge a _branch_

D. Automate build process

 + Setup, configure, and use  Travis CI

E. MarkDown repository 

 + Add TravisCI build status
 + Add Docker container status

<hr>
 
# Process
The CI/CD process utilizes the the following:

**command-line-interface tools**

+ `make` - control, build, test automation
+ `git` - software version and branch management
+ `docker` - Docker registries, repositories, and images
+ `hzn` - Open Horizon command-line-interface
+ `ssh` - Secure Shell 
+ `travis` - release change management (&#63743; `brew install travis`; &#128039; `apt-get install -y travis`)
+ `git-flow` - Automated GIT flow command extensions (&#63743; `brew install git-flow`; &#128039; `apt-get install -y git-flow`)
+ `jq` - JSON query processing command (&#63743; `brew install jq`; &#128039; `apt-get install -y jq`)
+ `curl` - **curl** is a tool to transfer data from or to a server (see `man curl`)
+ `envsubst` - environment variable substitution command (&#63743; `brew install gettext`; &#128039; `apt-get install -y gettext`)

**configuration files**

1. `~/.docker/config.json` - Docker configuration, including registries and authentication
2. `registry.json` - IBM Cloud Container Registry configuration (see [`REGISTRY.md`][registry-md])
3. `apiKey.json` - IBM Cloud platform API key

**control attributes**

+ `DOCKER_NAMESPACE` - identifies the collection of repositories, e.g. `dcmartin`
+ `DOCKER_REGISTRY` - identifies the SaaS server, e.g. `docker.io`
+ `DOCKER_LOGIN` - account identifier for access to registry
+ `DOCKER_PASSWORD` - password to verify account in registry
+ `HZN_ORG_ID` - organizational identifier for Open Horizon edge fabric exchange
+ `HZN_EXCHANGE_URL` - identifies the SaaS server, e.g. `alpha.edge-fabric.com`
+ `HZN_EXCHANGE_APIKEY` - API key for exchange server, a.k.a. IBM Cloud Platform API key

The process is designed to account for multiple branches, registries, and exchanges being utilized as part of the build, test, and release management process.  This [repository][repository] is built as an example implementation of this CI/CD process.  Each of the services is built using a similar [design][design-md] that utilizes a common set of `make` files and support scripts.  For more information refer to [`MAKEVARS.md`][makevars-md]

<hr>

# A. Setup

## Step 1
With the assumption that `docker` has already been installed; if not refer to these [instructions][get-docker].

```
wget -qO - ibm.biz/get-horizon | sudo bash
```
**Note**: only the `hzn` command-line-interface tool is installed for macOS

## Step 2
Create a [Github][github-com] account; login and create a [fork][forking-repository] of this [repository][repository].


This repository has the following default build variables which should be changed:

+ `GITHUB` - the namespace of the github.com repository, e.g. `dcmartin`
+ `DOCKER_NAMESPACE` - the identifier for the registry; for example, the _userid_ on [hub.docker.com][docker-hub]
+ `HZN_ORG_ID` - organizational identifier in the Open Horizon exchange; for example: `<userid>@cloud.ibm.com`

Set those environment variables (and `GD` for the _Git_ working directory) appropriately:

```
export GD=~/gitdir
export GITHUB=
export DOCKER_NAMESPACE=
export HZN_ORG_ID=
```

Use the following instructions (n.b. [automation script][clone-config-script]) to clone and configure this repository; uses Docker hub as the default registry and the default Open Horizon exchange.

```
mkdir -p $GD
cd $GD
git clone http://github.com/${GITHUB}/open-horizon
cd open-horizon
echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE
echo "${HZN_ORG_ID}" > HZN_ORG_ID
```

Creating the `DOCKER_NAMESPACE` and `HZN_ORG_ID` files will ensure persistence of build configuration.

**NOTE**: If using [IBM Container Registry][registry-md] and the `./open-horizon/registry.json` file exists, the Docker registry configuration therein will be utilized.


## Step 3 - Create IBM Cloud API key file
Visit the IBM Cloud [IAM][iam-service] service to create and download a platform API key; copy the downloaded `apiKey.json` file into the `open-horizon/` directory; for example:

[iam-service]: https://cloud.ibm.com/iam

```
cp -f ~/Downloads/apiKey.json $GD/open-horizon/apiKey.json 
```

## Step 4 - Create code-signing key files
Create a private-public key pair for encryption and digital signature:

```
cd $GD/open-horizon/
rm -f *.key *.pem
hzn key create ${HZN_ORG_ID} $(whoami)@$(hostname)
mv -f *.key ${HZN_ORG_ID}.key
mv -f *.pem ${HZN_ORG_ID}.pem
```

[clone-config-script]: ../scripts/clone-config.txt

## &#9989; Finished
The resulting `open-horizon/` directory contains all the necessary components to build a set of service, a deployable pattern, and a set of nodes for testing.

## &#10033; Optional: _alternative registry_
Refer to the [`REGISTRY.md`][registry-md] instructions for additional information on utilizing the IBM Cloud Container Registry.

[registry-md]: ../docs/REGISTRY.md

# B. Build
Services are organized into subdirectories of `open-horizon/` directory and all share a common [design][design-md]. Please refer to [`BUILD.md`][build-md] for details on the build process. 

Two base service containers are provided; one for Alpine with its minimal footprint, and one for Ubuntu with its support for a wide range of software packages.

1. [`base-alpine`][base-alpine] - a base service container for Alpine LINUX
2. [`base-ubuntu`][base-ubuntu] - a base service container for Ubuntu LINUX

The `cpu`,`hal`,`wan`, and `mqtt` services are Alpine-based and of minimal size.
The `yolo` and `yolo2msghub` services are Ubuntu-based to support YOLO/Darknet and Kafka, respectively.

## Examples

The containers built and pushed for these two services are utilized to build the remaining samples:

1. [`cpu`][cpu-service] - a cpu percentage monitor
2. [`hal`][hal-service] - a hardware-abstraction-layer inventory
3. [`wan`][wan-service] - a wide-area-network monitor
4. [`yolo`][yolo-service] - the `you-only-look-once` image entity detection and classification tool
5. [`yolo2msghub`][yolo2msghub-service] - uses 1-4 to send local state and entity detection information via Kafka

Each of the services may be built out-of-the-box (OOTB) using the `make` command.  Please refer to [`MAKE.md`][make-md] for additional information.

## Step 1
After copy and configuration of repository, build and test all services.

**Change to the Git working directory:**

```
cd $GD/open-horizon
```

**Build services for supported architectures.**  The default [`make`][make-md] target is to `build`, `run`, and `check` the service's container using the development host's native architecture (e.g. `amd64`).   A single architecture may be built with `build-service` which reports `build` output (n.b. `build` is silent).

```
make service-build
```

**Test services for supported architectures.**  The services' containers status outputs are **tested using the  [`jq`][json-intro-jq] command** and the first uncommented line from the `TEST_JQ_FILTER` file.  Some services require time to initialize; subsequent requests produce complete status.

```
make service-test
```

## Step 2 (_optional_)
Services require their Docker container images to be _pushed_ to the Docker registry.  Once a Docker container has been built, it may be pushed to a registry.  Services typically support more than one architecture.  A single architecture may be pushed with `push-service` or simply `push`.

**Push containers for supported architectures.**

```
make service-push
```

## Step 3
**Publish services in the exchange**. Automaticallly pushes the local containers and publishes those references into the exchange.

```
make service-publish
```
And then verify:

```
make service-verify
```

## Step 4
**Publish the `yolo2msghub` pattern**.  Records the pattern configuration file referencing the services.

```
make pattern-publish
```

And then validate:

```
make pattern-validate
```

## &#9989; Finished
All services and patterns have been published in the Open Horizon exchange and all associated Docker containers have been pushed to the designated registry.

For more information on building services, see [`SERVICE.md`][service-md].

# C. Change
The build process is designed to process changes to the software and take actions, e.g. rebuilding a service container.  To manage change control this process utilizes the `git` command in conjunction with a SaaS (e.g. `github.com`).

<hr>

# &#9888; WARNING

The namespace and version identifiers for Git do not represent the namespaces, identifiers, or versions used by either Docker or Open Horizon.  **To avoid conflicts in identification of containers, services, and patterns multiple Docker registries & namespaces and Open Horizon exchanges & organizations should be utilized.**


**For a single developer using a single registry, namespace, exchange, and organization** it is necessary to distinguish between containers, services, and patterns.  The `TAG` value is used to modify the container, service, and pattern identifiers in the configuration templates and build files.  In addition, the `build.json` file values are also decorated with the `TAG` value when from the same Docker registry and namespace.


### &#9995; Use `TAG` 
The value may be used to indicate a branch or stage;  for example development (`develop`) or staging (`master`). An`open-horizon/TAG` that distinguishes the `develop` branch would be created with the following command:

```
echo 'develop' > $GD/open-horizon/TAG
```

<hr>

## Step 1
The the most basic CI/CD process consists of the following activities (see [Git Basics][git-basics]):

1. Create branch (e.g. `develop`) of _parent_ (e.g. `master`)
1. Develop on `develop` branch
1. Merge `master` into `develop` and test
2. Commit `develop`
2. Merge `develop` into `master` and test
1. Commit `master`
2. Build, test, and deliver `master`

**Create branch.**  A branch requires a _name_ for identification; provide a string with no whitespace or special characters:

```
git branch develop
```

**Identify branch** A branch can be identified using the `git branch` command; an asterisk (`*`) indicates the current branch.
```
% git branch
  develop
* master
```

**Switch branch** Switch between branches using `git checkout` command:

```
% git checkout develop

Switched to branch 'develop'
Your branch is up to date with 'origin/master'.
% git branch
* develop
  master
```

## Step 2
**Change the service**.  Create a change in one of the repository's services and then build, test, and repeat until the change works as intended.

## Step 3
**Merge `master` branch into `develop`**.  Prior to merging a branch into a parent, any updates to the parent should be pulled into the branch and merge appropriately.  Build and test processes may then be applied either manually or automatically.

```
% git checkout develop
% git pull origin master
% make service-build && make service-test
```

## Step 4
**Merge `develop` branch into `master`**.  Once the branch has been successfully tested (and approved if submitted through _pull request_), the branch may be merged.  For example, merging the `develop` branch back into `master`:

```
% git checkout master
% git pull origin master
% git merge develop
% make service-build && make service-test && && make service-publish
% git commit -m "develop good" . && git push
```

## Step 5
**Test services as pattern.** After services have been published, patterns may be tested on an appropriate node(s), identified in the `TEST_TMP_MACHINES` file; one device per line.

 The `yolo2msghub` _service_ is also configured as a _pattern_ that can be deployed for testing.  The pattern instantiates the `yolo2msgub` service and its four (4) `requiredServices`: {`cpu`,`hal`,`wan`, and `yolo`} on nodes which _register_ for the service.  Please refer to [`PATTERN.md`][pattern-md] for information on creating and deploying nodes.

 If the development host is also configured as a node, it may be used to run the pattern test.

```
cd $GD/yolo2msghub
echo 'localhost' > TEST_TMP_MACHINES
make nodes
make nodes-test
```

## Step 6
If tests are successful, the services and patterns may be pushed for "stable" (aka `master`):

```
% git checkout develop
% git pull origin master
% make service-build && make service-test \
  && git commit -m "merge develop" . \
  && git push origin master \
  || echo "FAILED"
```

## &#9989; Finished
Services and pattern have been updated in both Docker registry and Open Horizon exchange.

# D. Automate
Automation of these steps utilizes the public [Travis-CI][travis-ci] system to run jobs in conjunction with changes to Git.  Please refer to [`TRAVIS.md`][travis-md] for more information.

## Step 1
Create a [Travis-CI][travis-ci] account; login with github.com credentials.  Enable the fork of this repository.

![travis-repo-enable.png](travis-repo-enable.png?raw=true "travis-repo-enable")


## Step 2
Change settings in Travis to specify the appropriate control variables as environment variables:

+ `DOCKER_LOGIN`
+ `DOCKER_NAMESPACE`
+ `DOCKER_PASSWORD`
+ `HZN_EXCHANGE_APIKEY`
+ `HZN_ORG_ID`

The keys required for signing need to be specified in BASE64 encoding; to create the appropriate values, encode the key files:

```
base64 ./open-horizon/${HZN_ORG_ID}.key > PRIVATE_KEY
base64 ./open-horizon/${HZN_ORG_ID}.pem > PUBLIC_KEY
```

And copy and paste those values in the following Travis settings environment variables:

+ `PRIVATE_KEY`
+ `PUBLIC_KEY`

The resulting screen should appear as follows:

![travis-settings.png](travis-settings.png?raw=true "travis-settings")


## Step 3
The Travis configuration file is stored in the Git repository and is used to control the jobs.  No changes should be required.  The relevant sections for CI/CD process:

+ `branch`
+ `env`
+ `addons`
+ `before_script`
+ `script`
+ `after_success`

#### `branch`
Controls where and when jobs will be executed; the configuration for this repository only executes on the `master` branch.

```
branches:
  only:
    - master
```

#### `env`
This directive indicates the environments which should be created for the job; each environment will be run in parallel up to the limits imposed by TravisCI (n.b. default `5`).  All supported architectures for all services should be specified.  Additional control variables, e.g. `DEBUG=true` may be specified, for example:

```
env:
  - BUILD_ARCH=amd64
  - DEBUG=true BUILD_ARCH=arm64
  - DEBUG=true BUILD_ARCH=arm
```

#### `addons`
The software requirements for the build process are installed using an `apt` directive, including the additional `sourceline` and `key_url` for Open Horizon (aka `bluehorizon`).

#### `before_script`
After installation and prior to script execution; check the branch and only set secret environment variables when _not_ processing a pull request.  QEMU emulation is also enabled for non-native jobs.

#### `script`
This section of the YAML file is the actual job; in this instance build and test the service; note that only one architecture is built per job.

```
script:
  - make build-service && make test-service
```

#### `after_success`
If the job is successful, these additional command will push and publish the service as well as publish the pattern.  If all the services has not been built successful, pattern publishing will fail.

```
after_success:
  - make publish-service && make pattern-publish
```

## &#9989; Finished
Travis has been configured to build the `open-horizon` repository; any commits to the `master` branch will trigger automated build, test, push, and publish for the services in this repository, should all make targets succeed.

# E. MarkDown
To appropriately inform consumers of the repository status can be indicated by using _badges_.  There are two primary badges used to describe this repository.  **THIS ONLY WORKS FOR PUBLIC REPOSITORIES**

+ Travis build status - obtained from travis-ci.org (e.g. `https://travis-ci.org/dcmartin/open-horizon`)
+ Container statistics - obtained from hub.docker.com

The badges issued by these services provide information in the form of small icons, e.g. the following icon indicates this repository's build status:

## Travis Status
```
[![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)
```

[![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)

## Container Status
Information about the container is available, but _only_ after the image has been registered on the site.  Visit [`microbadger.com`](http://microbadger.com), create an account and link to the appropriate containers.  For example, the `cpu` containers are referenced by their Docker registry's namespace and tag; an addition badge for pulls is provided by [`shields.io`](http://shields.io).

```
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu "Get your own version badge on microbadger.com")
[![](https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu.svg)](https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu)
```

[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu "Get your own version badge on microbadger.com")
[![](https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu.svg)](https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.cpu)

<hr>

# Next Step - `hello` world
When this document has been read and understood, take the next step and create a new service, the "[hello world][helloworld-md]" example.

[helloworld-md]: ../docs/HELLO_WORLD.md

<hr>

# Appendix A - Example MicroBadger

![microbadger.png](microbadger.png?raw=true "microbadger")

# Appendix B - Example Travis Screens

## B.1 - Travis Dashboard View
![travis-dashboard.png](travis-dashboard.png?raw=true "travis-dashboard")

## B.2 - Travis Repository View
![travis-repo.png](travis-repo.png?raw=true "travis-repo")

<hr>

# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

## MAP

![](http://clustrmaps.com/map_v2.png?cl=919191&w=1024&t=n&d=rCz509nZFssTCzPTGmATxaAmIiEXvfR5tQ58XfvQ0Rs&co=ffffff&ct=808080)

[base-alpine]: ../base-alpine/README.md
[base-ubuntu]: ../base-ubuntu/README.md
[build-md]: ../docs/BUILD.md
[cpu-service]: ../cpu/README.md
[curl-intro]: https://www.maketecheasier.com/introduction-curl/
[design-md]: ../docs/DESIGN.md
[docker-hub]: http://hub.docker.com
[forking-repository]: https://github.community/t5/Support-Protips/The-difference-between-forking-and-cloning-a-repository/ba-p/1372
[get-docker]: https://docs.docker.com/install/
[get-raspbian]: https://www.raspberrypi.org/downloads/raspbian/
[get-ubuntu]: https://www.ubuntu.com/download
[git-basics]: https://gist.github.com/blackfalcon/8428401
[git-branch-merge]: https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging
[git-pull-request]: https://help.github.com/en/articles/creating-a-pull-request
[github-com]: http://github.com
[gnu-make]: https://www.gnu.org/software/make/
[hal-service]: ../hal/README.md
[herald-service]: ../herald/README.md
[hzncli]: ../hzncli/README.md
[jetson-caffe-service]: ../jetson-caffe/README.md
[jetson-cuda]: ../jetson-cuda/README.md
[jetson-digits]: ../jetson-digits/README.md
[jetson-jetpack]: ../jetson-jetpack/README.md
[jetson-opencv]: ../jetson-opencv/README.md
[jetson-yolo-service]: ../jetson-yolo/README.md
[json-intro-jq]: https://medium.com/cameron-nokes/working-with-json-in-bash-using-jq-13d76d307c4
[make-md]: ../docs/MAKE.md
[makevars-md]: ../docs/MAKEVARS.md
[microbadger]: https://microbadger.com/
[motion2mqtt-service]: ../motion2mqtt/README.md
[mqtt-service]: ../mqtt/README.md
[mqtt2kafka-service]: ../mqtt2kafka/README.md
[open-horizon-examples-github]: http://github.com/open-horizon/examples
[open-horizon-github]: http://github.com/open-horizon
[open-horizon]: http://github.com/open-horizon
[pattern-md]: ../docs/PATTERN.md
[repository]:  https://github.com/dcmartin/open-horizon
[service-md]: ../docs/SERVICE.md
[socat-intro]: https://medium.com/@copyconstruct/socat-29453e9fc8a6
[terminology-md]: ../docs/TERMINOLOGY.md
[travis-ci]: http://travis-ci.org/
[travis-md]: ../docs/TRAVIS.md
[wan-service]: ../wan/README.md
[yolo-service]: ../yolo/README.md
[yolo2msghub-service]: ../yolo2msghub/README.md
[yolo4motion-service]: ../yolo4motion/README.md
