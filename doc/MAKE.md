# `MAKE.md` - how to build the software

# &#10071; Requirements

The top-level [makefile][makefile]  by default will `build` and `run` (locally) the containers for each _service_ in this repository, and then `check` each _service_ (see `make check` below).  The build process requires the following tools:

+ `make` - control, build, test automation
+ `git` - software version and branch management
+ `docker` - Docker registries, repositories, and images
+ `travis` - release change management
+ `hzn` - Open Horizon command-line-interface
+ `ssh` - Secure Shell 
+ `jq` - JSON query processing command (&#63743; `brew install jq`)
+ `envsubst` - environment variable substitution command (&#63743; `brew install gettext`)
+ `curl` - **curl** is a tool to transfer data from or to a server (see `man curl`)

Set `DOCKER_NAMESPACE` and `HZN_ORG_ID`


While these services may be built automatically, there are a number of details important for successful development and deployment; refer to [`CICD.md`][cicd-md]

# Build Process

## 1. Service configuration
The _service_ configuration and `make` process is controlled by a few command lines options and three JSON files.   The JSON files are:

+ `build.json` - service supported architectures and `BUILD_FROM` targets
+ `service.json` - service definition including `label`, `org`, `url`, and other information
+ `pattern.json`- information for the _service_ as a _pattern_ of services  [**_optional_**] 

### 1.1 `build.json`
This JSON configuration file maps supported architectures to designated containers from which to build.  For example, the [`cpu`][cpu-service] service supports four architectures:

```
{
    "build_from": {
        "arm64": "arm64v8/alpine:3.8",
        "amd64": "alpine:3.8",
        "arm": "arm32v6/alpine:3.8",
        "i386": "i386/alpine:3.8"
    }
}
```

### 1.2 `service.json`
This JSON configuration file specifies information about the service itself and is used as a template; the build process utilizes the following:

+ `org` - a _string_ for the _organization_ for this service in the _exchange_ 
+ `url` - a _string_ uniquely identifying the service in the _exchange_
+ `label` - a _string_ used for identifying the _service_ in the _organization_
+ `version` - a _string_ representing the [version][semver] of the service

The `label` and `version` values are used in the `make` process to derive other identifiers, e.g. the Docker image `name`; it is **recommended**, but not required, that the `label` be unique within the _organization_.
 
#### 1.2.1`userInput` in `service.json`

The `userInput` specifies values provided to the service as environment variables.  Some services _require_ values to be provided.  During development and testing, required values may be specified through files of the same name.  For example, the `yolo2msghub` service requires `YOLO2MSGHUB_APIKEY` as indicated by its `defaultValue` being `null` (see below and [here][yolo2msghub-service]).


```
"userInput": [
...
 { "name": "YOLO2MSGHUB_APIKEY", "label": "message hub API key", "type": "string", "defaultValue": null },
...
]
```

In this case a file may be created by processing the Kafka API key provided by the IBM [EventStreams][message-hub] service; for example:

```
% jq '.api_key' apiKey.json > YOLO2MSGHUB_APIKEY
```


#### 1.2.1 `ports` in `service.json`
 The `ports` specifies the ports to be mapped _from_ the container to the localhost, e.g. the following maps the service port `80` to the localhost port `8581`.  Both `tcp` and `udp` ports may be specified.  This port mapping is _only_ done when running the service locally (see `make run`).
 
```
 "ports": {  "80/tcp": 8581 }
```

#### 1.2.2 `tmpfs` in `service.json`
The `tmpfs` specifies whether a temporary file-system should be created in RAM and it's `size` in bytes, `destination` directory (default "/tmpfs"), and `mode` permissions (default `0177`).

```
 "tmpfs": {  "size": 2048000, "destination": "/tmpfs", "mode": "0177" }
```

### 1.3 `pattern.json`
This configuration file specifies information about using the _service_ in a pattern with other services for the architectures supported.  If a `pattern.json` files does not exist, the _service_ has not been configured as a _pattern_ and some `make` targets will not succeed.  In addition, before a _pattern_ can be published to an _exchange_, all `requiredServices` as specified in the `service.json` must already be published to the exchange (see `make publish` below).

```
{
  "label": "yolo2msghub",
  "description": "yolo and friends as a pattern",
  "public": true,
  "services": [
    { "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub", "serviceOrgid": "github@dcmartin.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1" } ] },
    { "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.1" } ] },
    { "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.1" } ] }
  ]   
}  
```

### 1.4 `userinput.json`

This configuration file is _not_ used in the build process, but provides a template for specifying the values required to _register_ for this pattern and is used to run the `start` the service (n.b. see `make start`).  The values specified in this file are utilized if there are no corresponding files with the variable name, for example `YOLO2MSGHUB_APIKEY`.

## 2. Dockerfile
The `Dockerfile` contains details on the required operating environment and package installation.  By default, all services are configured to launch `/usr/bin/run.sh` which invokes `/usr/bin/service.sh` to respond to RESTful `GET` for status on its designated port (n.b. default `80`); see the `make check` section below for details.  There should be no need to change this file.

## 3. `make`

The build process is controlled by the `make` command and two files: [`makefile`][makefile] at the top-level and [`service.makefile`][service-makefile], which all _services_ share.  There are many variables in these files, but usually do not require modification (see command-line options); for more information refer to [`MAKEVARS.md`][makevars-md]

The **make** command by **default** performs `build`,`run`,`check`; other available targets:

+ `build` - build container using `build.json` and `service.json`
+ `run` - run container locally; map `ports` as in `service.json`
+ `check` - checks the service locally on mapped port
+ `test` - test the service for conformant JSON status response
+ `push` - push the container to Docker registry; __requires__ `DOCKER_ID` and `docker login`
+ `service-publish` - publish service to _exchange_; __requires__ `hzn` CLI
+ `service-verify` - verify service on exchange; __requires__ `hzn` CLI
+ `service-start` - intiates service and required services locally; __requires__ `hzn` CLI
+ `service-test` - tests the service output using `test-{service}.sh` for conformant payload
+ `pattern-publish` - publish pattern to _exchange_; __requires__ `hzn` CLI
+ `pattern-validate` - validate pattern on exchange; __requires__ `hzn` CLI
+ `clean` - remove all generated artefacts, including running containers and images
+  `distclean` - remove all residuals, including variable and key files

###  3.0 Command-line options
The command line directives are optional, but may be specified to control the architecture and naming of the artefacts.  By default the native architecture is automatically detected and `TAG` is empty.

+ `BUILD_ARCH` - specify the architecture for the build process per `build.json` options
+ `TAG` - a _string_ value appended to _almost_ all artefacts, including Docker images, service `url`, ..

These options may be specified when invoking the `make` command (see below) or statically specified by creating a file with the same name in the top-level directory, e.g. `echo 'experimental' > TAG`)

```
% make BUILD_ARCH=arm64 TAG=experimental
```

### 3.1 `build`
This target builds a local Docker container for the service.  Output from the build is stored in the file `build.out`

### 3.2 `run`
This target runs the local Docker container for the service.

### 3.3 `check`
This target checks the service on its mapped port; see `service.json` for individual services.  For example, the `cpu` service responds on port `8581` with the following payload when `make check` is invoked in the `cpu/` directory.

```
{
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "",
    "host_ips": [
      ""
    ],
    "organization": "",
    "pattern": "",
    "ram": 0
  },
  "date": 1549907345,
  "service": "cpu",
  "hostname": "7a635ad1f814-172017000002",
  "pid": 21,
  "cpu": {
    "date": 1549911546,
    "log_level": "info",
    "debug": false,
    "period": 60,
    "interval": 1,
    "percent": 1.49
  }
}
```

### 3.4 `test`
This target tests the service either locally or when started through `service-start` for a conformant JSON status response; for example:

```
--- MAKE -- testing motion2mqtt-beta
+++ WARN ./test.sh 84592 -- No host specified; assuming 127.0.0.1
+++ WARN ./test.sh 84592 -- No port specified; assuming port 8082
+++ WARN ./test.sh 84592 -- No protocol specified; assuming http
--- INFO ./test.sh 84592 -- Testing http://127.0.0.1:8082 at Mon Feb 25 16:39:34 PST 2019
{"motion2mqtt":{"date":"number","log_level":"string","debug":"boolean","db":"string","name":"string","timezone":"string","mqtt":{"host":"string","port":"string","username":"string","password":"string"},"motion":{"post":"string"},"period":"number","services":["string"],"pid":"number","cpu":"null"},"hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string","string"],"organization":"string","pattern":"string","ram":"number"},"date":"number","service":"string","pattern":"null"}
--- SUCCESS ./test.sh 84592 -- test /Users/dcmartin/GIT/open-horizon/motion2mqtt/test-motion2mqtt.sh returned true
```

### 3.5 `push`
This target pushes the local Docker container to [Docker hub][docker-hub]

## 4. `service-` targets

Please refer to [`SERVICE.md`][service-md] for more information on these targets.

## 5. `pattern-` targets

Please refer to [`PATTERN.md`][pattern-md] for more information on these targets.

# Changelog & Releases

Releases are based on [Semantic Versioning][semver], and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.


## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[build-json]: ../yolo2msghub/build.json
[dcmartin]: https://github.com/dcmartin
[docker-hub]: http://hub.docker.com/
[issue]: https://github.com/dcmartin/open-horizon/issues
[makefile]: ../makefile
[makevars-md]: ../doc/MAKEVARS.md
[message-hub]: https://www.ibm.com/cloud/message-hub
[open-horizon]: http://github.com/open-horizon/
[pattern-md]: ../doc/PATTERN.md
[repository]: https://github.com/dcmartin/open-horizon
[semver]: https://semver.org/
[service-makefile]: ../service.makefile
[service-md]: ../doc/SERVICE.md
[cicd-md]: ../doc/CICD.md
[setup-readme-md]: ../setup/README.md
[yolo2msghub-service]: ../yolo2msghub/service.json
