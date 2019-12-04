# `SERVICE.md` - _Service_ build process automation

# Services
Open Horizon edge fabric services compose one or more Docker containers along with other required services connected with point-to-point virtual-private-networks (VPN). 

### Service identification
Services are identified with the following mandatory attributes:

+ `org` - the organization in the _exchange_
+ `url` - a unique name for the service within the organization
+ `version` - the [_semantic version_][whatis-semantic-version] of the service
+ `arch` - the architecture of the service (see [architecture list][arch-list])

### Service description
Additional descriptive attributes are also available:

+ `label` - an plain-text  string to name the service; **used for defaults in build process**
+ `description` - a plain-text description of the service; maximum 1024 characters
+ `documentation` - link (URL) to documentation, e.g. `README.md` file

### Service composition
The composition attributes include:

+ `shareable` - may be either `singleton` or `multiple` to control instantiation
+ `requiredServices` - an array of services to instantiate and connect  via [VPN][whatis-vpn]
+ `userInput` - an array of dictionary entries for variables passed as environment variables to the container(s)
+ `deployment` - a dictionary of `services` defined by hostname, including Docker image & environment

[whatis-vpn]: https://en.wikipedia.org/wiki/Virtual_private_network

### Service execution
The service execution controls include (see Docker [`run`][docker-run-mode] options):

+ `privileged` - equivalent to Docker `privileged` mode
+ `bind` - maps host file-system directories to container volumes
+ `specificPorts` - maps host IP ports to container ports (TCP and/or UDP)
+ `devices` - maps host devices to container (e.g. `/dev/video0`)

### Example service

The [`cpu/service.json`][cpu-service]  template -- when completed -- is listed below.

1. The service is identified by the combination: `org` `/` `url` `_` `version` `_` `arch`.

2. The service is described by its human-readable `label`, `description`, and `documentation` URL.

3. The service composition indicates `singleton` with no `requiredServices`.

4. The service execution indicates one `deployment.services` entry for `cpu` with `image` identifying the Docker container to be retrieved from the registry (n.b. the  default Docker registry is `docker.io` and is _not_ included in the path).  The container is to be run in Docker `privileged` mode, with two `environment` variables; four (4) `userInput` variables, and no `devices`, `binds`, or `specificPorts` mapped.

[docker-run-mode]: https://docs.docker.com/engine/reference/run/

[cpu-service]: ../cpu/service.json

```JSON
{
  "label": "cpu",
  "description": "Provides hardware abstraction layer as service",
  "documentation": "https://github.com/dcmartin/open-horizon/cpu/README.md",
  "org": "github@dcmartin.com",
  "url": "com.github.dcmartin.open-horizon.cpu-beta",
  "version": "0.0.3",
  "arch": "arm64",
  "sharable": "singleton",
  "requiredServices": [],
  "deployment": {
    "services": {
      "cpu": {
        "environment": ["SERVICE_LABEL=cpu", "SERVICE_VERSION=0.0.3" ],
        "image": "dcmartin/arm64_com.github.dcmartin.open-horizon.cpu-beta:0.0.3",
        "privileged": true,
        "binds": null,
        "devices":null,
        "specific_ports": null
      }
    }
  },
  "userInput": [
    { "name": "CPU_PERIOD","label": "seconds between update","type": "int","defaultValue": "60"},
    { "name": "CPU_INTERVAL", "label": "seconds between cpu testing", "type": "int", "defaultValue": "1"},
    { "name": "LOG_LEVEL","label": "specify logging level", "type": "string","defaultValue": "info"},
    { "name": "DEBUG","label": "debug on/off","type": "boolean","defaultValue": "false"}
  ],
  "public": true
}
```

The optional `public` attribute indicates the service is available -- **after publishing** -- to any organization using the exchange; note that authenticaton and authorization may also be requied for the Docker registry.


# 1. Building a service

Each of the services in this [repository][repository] are built using a common [`Makefile`][service-makefile] in the repository top-level.  In addition, all services share a common [design][design-md].

### Step 1
When the service is properly configured (see _Configuring a service_) the build process for a service is straight-forward:

```
make service-build
```
### Step 2
If all supported architectures are built successfully, each may be tested:

```
make service-test
```
### Step 3
Finally, if all tests complete successfully, the service may be published:

```
make service-publish
```

# 2. Configuring a service

Each service is composed of multiple artifacts:

+ `build.json` - a dictionary of architectures and containers  
+ `service.json` - a template of the service definition for components and configuration
+ `userinput.json` - a template for registration configuration

## 2.1 `build.json`
The JSON configuration file providing a dictionary of support architectures; see [`BUILD.md`][build-md].
	
## 2.2 `service.json` - service configuration _template_

The service template definition includes four (4) important fields that are used in service identification:

+ `org` - the organization for the service
+ `version` - the version of the service; this value is encoded for [semantic versioning][semver]
+ `url` - a unique identifier for the service (e.g. `com.github.dcmartin.open-horizon`)
+ `arch` - an architecture label (e.g. `amd64`)

The value of these fields are combined together to uniquely identify each service in the exchange; for example:

```
github@dcmartin.com/com.github.dcmartin.open-horizon.yolo2msghub_0.0.9_amd64
```

In addition to these identifying attributes, the `label` field identifies the service in a more human-readable form.  This field should be URL _encoded_ if spaces or other special characters are required.  Note that the `arch` attribute in the service configuration template is `null`; that value will be generated during the build process. For additional information on the service definition attributes, please refer to the documentation.

```
  "org": "${HZN_ORG_ID}",
  "version": "0.0.9",
  "url": "com.github.dcmartin.open-horizon.yolo2msghub",
  "arch": null,
  "label": "yolo2msghub",
  "description": "Sends JSON payloads from yolo service to Kafka",
  "documentation": "https://github.com/dcmartin/open-horizon/yolo2msghub/README.md",
  "public": true,
  "sharable": "singleton",
```

#### 2.2.1`requiredServices` 
This field is an array of identifying attributes for each service on which the service depends.  The `arch` field is `null` and will be populated according to the architecture when built.

```
  "requiredServices": [
    { "url": "com.github.dcmartin.open-horizon.yolo", "org": "${HZN_ORG_ID}", "version": "0.0.4", "arch": null },
    { "url": "com.github.dcmartin.open-horizon.wan", "org": "${HZN_ORG_ID}", "version": "0.0.1", "arch": null },
    { "url": "com.github.dcmartin.open-horizon.hal", "org": "${HZN_ORG_ID}", "version": "0.0.1", "arch": null },
    { "url": "com.github.dcmartin.open-horizon.cpu", "org": "${HZN_ORG_ID}", "version": "0.0.2", "arch": null }
  ],
```

#### 2.2.2 `userInput`
This field is an array of variables that may be used to configure the service; variables with a `defaultValue` of `null` are mandatory.

```
  "userInput": [
    { "name": "YOLO2MSGHUB_APIKEY", "label": "message hub API key", "type": "string", "defaultValue": null },
    { "name": "YOLO2MSGHUB_ADMIN_URL", "label": "administrative URL", "type": "string", "defaultValue": "https://kafka-admin-prod02.messagehub.services.us-south.bluemix.net:443"},
    { "name": "YOLO2MSGHUB_BROKER", "label": "message hub broker list", "type": "string", "defaultValue": "kafka05-prod02.messagehub.services.us-south.bluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093" },
    { "name": "YOLO2MSGHUB_PERIOD", "label": "update interval", "type": "int", "defaultValue": "30" },
    { "name": "LOG_LEVEL", "label": "specify logging level", "type": "string", "defaultValue": "info" },
    { "name": "DEBUG", "label": "debug on/off", "type": "boolean", "defaultValue": "false" }
  ],
```

#### 2.2.3 `deployment`
This field is a dictionary of `services` that are included in the service deployment.  Each entry in the dictionary provides specifics, including key name (e.g. `yolo2msghub` in example below) as well as other deployment options and configuration.  The `environment` section is deprecated, but used in these services design to convey the service's `label` value.

```
  "deployment": {
    "services": {
      "yolo2msghub": {
        "environment": [
          "SERVICE_LABEL=yolo2msghub","SERVICE_VERSION=0.0.9","SERVICE_PORT=8587"
        ],
        "devices": null,
        "binds": null,
        "specific_ports": [ { "HostPort": "8587:8587/tcp", "HostIP": "0.0.0.0" } ],
        "image": null,
        "privileged": false
      }
    }
  },
```

[service-makefile]: ../service.makefile
[semver]: https://semver.org/

## 2.3 `userinput.json`

The template for registration configuration includes specification of environment variables that will be defined for the service and any required services; for example, the `yolo2msghub/userinput.json` specifies variables for four (4) services:

```
{
  "global": [],
  "services": [
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.yolo2msghub",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "YOLO2MSGHUB_APIKEY": null, "LOCALHOST_PORT": 8587, "LOG_LEVEL": "info", "DEBUG": false }
    },
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.yolo",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "YOLO_ENTITY": "person", "YOLO_PERIOD": 60, "YOLO_CONFIG": "tiny", "YOLO_THRESHOLD": 0.25 }
    },
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.cpu",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "CPU_PERIOD": 60 }
    },
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.wan",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "WAN_PERIOD": 900 }
    },
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.hal",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "HAL_PERIOD": 1800 }
    }
  ]
}
```

# 3. `make` targets

The build process for each service is identical.  The _default_ `make` target `build`, `run`,`check` for the  Docker container image using the native architecture (e.g. `amd64`).  The execution environment does _not_ include the required services (see `service-start`).  More information on `make` and the build process is available in [`BUILD.md`][build-md] and [`MAKE.md`][make-md].

+ `service-build` - build Docker container images for all supported architectures
+ `service-push` - push the Docker container images to registry (n.b. `DOCKER_NAMESPACE`; see [`MAKEVARS.md`][makevars-md])
+ `service-start` - starts the services and required services 
+ `service-test` - tests the _started_ service using `test-{service}.sh` for conformant status payload
+ `service-stop` - stops the services and required services
+ `service-publish` - publish the service in the exchange for all supported architectures
+ `service-verify` - verifies the published service in the exchange

## 3.1 `service-build` & `service-push`

These targets will build and push, respectively, the service for all supported architectures; multi-architecture emulation using QEMU is TBD.  Services must be built and pushed prior to starting, testing, or publishing.

## 3.2 `service-start`

This target will ensure that the service is built and then initiate the service using the `hzn` CLI commands.  All services specified, including required services, will also be initiated and appropriate virtual private networks will be established.  Please refer to the Open Horizon documentation for more details on the `hzn` command-line-interface.

## 3.3 `service-test`

This target may be used against the local container, the local service (n.b. see `start` target), or any node running the _service_.  The service is accessed on its external `port` without mapping.  The payload is processed into a JSON type structure, including _object_, _array_, _number_, _string_.

```
{
  "hzn": {
    "agreementid": "string",
    "arch": "string",
    "cpus": "number",
    "device_id": "string",
    "exchange_url": "string",
    "host_ips": [
      "string"
    ],
    "organization": "string",
    "pattern": "string",
    "ram": "number"
  },
  "date": "number",
  "service": "string",
  "hostname": "string",
  "pid": "number",
  "cpu": {
    "date": "number",
    "log_level": "string",
    "debug": "boolean",
    "period": "number",
    "interval": "number",
    "percent": "number"
  }
}
```

## 3.4 `service-stop`

This target will stop the services and all required services initiated using the `service-start` target.

## 3.5 `service-publish`

This target pushes the Docker container images into the registry and publishes the service with the identifier (see above) and the corresponding registry image tag, e.g. `dcmartin/arm64_yolo2msghub_0.0.9`.

## 3.6 `service-verify`

This target will verify that the service is published into the exchange.

[docker-start]: https://www.docker.com/get-started
[make-md]: ../doc/MAKE.md
[build-md]: ../doc/BUILD.md
[makevars-md]: ../doc/MAKEVARS.md
[setup-readme-md]: ../setup/README.md

[travis-md]: ../doc/TRAVIS.md
[design-md]: ../doc/DESIGN.md
[travis-yaml]: ../.travis.yml
[travis-ci]: https://travis-ci.org/
[build-pattern-video]: https://youtu.be/cv_rOdxXidA

[yolo-service]: ../yolo/README.md
[hal-service]: ../hal/README.md
[cpu-service]: ../cpu/README.md
[wan-service]: ../wan/README.md
[yolo2msghub-service]: ../yolo2msghub/README.md
[motion2mqtt-service]: ../motion2mqtt/README.md

# 4. Example output

For reference the following are listings from executions of the targets from the top-level directory:

## 4.1 `make service-build`

Elapsed time: 22 minutes; 18 seconds.

```
>>> MAKE -- making service-build in base-alpine base-ubuntu hzncli cpu hal wan yolo  herald mqtt yolo4motion yolo2msghub motion2mqtt
>>> MAKE -- 10:47:54 -- making: base-alpine-beta; architecture: amd64
>>> MAKE -- 10:47:55 -- building: base-alpine-beta; tag: dcmartin/amd64_base-alpine-beta:0.0.2
>>> MAKE -- 10:48:03 -- making: base-alpine-beta; architecture: arm
>>> MAKE -- 10:48:04 -- building: base-alpine-beta; tag: dcmartin/arm_base-alpine-beta:0.0.2
>>> MAKE -- 10:48:15 -- making: base-alpine-beta; architecture: arm64
>>> MAKE -- 10:48:15 -- building: base-alpine-beta; tag: dcmartin/arm64_base-alpine-beta:0.0.2
>>> MAKE -- 10:48:25 -- making: base-ubuntu-beta; architecture: amd64
>>> MAKE -- 10:48:26 -- building: base-ubuntu-beta; tag: dcmartin/amd64_base-ubuntu-beta:0.0.2
>>> MAKE -- 10:48:42 -- making: base-ubuntu-beta; architecture: arm
>>> MAKE -- 10:48:42 -- building: base-ubuntu-beta; tag: dcmartin/arm_base-ubuntu-beta:0.0.2
>>> MAKE -- 10:49:26 -- making: base-ubuntu-beta; architecture: arm64
>>> MAKE -- 10:49:27 -- building: base-ubuntu-beta; tag: dcmartin/arm64_base-ubuntu-beta:0.0.2
>>> MAKE -- 10:49:29 -- making: hzncli-beta; architecture: amd64
>>> MAKE -- 10:49:30 -- building: hzncli-beta; tag: dcmartin/amd64_hzncli-beta:0.0.2
>>> MAKE -- 10:49:50 -- making: hzncli-beta; architecture: arm
>>> MAKE -- 10:49:51 -- building: hzncli-beta; tag: dcmartin/arm_hzncli-beta:0.0.2
>>> MAKE -- 10:51:47 -- making: hzncli-beta; architecture: arm64
>>> MAKE -- 10:51:48 -- building: hzncli-beta; tag: dcmartin/arm64_hzncli-beta:0.0.2
>>> MAKE -- 10:53:14 -- making: cpu-beta; architecture: amd64
>>> MAKE -- 10:53:15 -- building: cpu-beta; tag: dcmartin/amd64_cpu-beta:0.0.2
>>> MAKE -- 10:53:20 -- making: cpu-beta; architecture: arm
>>> MAKE -- 10:53:20 -- building: cpu-beta; tag: dcmartin/arm_cpu-beta:0.0.2
>>> MAKE -- 10:53:26 -- making: cpu-beta; architecture: arm64
>>> MAKE -- 10:53:27 -- building: cpu-beta; tag: dcmartin/arm64_cpu-beta:0.0.2
>>> MAKE -- 10:53:33 -- making: hal-beta; architecture: amd64
>>> MAKE -- 10:53:34 -- building: hal-beta; tag: dcmartin/amd64_hal-beta:0.0.2
>>> MAKE -- 10:53:38 -- making: hal-beta; architecture: arm
>>> MAKE -- 10:53:39 -- building: hal-beta; tag: dcmartin/arm_hal-beta:0.0.2
>>> MAKE -- 10:53:45 -- making: hal-beta; architecture: arm64
>>> MAKE -- 10:53:45 -- building: hal-beta; tag: dcmartin/arm64_hal-beta:0.0.2
>>> MAKE -- 10:53:51 -- making: wan-beta; architecture: amd64
>>> MAKE -- 10:53:52 -- building: wan-beta; tag: dcmartin/amd64_wan-beta:0.0.2
>>> MAKE -- 10:54:03 -- making: wan-beta; architecture: arm
>>> MAKE -- 10:54:03 -- building: wan-beta; tag: dcmartin/arm_wan-beta:0.0.2
>>> MAKE -- 10:54:27 -- making: wan-beta; architecture: arm64
>>> MAKE -- 10:54:27 -- building: wan-beta; tag: dcmartin/arm64_wan-beta:0.0.2
>>> MAKE -- 10:54:52 -- making: yolo-beta; architecture: amd64
>>> MAKE -- 10:54:53 -- building: yolo-beta; tag: dcmartin/amd64_yolo-beta:0.0.5
>>> MAKE -- 10:55:56 -- making: yolo-beta; architecture: arm
>>> MAKE -- 10:55:56 -- building: yolo-beta; tag: dcmartin/arm_yolo-beta:0.0.5
>>> MAKE -- 11:00:19 -- making: yolo-beta; architecture: arm64
>>> MAKE -- 11:00:20 -- building: yolo-beta; tag: dcmartin/arm64_yolo-beta:0.0.5
>>> MAKE -- 11:04:38 -- making: herald-beta; architecture: amd64
>>> MAKE -- 11:04:39 -- building: herald-beta; tag: dcmartin/amd64_herald-beta:0.0.2
>>> MAKE -- 11:04:53 -- making: herald-beta; architecture: arm
>>> MAKE -- 11:04:53 -- building: herald-beta; tag: dcmartin/arm_herald-beta:0.0.2
>>> MAKE -- 11:05:36 -- making: herald-beta; architecture: arm64
>>> MAKE -- 11:05:37 -- building: herald-beta; tag: dcmartin/arm64_herald-beta:0.0.2
>>> MAKE -- 11:06:14 -- making: mqtt-beta; architecture: amd64
>>> MAKE -- 11:06:14 -- building: mqtt-beta; tag: dcmartin/amd64_mqtt-beta:0.0.2
>>> MAKE -- 11:06:19 -- making: mqtt-beta; architecture: arm
>>> MAKE -- 11:06:20 -- building: mqtt-beta; tag: dcmartin/arm_mqtt-beta:0.0.2
>>> MAKE -- 11:06:25 -- making: mqtt-beta; architecture: arm64
>>> MAKE -- 11:06:25 -- building: mqtt-beta; tag: dcmartin/arm64_mqtt-beta:0.0.2
>>> MAKE -- 11:06:31 -- making: yolo4motion-beta; architecture: arm64
>>> MAKE -- 11:06:31 -- building: yolo4motion-beta; tag: dcmartin/arm64_yolo4motion-beta:0.0.3
>>> MAKE -- 11:06:55 -- making: yolo4motion-beta; architecture: amd64
>>> MAKE -- 11:06:55 -- building: yolo4motion-beta; tag: dcmartin/amd64_yolo4motion-beta:0.0.3
>>> MAKE -- 11:07:04 -- making: yolo4motion-beta; architecture: arm
>>> MAKE -- 11:07:04 -- building: yolo4motion-beta; tag: dcmartin/arm_yolo4motion-beta:0.0.3
>>> MAKE -- 11:07:38 -- making: yolo2msghub-beta; architecture: amd64
>>> MAKE -- 11:07:39 -- building: yolo2msghub-beta; tag: dcmartin/amd64_yolo2msghub-beta:0.0.9
>>> MAKE -- 11:07:50 -- making: yolo2msghub-beta; architecture: arm
>>> MAKE -- 11:07:51 -- building: yolo2msghub-beta; tag: dcmartin/arm_yolo2msghub-beta:0.0.9
>>> MAKE -- 11:08:49 -- making: yolo2msghub-beta; architecture: arm64
>>> MAKE -- 11:08:50 -- building: yolo2msghub-beta; tag: dcmartin/arm64_yolo2msghub-beta:0.0.9
>>> MAKE -- 11:09:41 -- making: motion2mqtt-beta; architecture: amd64
>>> MAKE -- 11:09:41 -- building: motion2mqtt-beta; tag: dcmartin/amd64_motion2mqtt-beta:0.0.11
>>> MAKE -- 11:09:53 -- making: motion2mqtt-beta; architecture: arm
>>> MAKE -- 11:09:53 -- building: motion2mqtt-beta; tag: dcmartin/arm_motion2mqtt-beta:0.0.11
>>> MAKE -- 11:10:11 -- making: motion2mqtt-beta; architecture: arm64
>>> MAKE -- 11:10:12 -- building: motion2mqtt-beta; tag: dcmartin/arm64_motion2mqtt-beta:0.0.11
```

## 4.2 `make service-push`

Elapsed time: 56 minutes; 48 seconds

```
>>> MAKE -- making service-push in base-alpine base-ubuntu hzncli cpu hal wan yolo  herald mqtt yolo4motion yolo2msghub motion2mqtt
>>> MAKE -- 10:46:21 -- pushing: base-alpine; architectures: amd64 arm arm64
>>> MAKE -- 10:46:21 -- building: base-alpine; tag: dcmartin/amd64_base-alpine:0.0.2
>>> MAKE -- 10:46:22 -- pushing: base-alpine; tag dcmartin/amd64_base-alpine:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_base-alpine]
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
b9def742274b: Layer already exists
c1a2b5e17511: Layer already exists
d9ff549177a9: Layer already exists
0.0.2: digest: sha256:439afcf42b214d32ed0c3929e29c929ee52c6145331dd6fa19bba3118c159ea4 size: 947
>>> MAKE -- 10:46:28 -- building: base-alpine; tag: dcmartin/arm_base-alpine:0.0.2
>>> MAKE -- 10:46:29 -- pushing: base-alpine; tag dcmartin/arm_base-alpine:0.0.2
The push refers to repository [docker.io/dcmartin/arm_base-alpine]
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
4d6f2b7ff2f4: Layer already exists
e093aa48fce2: Layer already exists
8d4762c91c35: Layer already exists
c1a2b5e17511: Layer already exists
0.0.2: digest: sha256:d2cb4dc682012477f81289cd3c00d1b6ded168173f025727d1cedadb3602f046 size: 1154
>>> MAKE -- 10:46:34 -- building: base-alpine; tag: dcmartin/arm64_base-alpine:0.0.2
>>> MAKE -- 10:46:34 -- pushing: base-alpine; tag dcmartin/arm64_base-alpine:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_base-alpine]
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
82fe62b38ba2: Layer already exists
c1a2b5e17511: Layer already exists
92d7b4d0b33c: Layer already exists
83f5b20eed3b: Layer already exists
0.0.2: digest: sha256:c705931e8acd7b03b08d63cb5b99bfe1355fe7cd7bc917070e5b99df04dce8a0 size: 1154
>>> MAKE -- 10:46:40 -- pushing: base-ubuntu; architectures: amd64 arm arm64
>>> MAKE -- 10:46:40 -- building: base-ubuntu; tag: dcmartin/amd64_base-ubuntu:0.0.2
>>> MAKE -- 10:46:41 -- pushing: base-ubuntu; tag dcmartin/amd64_base-ubuntu:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_base-ubuntu]
c1a2b5e17511: Preparing
4758067d99e3: Preparing
4b7d93055d87: Preparing
663e8522d78b: Preparing
283fb404ea94: Preparing
bebe7ce6215a: Preparing
bebe7ce6215a: Waiting
c1a2b5e17511: Layer already exists
4b7d93055d87: Layer already exists
663e8522d78b: Layer already exists
4758067d99e3: Layer already exists
283fb404ea94: Layer already exists
bebe7ce6215a: Layer already exists
0.0.2: digest: sha256:74546888d9fb516f7cfe0c218d341a29df77b8b921e11d8fcf959bff01ad1dc2 size: 1570
>>> MAKE -- 10:46:50 -- building: base-ubuntu; tag: dcmartin/arm_base-ubuntu:0.0.2
>>> MAKE -- 10:46:50 -- pushing: base-ubuntu; tag dcmartin/arm_base-ubuntu:0.0.2
The push refers to repository [docker.io/dcmartin/arm_base-ubuntu]
c1a2b5e17511: Preparing
d35828dda5a2: Preparing
76c291cb7a07: Preparing
318f75c7806d: Preparing
f9ea0020b31c: Preparing
8173237b52d4: Preparing
8173237b52d4: Waiting
d35828dda5a2: Layer already exists
318f75c7806d: Layer already exists
76c291cb7a07: Layer already exists
c1a2b5e17511: Layer already exists
f9ea0020b31c: Layer already exists
8173237b52d4: Layer already exists
0.0.2: digest: sha256:9e55e696a6cb295b211f4ce643bb8720aaeb629990d0d5d3b3c1098712b4833d size: 1570
>>> MAKE -- 10:46:59 -- building: base-ubuntu; tag: dcmartin/arm64_base-ubuntu:0.0.2
>>> MAKE -- 10:47:00 -- pushing: base-ubuntu; tag dcmartin/arm64_base-ubuntu:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_base-ubuntu]
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
8619c5882d3a: Waiting
c46f525186dd: Layer already exists
54bebf6eee8f: Layer already exists
2507b251c488: Layer already exists
c1a2b5e17511: Layer already exists
4d4364c8fc58: Layer already exists
8619c5882d3a: Layer already exists
0.0.2: digest: sha256:d61686c7a739b714eb31eee5ee7edb4c929489575bb82a3a244374a7aeb2a500 size: 1570
>>> MAKE -- 10:47:05 -- pushing: hzncli; architectures: amd64 arm arm64
>>> MAKE -- 10:47:06 -- building: hzncli; tag: dcmartin/amd64_hzncli:0.0.2
>>> MAKE -- 10:47:31 -- pushing: hzncli; tag dcmartin/amd64_hzncli:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_hzncli]
87dc38c80516: Preparing
e492a6ccdd7b: Preparing
898c00fa3bf5: Preparing
c1a2b5e17511: Preparing
4758067d99e3: Preparing
4b7d93055d87: Preparing
663e8522d78b: Preparing
283fb404ea94: Preparing
bebe7ce6215a: Preparing
4b7d93055d87: Waiting
283fb404ea94: Waiting
bebe7ce6215a: Waiting
663e8522d78b: Waiting
87dc38c80516: Layer already exists
4758067d99e3: Layer already exists
c1a2b5e17511: Layer already exists
4b7d93055d87: Layer already exists
663e8522d78b: Layer already exists
283fb404ea94: Layer already exists
bebe7ce6215a: Layer already exists
e492a6ccdd7b: Pushed
898c00fa3bf5: Pushed
0.0.2: digest: sha256:4e973e097e6ead6a8b3af25041fbfb76b45723b1b99a32a49be2c0bab95649e5 size: 2199
>>> MAKE -- 10:47:54 -- building: hzncli; tag: dcmartin/arm_hzncli:0.0.2
>>> MAKE -- 10:50:23 -- pushing: hzncli; tag dcmartin/arm_hzncli:0.0.2
The push refers to repository [docker.io/dcmartin/arm_hzncli]
87dc38c80516: Preparing
136067d4774b: Preparing
dfb95e8d287b: Preparing
c1a2b5e17511: Preparing
d35828dda5a2: Preparing
76c291cb7a07: Preparing
318f75c7806d: Preparing
f9ea0020b31c: Preparing
8173237b52d4: Preparing
76c291cb7a07: Waiting
318f75c7806d: Waiting
f9ea0020b31c: Waiting
8173237b52d4: Waiting
87dc38c80516: Layer already exists
d35828dda5a2: Layer already exists
c1a2b5e17511: Layer already exists
76c291cb7a07: Layer already exists
318f75c7806d: Layer already exists
f9ea0020b31c: Layer already exists
8173237b52d4: Layer already exists
dfb95e8d287b: Pushed
136067d4774b: Pushed
0.0.2: digest: sha256:3dfdb117379468e64a12408f970c213978a2aff53d91825f97ca0106088a5f6d size: 2199
>>> MAKE -- 10:51:00 -- building: hzncli; tag: dcmartin/arm64_hzncli:0.0.2
>>> MAKE -- 10:53:02 -- pushing: hzncli; tag dcmartin/arm64_hzncli:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_hzncli]
87dc38c80516: Preparing
c7e73a0d7d20: Preparing
6901affa77c1: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
4d4364c8fc58: Waiting
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
c1a2b5e17511: Layer already exists
87dc38c80516: Layer already exists
54bebf6eee8f: Layer already exists
2507b251c488: Layer already exists
4d4364c8fc58: Layer already exists
c46f525186dd: Layer already exists
8619c5882d3a: Layer already exists
c7e73a0d7d20: Pushed
6901affa77c1: Pushed
0.0.2: digest: sha256:64c8a205f862eccc98e275789f3123d5c811c815c520f81dbdabb8b1b209201e size: 2199
>>> MAKE -- 10:53:46 -- pushing: cpu; architectures: amd64 arm arm64
>>> MAKE -- 10:53:46 -- building: cpu; tag: dcmartin/amd64_cpu:0.0.2
>>> MAKE -- 10:53:52 -- pushing: cpu; tag dcmartin/amd64_cpu:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_cpu]
666fa1873489: Preparing
8facc4df3992: Preparing
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
b9def742274b: Layer already exists
d9ff549177a9: Layer already exists
666fa1873489: Layer already exists
c1a2b5e17511: Layer already exists
8facc4df3992: Pushed
0.0.2: digest: sha256:09173f393e1d6bdd60db6701e3038abf49dd4ece4912b10269480e6e6c025bfe size: 1363
>>> MAKE -- 10:54:00 -- building: cpu; tag: dcmartin/arm_cpu:0.0.2
>>> MAKE -- 10:54:07 -- pushing: cpu; tag dcmartin/arm_cpu:0.0.2
The push refers to repository [docker.io/dcmartin/arm_cpu]
666fa1873489: Preparing
35234b927c96: Preparing
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
e093aa48fce2: Waiting
c1a2b5e17511: Layer already exists
8d4762c91c35: Layer already exists
666fa1873489: Layer already exists
4d6f2b7ff2f4: Layer already exists
e093aa48fce2: Layer already exists
35234b927c96: Pushed
0.0.2: digest: sha256:a210c3c6b59dd9f8c30abfda232f36ca517ad944587315a92701cd68312e270d size: 1570
>>> MAKE -- 10:54:15 -- building: cpu; tag: dcmartin/arm64_cpu:0.0.2
>>> MAKE -- 10:54:22 -- pushing: cpu; tag dcmartin/arm64_cpu:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_cpu]
666fa1873489: Preparing
46f35560fce6: Preparing
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
92d7b4d0b33c: Waiting
666fa1873489: Layer already exists
82fe62b38ba2: Layer already exists
c1a2b5e17511: Layer already exists
83f5b20eed3b: Layer already exists
92d7b4d0b33c: Layer already exists
46f35560fce6: Pushed
0.0.2: digest: sha256:d158396b22b0f9d19048949d114687d153c1722c79978c035d1be7e0adb00c42 size: 1570
>>> MAKE -- 10:54:29 -- pushing: hal; architectures: amd64 arm arm64
>>> MAKE -- 10:54:29 -- building: hal; tag: dcmartin/amd64_hal:0.0.2
>>> MAKE -- 10:54:35 -- pushing: hal; tag dcmartin/amd64_hal:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_hal]
6ecaf443f838: Preparing
9d0866d0d9ef: Preparing
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
c1a2b5e17511: Layer already exists
b9def742274b: Layer already exists
d9ff549177a9: Layer already exists
6ecaf443f838: Layer already exists
9d0866d0d9ef: Pushed
0.0.2: digest: sha256:dc4b60ae3d9811c315947bce38d46836f43cfb075479363ff03e44707d6774e7 size: 1366
>>> MAKE -- 10:54:50 -- building: hal; tag: dcmartin/arm_hal:0.0.2
>>> MAKE -- 10:54:59 -- pushing: hal; tag dcmartin/arm_hal:0.0.2
The push refers to repository [docker.io/dcmartin/arm_hal]
6ecaf443f838: Preparing
c19226c30f3c: Preparing
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
e093aa48fce2: Waiting
4d6f2b7ff2f4: Layer already exists
c1a2b5e17511: Layer already exists
6ecaf443f838: Layer already exists
8d4762c91c35: Layer already exists
e093aa48fce2: Layer already exists
c19226c30f3c: Pushed
0.0.2: digest: sha256:426078c6a6cd2248f29639e75cf2403a73b717dc698e1cfc972fd842aab6c907 size: 1573
>>> MAKE -- 10:55:39 -- building: hal; tag: dcmartin/arm64_hal:0.0.2
>>> MAKE -- 10:55:46 -- pushing: hal; tag dcmartin/arm64_hal:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_hal]
6ecaf443f838: Preparing
3c381e909e60: Preparing
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
92d7b4d0b33c: Waiting
83f5b20eed3b: Layer already exists
82fe62b38ba2: Layer already exists
6ecaf443f838: Layer already exists
c1a2b5e17511: Layer already exists
92d7b4d0b33c: Layer already exists
3c381e909e60: Pushed
0.0.2: digest: sha256:106675c91dd784d5e843b8900732120128e3ea29d94a5b1b14b24a674649a8a4 size: 1573
>>> MAKE -- 10:56:04 -- pushing: wan; architectures: amd64 arm arm64
>>> MAKE -- 10:56:04 -- building: wan; tag: dcmartin/amd64_wan:0.0.2
>>> MAKE -- 10:56:18 -- pushing: wan; tag dcmartin/amd64_wan:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_wan]
35adc189ceb3: Preparing
a95e5d991272: Preparing
5805f19e1203: Preparing
b13f44e5d940: Preparing
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
d9ff549177a9: Waiting
b9def742274b: Waiting
35adc189ceb3: Layer already exists
c1a2b5e17511: Layer already exists
b9def742274b: Layer already exists
d9ff549177a9: Layer already exists
a95e5d991272: Pushed
5805f19e1203: Pushed
b13f44e5d940: Pushed
0.0.2: digest: sha256:9ac55b63670e227adbd94f4d004e20dfe6354749f74465d1daff323a3e896ca8 size: 1786
>>> MAKE -- 10:57:04 -- building: wan; tag: dcmartin/arm_wan:0.0.2
>>> MAKE -- 10:57:49 -- pushing: wan; tag dcmartin/arm_wan:0.0.2
The push refers to repository [docker.io/dcmartin/arm_wan]
35adc189ceb3: Preparing
3de53a18fbcd: Preparing
e3dd54756305: Preparing
e62d9f472608: Preparing
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
8d4762c91c35: Waiting
4d6f2b7ff2f4: Waiting
e093aa48fce2: Waiting
35adc189ceb3: Layer already exists
c1a2b5e17511: Layer already exists
8d4762c91c35: Layer already exists
4d6f2b7ff2f4: Layer already exists
e093aa48fce2: Layer already exists
3de53a18fbcd: Pushed
e3dd54756305: Pushed
e62d9f472608: Pushed
0.0.2: digest: sha256:d90480530b50003cdf9e50eabf866be8776b9eab64eeba39b48d7b059ef8f5b2 size: 1993
>>> MAKE -- 10:58:28 -- building: wan; tag: dcmartin/arm64_wan:0.0.2
>>> MAKE -- 10:59:01 -- pushing: wan; tag dcmartin/arm64_wan:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_wan]
35adc189ceb3: Preparing
07758018beb9: Preparing
58d0f6b202e9: Preparing
753a6482df8e: Preparing
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
83f5b20eed3b: Waiting
82fe62b38ba2: Waiting
92d7b4d0b33c: Waiting
c1a2b5e17511: Layer already exists
35adc189ceb3: Layer already exists
83f5b20eed3b: Layer already exists
82fe62b38ba2: Layer already exists
92d7b4d0b33c: Layer already exists
07758018beb9: Pushed
58d0f6b202e9: Pushed
753a6482df8e: Pushed
0.0.2: digest: sha256:01b80ae5684848fe158d15fd16f7a338afdaec9bb3db8138b2a1314e7d9f4cea size: 1993
>>> MAKE -- 10:59:49 -- pushing: yolo; architectures: amd64 arm arm64
>>> MAKE -- 10:59:49 -- building: yolo; tag: dcmartin/amd64_yolo:0.0.5
>>> MAKE -- 11:00:58 -- pushing: yolo; tag dcmartin/amd64_yolo:0.0.5
The push refers to repository [docker.io/dcmartin/amd64_yolo]
1aebe514d438: Preparing
cb6df2cde894: Preparing
ee50358af42a: Preparing
6f12de94adc8: Preparing
7480c71324af: Preparing
4980dfb3767d: Preparing
c1a2b5e17511: Preparing
4758067d99e3: Preparing
4b7d93055d87: Preparing
663e8522d78b: Preparing
283fb404ea94: Preparing
bebe7ce6215a: Preparing
663e8522d78b: Waiting
c1a2b5e17511: Waiting
283fb404ea94: Waiting
4758067d99e3: Waiting
4980dfb3767d: Waiting
bebe7ce6215a: Waiting
4b7d93055d87: Waiting
7480c71324af: Pushed
1aebe514d438: Pushed
c1a2b5e17511: Layer already exists
4758067d99e3: Layer already exists
4b7d93055d87: Layer already exists
663e8522d78b: Layer already exists
283fb404ea94: Layer already exists
bebe7ce6215a: Layer already exists
ee50358af42a: Pushed
cb6df2cde894: Pushed
6f12de94adc8: Pushed
4980dfb3767d: Pushed
0.0.5: digest: sha256:5720c0f2a79e94a460028d990df5ace3cc2d36ddd3ce6b736a07fb04bca8aa54 size: 2832
>>> MAKE -- 11:04:27 -- building: yolo; tag: dcmartin/arm_yolo:0.0.5
>>> MAKE -- 11:11:18 -- pushing: yolo; tag dcmartin/arm_yolo:0.0.5
The push refers to repository [docker.io/dcmartin/arm_yolo]
db4143564519: Preparing
1fee42e2c1d5: Preparing
b37bd0db2593: Preparing
e8a0e2f05698: Preparing
c15f6916b7d4: Preparing
ce197e015fda: Preparing
c1a2b5e17511: Preparing
d35828dda5a2: Preparing
76c291cb7a07: Preparing
318f75c7806d: Preparing
f9ea0020b31c: Preparing
8173237b52d4: Preparing
ce197e015fda: Waiting
c1a2b5e17511: Waiting
d35828dda5a2: Waiting
76c291cb7a07: Waiting
318f75c7806d: Waiting
f9ea0020b31c: Waiting
8173237b52d4: Waiting
c15f6916b7d4: Pushed
db4143564519: Pushed
c1a2b5e17511: Layer already exists
d35828dda5a2: Layer already exists
76c291cb7a07: Layer already exists
318f75c7806d: Layer already exists
f9ea0020b31c: Layer already exists
8173237b52d4: Layer already exists
b37bd0db2593: Pushed
e8a0e2f05698: Pushed
1fee42e2c1d5: Pushed
ce197e015fda: Pushed
0.0.5: digest: sha256:1a5438c86a8124f9da74ec004acd1ac42afc551cf67f0d3979637cc1d99e8666 size: 2830
>>> MAKE -- 11:14:12 -- building: yolo; tag: dcmartin/arm64_yolo:0.0.5
>>> MAKE -- 11:19:41 -- pushing: yolo; tag dcmartin/arm64_yolo:0.0.5
The push refers to repository [docker.io/dcmartin/arm64_yolo]
27883008de43: Preparing
66c88e3c4f18: Preparing
84fbb4e70bda: Preparing
01cddfbf7ce6: Preparing
4e66cab03679: Preparing
58f908f99ad1: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
58f908f99ad1: Waiting
c1a2b5e17511: Waiting
54bebf6eee8f: Waiting
4d4364c8fc58: Waiting
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
27883008de43: Pushed
4e66cab03679: Pushed
c1a2b5e17511: Layer already exists
54bebf6eee8f: Layer already exists
4d4364c8fc58: Layer already exists
84fbb4e70bda: Pushed
c46f525186dd: Layer already exists
2507b251c488: Layer already exists
8619c5882d3a: Layer already exists
66c88e3c4f18: Pushed
01cddfbf7ce6: Pushed
58f908f99ad1: Pushed
0.0.5: digest: sha256:0e1dbfe0c7593f09f201b64d035b5280e75b3111e6ee8dc2e151f235764e57ce size: 2831
>>> MAKE -- 11:23:21 -- pushing: herald; architectures: amd64 arm arm64
>>> MAKE -- 11:23:21 -- building: herald; tag: dcmartin/amd64_herald:0.0.2
>>> MAKE -- 11:23:41 -- pushing: herald; tag dcmartin/amd64_herald:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_herald]
79294a3a78c2: Preparing
2783261a46c8: Preparing
50f0d90ce796: Preparing
3e2f32cda8c7: Preparing
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
b9def742274b: Waiting
d9ff549177a9: Waiting
c1a2b5e17511: Layer already exists
79294a3a78c2: Layer already exists
b9def742274b: Layer already exists
d9ff549177a9: Layer already exists
2783261a46c8: Pushed
50f0d90ce796: Pushed
3e2f32cda8c7: Pushed
0.0.2: digest: sha256:62710485949e34e2d054266cf7d12d496f8ee591fc890ab74d81bd148391263c size: 1789
>>> MAKE -- 11:24:42 -- building: herald; tag: dcmartin/arm_herald:0.0.2
>>> MAKE -- 11:25:31 -- pushing: herald; tag dcmartin/arm_herald:0.0.2
The push refers to repository [docker.io/dcmartin/arm_herald]
79294a3a78c2: Preparing
6fbb73162b93: Preparing
54c434694c35: Preparing
15bc15f34e57: Preparing
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
8d4762c91c35: Waiting
4d6f2b7ff2f4: Waiting
e093aa48fce2: Waiting
c1a2b5e17511: Layer already exists
79294a3a78c2: Layer already exists
4d6f2b7ff2f4: Layer already exists
8d4762c91c35: Layer already exists
e093aa48fce2: Layer already exists
54c434694c35: Pushed
6fbb73162b93: Pushed
15bc15f34e57: Pushed
0.0.2: digest: sha256:3bae4547263533599dfa69c3bb4f2b5890a6974c8893abc0832a439da753a5c9 size: 1996
>>> MAKE -- 11:27:55 -- building: herald; tag: dcmartin/arm64_herald:0.0.2
>>> MAKE -- 11:28:41 -- pushing: herald; tag dcmartin/arm64_herald:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_herald]
79294a3a78c2: Preparing
e8cfafc25587: Preparing
908dc9cef47f: Preparing
bd73f1e71180: Preparing
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
82fe62b38ba2: Waiting
83f5b20eed3b: Waiting
92d7b4d0b33c: Waiting
79294a3a78c2: Layer already exists
c1a2b5e17511: Layer already exists
83f5b20eed3b: Layer already exists
82fe62b38ba2: Layer already exists
92d7b4d0b33c: Layer already exists
e8cfafc25587: Pushed
908dc9cef47f: Pushed
bd73f1e71180: Pushed
0.0.2: digest: sha256:c91006564e572411bc14062affe2518aa054ff1133054c2b14ff8c65aa413a3e size: 1996
>>> MAKE -- 11:30:12 -- pushing: mqtt; architectures: amd64 arm arm64
>>> MAKE -- 11:30:12 -- building: mqtt; tag: dcmartin/amd64_mqtt:0.0.2
>>> MAKE -- 11:30:17 -- pushing: mqtt; tag dcmartin/amd64_mqtt:0.0.2
The push refers to repository [docker.io/dcmartin/amd64_mqtt]
d0a16f1c0d1b: Preparing
83d7271bc8e6: Preparing
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
b9def742274b: Layer already exists
d0a16f1c0d1b: Layer already exists
d9ff549177a9: Layer already exists
c1a2b5e17511: Layer already exists
83d7271bc8e6: Pushed
0.0.2: digest: sha256:e4519a7312874ccdba458628c27be21c0e6cf71c77ea4e8e063cdaf3f3674700 size: 1365
>>> MAKE -- 11:30:26 -- building: mqtt; tag: dcmartin/arm_mqtt:0.0.2
>>> MAKE -- 11:30:32 -- pushing: mqtt; tag dcmartin/arm_mqtt:0.0.2
The push refers to repository [docker.io/dcmartin/arm_mqtt]
d0a16f1c0d1b: Preparing
d326945c3fc0: Preparing
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
e093aa48fce2: Waiting
8d4762c91c35: Layer already exists
4d6f2b7ff2f4: Layer already exists
d0a16f1c0d1b: Layer already exists
c1a2b5e17511: Layer already exists
e093aa48fce2: Layer already exists
d326945c3fc0: Pushed
0.0.2: digest: sha256:93333d0b77c4dfe5dcac6b55c0baac5689c26d309d09f77db2cb030394d6113a size: 1572
>>> MAKE -- 11:30:41 -- building: mqtt; tag: dcmartin/arm64_mqtt:0.0.2
>>> MAKE -- 11:30:48 -- pushing: mqtt; tag dcmartin/arm64_mqtt:0.0.2
The push refers to repository [docker.io/dcmartin/arm64_mqtt]
d0a16f1c0d1b: Preparing
b21c0988fcc0: Preparing
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
92d7b4d0b33c: Waiting
d0a16f1c0d1b: Layer already exists
82fe62b38ba2: Layer already exists
c1a2b5e17511: Layer already exists
83f5b20eed3b: Layer already exists
92d7b4d0b33c: Layer already exists
b21c0988fcc0: Pushed
0.0.2: digest: sha256:f9ecbab990a9ae13f54bfa8af4470dc835b92ea11c48da0f0a8ccf09be083bea size: 1572
>>> MAKE -- 11:31:01 -- pushing: yolo4motion; architectures: arm64 amd64 arm
>>> MAKE -- 11:31:01 -- building: yolo4motion; tag: dcmartin/arm64_yolo4motion:0.0.3
>>> MAKE -- 11:31:38 -- pushing: yolo4motion; tag dcmartin/arm64_yolo4motion:0.0.3
The push refers to repository [docker.io/dcmartin/arm64_yolo4motion]
af61af002982: Preparing
c07a4c8522ac: Preparing
27883008de43: Preparing
66c88e3c4f18: Preparing
84fbb4e70bda: Preparing
01cddfbf7ce6: Preparing
4e66cab03679: Preparing
58f908f99ad1: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
c1a2b5e17511: Waiting
54bebf6eee8f: Waiting
4d4364c8fc58: Waiting
01cddfbf7ce6: Waiting
4e66cab03679: Waiting
58f908f99ad1: Waiting
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
af61af002982: Layer already exists
84fbb4e70bda: Mounted from dcmartin/arm64_yolo
27883008de43: Mounted from dcmartin/arm64_yolo
66c88e3c4f18: Mounted from dcmartin/arm64_yolo
01cddfbf7ce6: Mounted from dcmartin/arm64_yolo
c1a2b5e17511: Layer already exists
54bebf6eee8f: Layer already exists
4e66cab03679: Mounted from dcmartin/arm64_yolo
c46f525186dd: Layer already exists
4d4364c8fc58: Layer already exists
2507b251c488: Layer already exists
58f908f99ad1: Mounted from dcmartin/arm64_yolo
8619c5882d3a: Layer already exists
c07a4c8522ac: Pushed
0.0.3: digest: sha256:af6ecb43c0e0705127d6456a06aa84b4a499f2c1a1a601a9620aad8eb2218893 size: 3250
>>> MAKE -- 11:32:08 -- building: yolo4motion; tag: dcmartin/amd64_yolo4motion:0.0.3
>>> MAKE -- 11:32:18 -- pushing: yolo4motion; tag dcmartin/amd64_yolo4motion:0.0.3
The push refers to repository [docker.io/dcmartin/amd64_yolo4motion]
af61af002982: Preparing
1a7f31a07868: Preparing
1aebe514d438: Preparing
cb6df2cde894: Preparing
ee50358af42a: Preparing
6f12de94adc8: Preparing
7480c71324af: Preparing
4980dfb3767d: Preparing
c1a2b5e17511: Preparing
4758067d99e3: Preparing
4b7d93055d87: Preparing
663e8522d78b: Preparing
283fb404ea94: Preparing
bebe7ce6215a: Preparing
4980dfb3767d: Waiting
c1a2b5e17511: Waiting
4758067d99e3: Waiting
4b7d93055d87: Waiting
663e8522d78b: Waiting
283fb404ea94: Waiting
bebe7ce6215a: Waiting
6f12de94adc8: Waiting
7480c71324af: Waiting
af61af002982: Layer already exists
1aebe514d438: Mounted from dcmartin/amd64_yolo
ee50358af42a: Mounted from dcmartin/amd64_yolo
cb6df2cde894: Mounted from dcmartin/amd64_yolo
6f12de94adc8: Mounted from dcmartin/amd64_yolo
c1a2b5e17511: Layer already exists
4758067d99e3: Layer already exists
4b7d93055d87: Layer already exists
663e8522d78b: Layer already exists
4980dfb3767d: Mounted from dcmartin/amd64_yolo
283fb404ea94: Layer already exists
7480c71324af: Mounted from dcmartin/amd64_yolo
bebe7ce6215a: Layer already exists
1a7f31a07868: Pushed
0.0.3: digest: sha256:59f884de14f27421ed1f68dbf8f5df62649b0270575acf357bfd4c82277cc05b size: 3250
>>> MAKE -- 11:32:30 -- building: yolo4motion; tag: dcmartin/arm_yolo4motion:0.0.3
>>> MAKE -- 11:33:13 -- pushing: yolo4motion; tag dcmartin/arm_yolo4motion:0.0.3
The push refers to repository [docker.io/dcmartin/arm_yolo4motion]
af61af002982: Preparing
088358cd3d6a: Preparing
db4143564519: Preparing
1fee42e2c1d5: Preparing
b37bd0db2593: Preparing
e8a0e2f05698: Preparing
c15f6916b7d4: Preparing
ce197e015fda: Preparing
c1a2b5e17511: Preparing
d35828dda5a2: Preparing
76c291cb7a07: Preparing
318f75c7806d: Preparing
f9ea0020b31c: Preparing
8173237b52d4: Preparing
e8a0e2f05698: Waiting
c15f6916b7d4: Waiting
ce197e015fda: Waiting
c1a2b5e17511: Waiting
d35828dda5a2: Waiting
76c291cb7a07: Waiting
318f75c7806d: Waiting
8173237b52d4: Waiting
f9ea0020b31c: Waiting
af61af002982: Layer already exists
b37bd0db2593: Mounted from dcmartin/arm_yolo
1fee42e2c1d5: Mounted from dcmartin/arm_yolo
db4143564519: Mounted from dcmartin/arm_yolo
e8a0e2f05698: Mounted from dcmartin/arm_yolo
c1a2b5e17511: Layer already exists
d35828dda5a2: Layer already exists
318f75c7806d: Layer already exists
76c291cb7a07: Layer already exists
c15f6916b7d4: Mounted from dcmartin/arm_yolo
ce197e015fda: Mounted from dcmartin/arm_yolo
f9ea0020b31c: Layer already exists
8173237b52d4: Layer already exists
088358cd3d6a: Pushed
0.0.3: digest: sha256:ecd95417099e26b6ef2088c3a4e9e767a6d1de9272400841425f63ad1133e9c2 size: 3249
>>> MAKE -- 11:33:32 -- pushing: yolo2msghub; architectures: amd64 arm arm64
>>> MAKE -- 11:33:32 -- building: yolo2msghub; tag: dcmartin/amd64_yolo2msghub:0.0.9
>>> MAKE -- 11:33:46 -- pushing: yolo2msghub; tag dcmartin/amd64_yolo2msghub:0.0.9
The push refers to repository [docker.io/dcmartin/amd64_yolo2msghub]
e194dbf384ff: Preparing
becc468bc73e: Preparing
c1a2b5e17511: Preparing
4758067d99e3: Preparing
4b7d93055d87: Preparing
663e8522d78b: Preparing
283fb404ea94: Preparing
bebe7ce6215a: Preparing
283fb404ea94: Waiting
bebe7ce6215a: Waiting
663e8522d78b: Waiting
e194dbf384ff: Layer already exists
4758067d99e3: Layer already exists
4b7d93055d87: Layer already exists
c1a2b5e17511: Layer already exists
663e8522d78b: Layer already exists
283fb404ea94: Layer already exists
bebe7ce6215a: Layer already exists
becc468bc73e: Pushed
0.0.9: digest: sha256:0b1ee54d22e0d7ad7269b17a1dd0a97c730221e55f174114d6be84566dae8dda size: 1989
>>> MAKE -- 11:34:02 -- building: yolo2msghub; tag: dcmartin/arm_yolo2msghub:0.0.9
>>> MAKE -- 11:35:27 -- pushing: yolo2msghub; tag dcmartin/arm_yolo2msghub:0.0.9
The push refers to repository [docker.io/dcmartin/arm_yolo2msghub]
e194dbf384ff: Preparing
2a4f055b2213: Preparing
c1a2b5e17511: Preparing
d35828dda5a2: Preparing
76c291cb7a07: Preparing
318f75c7806d: Preparing
f9ea0020b31c: Preparing
8173237b52d4: Preparing
f9ea0020b31c: Waiting
8173237b52d4: Waiting
318f75c7806d: Waiting
76c291cb7a07: Layer already exists
e194dbf384ff: Layer already exists
c1a2b5e17511: Layer already exists
d35828dda5a2: Layer already exists
8173237b52d4: Layer already exists
318f75c7806d: Layer already exists
f9ea0020b31c: Layer already exists
2a4f055b2213: Pushed
0.0.9: digest: sha256:1f8ad676397b81f8fbdf08918d5353f85d6e9af27a79d9b60b5a012089c08292 size: 1989
>>> MAKE -- 11:35:55 -- building: yolo2msghub; tag: dcmartin/arm64_yolo2msghub:0.0.9
>>> MAKE -- 11:37:06 -- pushing: yolo2msghub; tag dcmartin/arm64_yolo2msghub:0.0.9
The push refers to repository [docker.io/dcmartin/arm64_yolo2msghub]
e194dbf384ff: Preparing
d27b4ee759dc: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
54bebf6eee8f: Layer already exists
e194dbf384ff: Layer already exists
c1a2b5e17511: Layer already exists
4d4364c8fc58: Layer already exists
c46f525186dd: Layer already exists
2507b251c488: Layer already exists
8619c5882d3a: Layer already exists
d27b4ee759dc: Pushed
0.0.9: digest: sha256:038a1efec5e03486a60ce7783eccfa2d69352b44154bbd9b48d3ae31556cce70 size: 1989
>>> MAKE -- 11:37:20 -- pushing: motion2mqtt; architectures: amd64 arm arm64
>>> MAKE -- 11:37:20 -- building: motion2mqtt; tag: dcmartin/amd64_motion2mqtt:0.0.11
>>> MAKE -- 11:37:35 -- pushing: motion2mqtt; tag dcmartin/amd64_motion2mqtt:0.0.11
The push refers to repository [docker.io/dcmartin/amd64_motion2mqtt]
4fa6f6c83a2f: Preparing
ecd96f1ffea1: Preparing
c1a2b5e17511: Preparing
b9def742274b: Preparing
d9ff549177a9: Preparing
b9def742274b: Layer already exists
4fa6f6c83a2f: Layer already exists
c1a2b5e17511: Layer already exists
d9ff549177a9: Layer already exists
ecd96f1ffea1: Pushed
0.0.11: digest: sha256:44e2a291a524198d6205f5ae917d76e3b98b63a6a7a06207b9354fbbffd5d4ff size: 1370
>>> MAKE -- 11:40:11 -- building: motion2mqtt; tag: dcmartin/arm_motion2mqtt:0.0.11
>>> MAKE -- 11:40:34 -- pushing: motion2mqtt; tag dcmartin/arm_motion2mqtt:0.0.11
The push refers to repository [docker.io/dcmartin/arm_motion2mqtt]
4fa6f6c83a2f: Preparing
b08c26e5f1b7: Preparing
c1a2b5e17511: Preparing
8d4762c91c35: Preparing
4d6f2b7ff2f4: Preparing
e093aa48fce2: Preparing
e093aa48fce2: Waiting
4fa6f6c83a2f: Layer already exists
8d4762c91c35: Layer already exists
c1a2b5e17511: Layer already exists
4d6f2b7ff2f4: Layer already exists
e093aa48fce2: Layer already exists
b08c26e5f1b7: Pushed
0.0.11: digest: sha256:649f6824ef7ee52d873251765503322a057823c95c0b7da93dae716aa733f1bb size: 1577
>>> MAKE -- 11:42:49 -- building: motion2mqtt; tag: dcmartin/arm64_motion2mqtt:0.0.11
>>> MAKE -- 11:43:09 -- pushing: motion2mqtt; tag dcmartin/arm64_motion2mqtt:0.0.11
The push refers to repository [docker.io/dcmartin/arm64_motion2mqtt]
4fa6f6c83a2f: Preparing
3303e33bf0b9: Preparing
c1a2b5e17511: Preparing
83f5b20eed3b: Preparing
82fe62b38ba2: Preparing
92d7b4d0b33c: Preparing
92d7b4d0b33c: Waiting
82fe62b38ba2: Layer already exists
c1a2b5e17511: Layer already exists
4fa6f6c83a2f: Layer already exists
83f5b20eed3b: Layer already exists
92d7b4d0b33c: Layer already exists
3303e33bf0b9: Pushed
0.0.11: digest: sha256:d9a31474bf8b4b901655fc81a08704bc6e3bbdde29b059161b2cab5c0b297d95 size: 1577
```

## 4.3 `make service-test`
```
```

## 4.4 `make service-publish`
```
```

## 4.5 `make service-verify`
```
```

## 4.6 `make all`

To rebuild the service (and pattern if applicable)

```
>>> MAKE -- 11:54:26 -- pushing: yolo2msghub; architectures: amd64 arm arm64
>>> MAKE -- 11:54:27 -- building: yolo2msghub; tag: dcmartin/amd64_yolo2msghub:0.0.9
>>> MAKE -- 11:54:29 -- pushing: yolo2msghub; tag dcmartin/amd64_yolo2msghub:0.0.9
The push refers to repository [docker.io/dcmartin/amd64_yolo2msghub]
30f7e29283cb: Pushed 
becc468bc73e: Layer already exists 
c1a2b5e17511: Layer already exists 
4758067d99e3: Layer already exists 
4b7d93055d87: Layer already exists 
663e8522d78b: Layer already exists 
283fb404ea94: Layer already exists 
bebe7ce6215a: Layer already exists 
0.0.9: digest: sha256:8e848df954d6842ca9b819772a84e7c66d6f29d7473bffe78eef6667bc9c9996 size: 1989
>>> MAKE -- 11:54:37 -- building: yolo2msghub; tag: dcmartin/arm_yolo2msghub:0.0.9
>>> MAKE -- 11:54:40 -- pushing: yolo2msghub; tag dcmartin/arm_yolo2msghub:0.0.9
The push refers to repository [docker.io/dcmartin/arm_yolo2msghub]
30f7e29283cb: Mounted from dcmartin/amd64_yolo2msghub 
2a4f055b2213: Layer already exists 
c1a2b5e17511: Layer already exists 
d35828dda5a2: Layer already exists 
76c291cb7a07: Layer already exists 
318f75c7806d: Layer already exists 
f9ea0020b31c: Layer already exists 
8173237b52d4: Layer already exists 
0.0.9: digest: sha256:1e299a8ebe11c3573e9192bc6bf2b43cd1db8c4d9ecceeb6a83e60f82105fdaa size: 1989
>>> MAKE -- 11:54:46 -- building: yolo2msghub; tag: dcmartin/arm64_yolo2msghub:0.0.9
>>> MAKE -- 11:54:49 -- pushing: yolo2msghub; tag dcmartin/arm64_yolo2msghub:0.0.9
The push refers to repository [docker.io/dcmartin/arm64_yolo2msghub]
30f7e29283cb: Mounted from dcmartin/arm_yolo2msghub 
d27b4ee759dc: Layer already exists 
c1a2b5e17511: Layer already exists 
54bebf6eee8f: Layer already exists 
4d4364c8fc58: Layer already exists 
c46f525186dd: Layer already exists 
2507b251c488: Layer already exists 
8619c5882d3a: Layer already exists 
0.0.9: digest: sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f size: 1989
>>> MAKE -- 11:54:55 -- publishing: yolo2msghub; architectures: amd64 arm arm64
>>> MAKE -- 11:54:55 -- publishing: yolo2msghub; architecture: amd64
Signing service...
Pushing dcmartin/arm64_yolo2msghub:0.0.9...
The push refers to repository [docker.io/dcmartin/arm64_yolo2msghub]
30f7e29283cb: Preparing
d27b4ee759dc: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
c1a2b5e17511: Layer already exists
54bebf6eee8f: Layer already exists
4d4364c8fc58: Layer already exists
30f7e29283cb: Layer already exists
d27b4ee759dc: Layer already exists
2507b251c488: Layer already exists
8619c5882d3a: Layer already exists
c46f525186dd: Layer already exists
0.0.9: digest: sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f size: 1989
Using 'dcmartin/arm64_yolo2msghub@sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f' in 'deployment' field instead of 'dcmartin/arm64_yolo2msghub:0.0.9'
Updating com.github.dcmartin.open-horizon.yolo2msghub_0.0.9_arm64 in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the service in the exchange...
>>> MAKE -- 11:55:02 -- publishing: yolo2msghub; architecture: arm
Signing service...
Pushing dcmartin/arm64_yolo2msghub:0.0.9...
The push refers to repository [docker.io/dcmartin/arm64_yolo2msghub]
30f7e29283cb: Preparing
d27b4ee759dc: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
c1a2b5e17511: Layer already exists
4d4364c8fc58: Layer already exists
d27b4ee759dc: Layer already exists
30f7e29283cb: Layer already exists
54bebf6eee8f: Layer already exists
c46f525186dd: Layer already exists
8619c5882d3a: Layer already exists
2507b251c488: Layer already exists
0.0.9: digest: sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f size: 1989
Using 'dcmartin/arm64_yolo2msghub@sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f' in 'deployment' field instead of 'dcmartin/arm64_yolo2msghub:0.0.9'
Updating com.github.dcmartin.open-horizon.yolo2msghub_0.0.9_arm64 in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the service in the exchange...
>>> MAKE -- 11:55:07 -- publishing: yolo2msghub; architecture: arm64
Signing service...
Pushing dcmartin/arm64_yolo2msghub:0.0.9...
The push refers to repository [docker.io/dcmartin/arm64_yolo2msghub]
30f7e29283cb: Preparing
d27b4ee759dc: Preparing
c1a2b5e17511: Preparing
54bebf6eee8f: Preparing
4d4364c8fc58: Preparing
c46f525186dd: Preparing
2507b251c488: Preparing
8619c5882d3a: Preparing
c46f525186dd: Waiting
2507b251c488: Waiting
8619c5882d3a: Waiting
c1a2b5e17511: Layer already exists
d27b4ee759dc: Layer already exists
54bebf6eee8f: Layer already exists
4d4364c8fc58: Layer already exists
30f7e29283cb: Layer already exists
2507b251c488: Layer already exists
c46f525186dd: Layer already exists
8619c5882d3a: Layer already exists
0.0.9: digest: sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f size: 1989
Using 'dcmartin/arm64_yolo2msghub@sha256:1f905bc7551e39e6b90a3f2a6d22333575856385fb17addbd203f7d74b49a68f' in 'deployment' field instead of 'dcmartin/arm64_yolo2msghub:0.0.9'
Updating com.github.dcmartin.open-horizon.yolo2msghub_0.0.9_arm64 in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the service in the exchange...
>>> MAKE -- 11:55:13 -- verifying: yolo2msghub; organization: github@dcmartin.com
true
All signatures verified
>>> MAKE -- 11:55:15 -- publishing: yolo2msghub; organization: github@dcmartin.com; exchange: https://alpha.edge-fabric.com/v1
Updating yolo2msghub in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the pattern in the exchange...
>>> MAKE -- 11:55:18 -- validating: yolo2msghub; organization: github@dcmartin.com; exchange: https://alpha.edge-fabric.com/v1
All signatures verified
Found pattern github@dcmartin.com/yolo2msghub
```

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
