# `MAKEVARS.md` - variables defined in `make` files

# 1. Manual variables

## `DOCKER_NAMESPACE`

Please specify the appropriate identifier for your container registry; defaults to `whoami`.  This variable should be changed prior to attempting to `push` a Docker image.

## `HZN_ORG_ID`

This variable controls which organization services and patterns are directed.  This variable should be changed prior to attempting to `service-publish` or `pattern-publish`.

## `TAG` & `BUILD_ARCH`

These variables control identification and naming as well as architecture for build:

+ `TAG` - tag, if any, for build artefacts; defaults to empty unless `TAG` file found or specified as environment variable
+ `BUILD_ARCH` -   defined in the `build.json` configuration file

They may be used on the command-line to control the build, for example:

```
% make BUILD_ARCH=arm64 TAG=test publish-service
```
## 1.1 Code signing

These variables indicate the files used for code signing.  These files are generated using the `hzn` command-line-interface and preferably stored in the `open-horizon/` directory.  These keys are necessary for any `service-publish` or `pattern-publish` targets.

+ `PRIVATE_KEY_FILE` - filename of private key for code signing; defaults to `IBM-*.key` or `PRIVATE_KEY_FILE`
+ `PUBLIC_KEY_FILE` - filename of public key for code signing; defaults to `IBM-*.pem` or `PUBLIC_KEY_FILE`

Use the following command with appropriate alternatives; any values are acceptable:

```
hzn key create ${HZN_ORG_ID} ${USER}@${HOST}
mv -f *.key ${HZN_ORG_ID}.key
mv -f *.pem ${HZN_ORG_ID}.pem
```

## 1.2 IBM Cloud API Key

This variable provides the IBM Cloud API key; it is the contents of the `APIKEY` file which itself is derived from`apiKey` if an IBM Cloud API key JSON file is stored in `open-horizon/apiKey.json`  IBM Cloud API keys can be generated and downloaded from the IBM Cloud `IAM` [service][ibm-iam].

[ibm-iam]: http://cloud.ibm.com/iam

+ `APIKEY`- contents of `APIKEY` file; created from `apiKey` in `apiKey.json` 

# 2. Automatic variables

## Service definitions

+ `SERVICE_ORG` - _organization_ for service; defaults to `org` from `service.json`
+ `SERVICE_LABEL` - _label_ for service; defaults to `label` from `service.json`
+ `SERVICE_NAME` - name to use for service artefacts w/ `TAG` if exists; defaults to `SERVICE_LABEL`
+ `SERVICE_VERSION` - semantic version `#.#.#` for service; defaults to `version` from `service.json`
+ `SERVICE_TAG` - identifier for service as recorded in Open Horizon _exchange_
+ `SERVICE_PORT` - status port for service; identified as first entry from `specific_ports` in `service.json`
+ `SERVICE_URI` - unique identifier for _service_ in _exchange_; defaults to `url` from `service.json`
+ `SERVICE_URL` - unique identifier for _service_ in _exchange_ w/ `TAG` if exists; defaults to `SERVICE_URI`
+ `SERVICE_REQVARS` - list of required variables from `service.json`

## Docker

+ `DOCKER_NAMESPACE` - identifier for login to container registry; defaults to output of `whoami`
+ `DOCKER_NAME` - identifier for container; defaults to `${BUILD_ARCH}/${SERVICE_NAME}`
+ `DOCKER_TAG` - tag for container; defaults to `$(DOCKER_ID)/$(DOCKER_NAME):$(SERVICE_VERSION)` 
+ `DOCKER_PORT` - port mapping for local container; from default is first from `ports` in `service.json`

## TEST

These variables control the testing of the _service_ or _pattern_:

+ `TEST_JQ_FILTER` - filter to apply to `jq` command when testing the _service_; defaults to first line of `TEST_JQ_FILTER` file
+ `TEST_NODE_FILTER` - filter to apply when testing nodes; defaults to first line of `TEST_NODE_FILTER` file
+ `TEST_NODE_TIMEOUT` - number of seconds to wait for a node connection
+ `TEST_NODE_NAMES` - list of nodes or contents of file `TEST_TMP_MACHINES`; defaults to `localhost`

```
TEST_JQ_FILTER ?= $(if $(wildcard TEST_JQ_FILTER),$(shell head -1 TEST_JQ_FILTER),)
TEST_NODE_FILTER ?= $(if $(wildcard TEST_NODE_FILTER),$(shell head -1 TEST_NODE_FILTER),)
TEST_TIMEOUT = 10
TEST_NODE_NAMES = $(if $(wildcard TEST_TMP_MACHINES),$(shell cat TEST_TMP_MACHINES),localhost)
```

## BUILD

These variables are complicated and subject to change.

Define `BUILD_FROM` according to `TAG` if and only if the original `BUILD_BASE` is from the same `DOCKER_ID` (i.e. use base images with same `TAG`).

```
BUILD_BASE=$(shell jq -r ".build_from.${BUILD_ARCH}" build.json)
BUILD_ORG=$(shell echo $(BUILD_BASE) | sed "s|\([^/]*\)/.*|\1|")
SAME_ORG=$(shell if [ $(BUILD_ORG) = $(DOCKER_ID) ]; then echo ${DOCKER_ID}; else echo ""; fi)
BUILD_PKG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/\([^:]*\):.*|\1|")
BUILD_TAG=$(shell echo $(BUILD_BASE) | sed "s|[^/]*/[^:]*:\(.*\)|\1|")
BUILD_FROM=$(if ${TAG},$(if ${SAME_ORG},${BUILD_ORG}/${BUILD_PKG}-${TAG}:${BUILD_TAG},${BUILD_BASE}),${BUILD_BASE})
```
