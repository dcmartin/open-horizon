# `BUILD.md` - build process automation

## Introduction

This [repository][repository] is built using the following tools: `make`, `git`, `curl`, `jq`, and [`docker`][docker-start].

Services are built using `make` command and a set of targets; see:

+ [`MAKE.md`][make-md]
+ [`MAKEVARS.md`][makevars-md]

[docker-start]: https://www.docker.com/get-started
[cicd-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/CICD.md

## 1. Build control files

Within each directory is a set of files to control the build process:

+ `Makefile` - build configuration and control for `make` command
+ `.travis.yml` - process automation configuration and control for [Travis][travis-ci]
+ `Dockerfile` - a cross-architecture container definition
+ `build.json` - Docker container configuration
+ `service.json` - _service_ configuration template
+ `userinput.json` - variables template for use in testing _service_
+ `pattern.json` - [**optional**] _pattern_ configuration template (see [`PATTERN.md`][pattern-md] for more information).

### 1.1 `Makefile` &  `.travis.yml`

The `Makefile` is shared across all services; it is a symbolic link to a common, shared, [file][service-makefile] in the root of the repository.  The top-level [`makefile`][makefile] invokes targets across service directories.

The [Travis][travis-ci] process automation system for continuous-integration enables the execution of the build process and tools in a cloud environment.  Please see [`TRAVIS.md`][travis-md] for more information.

### 1.2 `Dockerfile` & `build.json`

The `Dockerfile` controls the container build process.  A critical component of that process is the `FROM` directive, which indicates the container from which to build.

The `Dockerfile` also includes information for `LABEL` container information, for example:

```
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.name="cpu" \
    org.label-schema.description="base alpine container" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/master/cpu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
```


The **`build.json`** configuration file provides a mapping for each architecture the _service_ supports.  For example, the Alpine-based LINUX `base-alpine` configuration:

```
{
    "squash": false,
    "build_from": {
        "amd64": "alpine:3.8",
        "arm": "arm32v6/alpine:3.8",
        "arm64": "arm64v8/alpine:3.8",
        "386": null,
        "ppc64": null,
        "ppc64le": null,
        "mips64": null,
        "mips64le": null,
        "s390x": null,
        "mips": null,
        "mipsle": null
    },
    "args": {}
}
```

This example indicates three (3) supported architectures with values: `arm64`, `amd64`, and `arm`, and corresponding Docker container tags. The architecture values must be common across the build automation process and configuration files; it also **effects the building and naming of container images and services**. However, values may be specified as necessary to ensure uniqueness.

**NOTE:** Version attributions for the `BUILD_FROM` target is drawn from version of the parent service, e.g. `version` in the `yolo/service.json` service configuration template value of `0.0.7`; see below:

### `base-ubuntu/build.json`
```
{
  "build_from": {
    "amd64": "ubuntu:bionic",
    "arm": "arm32v7/ubuntu:bionic",
    "arm64": "arm64v8/ubuntu:bionic"
  }
}
```
### `yolo/build.json`
```
{
  "build_from": {
    "amd64": "${DOCKER_REPOSITORY}/amd64_com.github.dcmartin.open-horizon.base-ubuntu:0.0.2",
    "arm": "${DOCKER_REPOSITORY}/arm_com.github.dcmartin.open-horizon.base-ubuntu:0.0.2",
    "arm64": "${DOCKER_REPOSITORY}/arm64_com.github.dcmartin.open-horizon.base-ubuntu:0.0.2"
  }
}
```
### `yolo4motion/build.json`
```
{
  "build_from": {
    "amd64": "${DOCKER_REPOSITORY}/amd64_com.github.dcmartin.open-horizon.yolo:0.0.7",
    "arm": "${DOCKER_REPOSITORY}/arm_com.github.dcmartin.open-horizon.yolo:0.0.7",
    "arm64": "${DOCKER_REPOSITORY}/arm64_com.github.dcmartin.open-horizon.yolo:0.0.7"
  },
}
```

### 1.3 `service.json` & `userinput.json`

The `service.json` configuration template provides standard Open Horizon service metadata and state information, including:

+ `org` - _organization_ in _exchange_
+ `url` - unique identifier for _service_ in organization
+ `version` - semantic version of _service_ [**state**]
+ `arch` - `null` in template; derived from `build.json`

In addition to the standard service configuration semantics and structure, there are three additional modifications:

+ `label` - this value is now used as a token (**non-breaking-string**), aka  _slug_, identifier for the service and _pattern_
+ `ports` - a mapping of service ports to host ports during local execution
+ `tmpfs` - [**optional**] specification for a temporary, in-memory, file-system for use on IoT devices

Ports may be specified for mapping both TCP and UDP, for example:

```
"ports": {
  "8082/tcp": 8082,
  "8080/tcp": 8080,
  "8081/tcp": 8081
}
```

The `tmpfs` specifies whether a temporary file-system should be created in RAM and it's `size` in bytes, `destination` directory (default "/tmpfs"), and `mode` permissions (default `0177`).

```
 "tmpfs": {  "size": 2048000, "destination": "/tmpfs", "mode": "0177" }
```

The `userinput.json` provides configuration for variables defined the _service_ in the `service.json`; this is service dependent.  Variables, including secrets, may also be defined as files with JSON content.  For example, the `yolo2msghub` service's required Kafka API key variable -- `YOLO2MSGHUB_APIKEY` -- would be created from an IBM MessageHub Kafka API key JSON file:

```
% jq '.api_key' {kafka-apiKey-file} > YOLO2MSGHUB_APIKEY
```

## 2. Build support scripts

In addition, there are a set of build support scripts that provide required services for the automated build process; as with the `Makefile`, all scripts are shared across services.

+ `docker-run.sh` - standardized local execution of Docker containers per `service.json` configuration template
+ `mkdepend.sh` - utilizes `hzn` CLI to create build artefacts
+ `checkvars.sh`- process _service_ variables for `userinput.json`
+ `test-service.sh`- test _service_ output (**note:** linked as `test-<service>.sh`)
+ `test.sh` - test harness for processing output from `test-service.sh`
+ `exchange-test.sh` - test _exchange_ for _service_ or _pattern_ pre-requisites; (**note:** linked as `{pattern,service}-test.sh`)
+ `fixpattern.sh` - process _pattern_ configuration template (see [`PATTERN.md`][pattern-md])

### 2.1 `docker-run.sh`

Run the _service_ locally as configured in the template and include all variables, port definitions, temporary file-system, and privilege.  Other parameters currently available for _service_ configuration are _not_ available.

### 2.2 `mkdepend.sh`

Utilize `hzn` CLI to create temporary build directory and process configuration template for _service_.

### 2.3 `checkvars.sh`

Gather variable(s) values as specified in _service_ configuration template, `userinput.json`, or corresponding files in directory.

### 2.4 `test-service.sh` & `test.sh`

Perform a test of the _service_ to support the test-harness (`test.sh`) for any service; the script name is dependent on the _service_ `label`.  All services share a common `'test-service.sh` script, symbolically linked using the service label, e.g. `test-yolo2msghub.sh`.

### 2.5 `service-test.sh` (_aka_ `exchange-test.sh`)

One script with three names for interrogating the _exchange_.  When invoked as `service-test.sh`, which is symbolically linked to `exchange-test.sh`, the _service_ is tested to determine if all required services are up-to-date with respect to organization, architecture, and semantic version number.  Out-of-date service configurations will fail with an error message.

### 2.6 `fixpattern.sh`

Process the _pattern_ configuration template with any additional `TAG` information.  See [`MAKE.md`][make-md] for more information on `TAG`.

### 2.7 `pattern-test.sh` (_aka_ `exchange-test.sh`)

One script with three names for interrogating the _exchange_.  When invoked as `pattern-test.sh`, which is symbolically linked to `exchange-test.sh`, the _pattern_ is tested to determine if all services are up-to-date with respect to organization, architecture, and semantic version number.  Out-of-date pattern configurations will fail with an error message.

[docker-start]: https://www.docker.com/get-started
[make-md]: ../doc/MAKE.md
[makevars-md]: ../doc/MAKEVARS.md
[service-makefile]: ../service.makefile
[makefile]: ../makefile

[travis-md]: ../doc/TRAVIS.md
[design-md]: ../doc/DESIGN.md
[build-md]: ../doc/BUILD.md
[service-md]: ../doc/SERVICE.md
[pattern-md]: ../doc/PATTERN.md
[setup-readme-md]: ../setup/README.md
[travis-yaml]: ../.travis.yml
[travis-ci]: https://travis-ci.org/
[build-pattern-video]: https://youtu.be/cv_rOdxXidA

[yolo-service]: ../yolo/README.md
[hal-service]: ../hal/README.md
[cpu-service]: ../cpu/README.md
[wan-service]: ../wan/README.md
[yolo2msghub-service]: ../yolo2msghub/README.md
[motion2mqtt-service]: ../motion2mqtt/README.md

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/graphs/contributors
[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-cloudplatform.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
