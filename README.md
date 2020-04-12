<img src="docs/bluehorizon.gif" width="90%">

# `open-horizon`  _edge fabric_ services & patterns

This [repository][repository] contains [Open Horizon](http://github.com/open-horizon) services and patterns, including:

+ [`yolo4motion`](services/yolo4motion/README.md) - A service to process MQTT messages through the **[OpenYOLO](https://github.com/dcmartin/openyolo/)** object detector and classifier
+ [`alpr4motion`](services/alpr4motion/README.md) - A service to process MQTT messages through the **[OpenALPR](http://github.com/dcmartin/openalpr)** automated license plate reader
+ [`face4motion`](services/face4motion/README.md) - A service to process MQTT messages through the **[OpenFACE](http://github.com/dcmartin/openface)** face detector

To setup your own Open Horizon _exchange_, follow the setup [instructions](SETUP.md) to install and configure.

Please see the ["hello world"](docs/HELLO_WORLD.md) example for an introduction to developing for [Open Horizon](http://github.com/open-horizon)

[design-md]: https://github.com/dcmartin/open-horizon/tree/master/docs/DESIGN.md

# 1. [Status][status-md] 

![](https://img.shields.io/github/license/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/release/dcmartin/open-horizon.svg?style=flat)
[![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)
[![Coverage Status](https://coveralls.io/repos/github/dcmartin/open-horizon/badge.svg?branch=master)](https://coveralls.io/github/dcmartin/open-horizon?branch=master)

![](https://img.shields.io/github/repo-size/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/last-commit/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/commit-activity/w/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/contributors/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/issues/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/tag/dcmartin/open-horizon.svg?style=flat)

![Supports amd64 Architecture][amd64-shield]
![Supports arm64 Architecture][arm64-shield]
![Supports arm Architecture][arm-shield]

([_beta_ branch][beta-md])

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## 1.1 Introduction

These services and patterns are built and pushed to designated Docker registry & namespace as well as Open Horizon exchange and organization.  The default build configuration is:

+ `HZN_EXCHANGE_URL` defaults to `https://exchange:3090/v1/`
+ `HZN_ORG_ID` is **unspecified** (e.g. `dcmartin`)
+ `DOCKER_NAMESPACE` is **unspecified** (e.g. [`dcmartin`][docker-dcmartin])
+ `DOCKER_REGISTRY` is **unset** and defaults to `docker.io`

[docker-dcmartin]: https://hub.docker.com/?namespace=dcmartin

This repository works best on a &#63743; macOS computer.  However, macOS need some additional software install the [HomeBrew](http://brew.sh) package manager and install the necessary software:

```
% brew install gettext
% cd /usr/local/bin && ln -s ../Cellar/gettext/0.19.8.1/bin/envsubst .
```

### 1.1.1 Variables
The `HZN_ORG_ID` and `DOCKER_NAMESPACE` should be specified appropriately prior to any build; substitute values appropriately, for example:

```
export HZN_ORG_ID=$(USER}
export HZN_USER_ID=${USER}
export DOCKER_NAMESPACE=${USER}
export HZN_EXCHANGE_URL="http://exchange:3090/v1/"
export HZN_EXCHANGE_APIKEY="whocares"
```

To make those environment variables persistent, copy them into files with the same names:

```
echo "${HZN_ORG_ID}" > HZN_ORG_ID
echo "${HZN_USER_ID}" > HZN_USER_ID
echo "${HZN_EXCHANGE_APIKEY}" > HZN_EXCHANGE_APIKEY
echo "${HZN_EXCHANGE_URL}" > HZN_EXCHANGE_URL
echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE
```

### 1.1.2 Dependencies
Docker provides for build dependencies through the `FROM ` directive in the `Dockerfile`; most services depend on the base service containers for `base-ubuntu` or `base-alpine`.

Build services and containers from the top-level using the following command:

```
make build
```

To build (or push or publish ..) for all services on _all_ architectures, modify the target with `service-` prepended; for example:

```
make service-build
```

# 2. Services & Patterns

Services are defined within a directory hierarchy of this [repository][repository]. All services in this repository share a common [design][design-md].

Examples:

+ [`hello`](./hello/README.md) - The "hello world" example
+ [`esstest`](./esstest/README.md) - A simple test of the [edge-sync-service](http://github.com/open-horizon/edge-sync-service)
+ [`sdr2msghub`](./sdr2msghub/README.md) - Re-packaging of `IBM/sdr2msghub` service w/ `startup`

Services include:

+ [`cpu`](services/cpu/README.md) - provide CPU usage as percentage services/0-100)
+ [`fft`](services/fft/README.md) - Perform FFT analysis on sound
+ [`hal`](services/hal/README.md) - provide Hardware-Abstraction-Layer information
+ [`herald`](services/herald/README.md) - multi-cast data received from other heralds on local-area-network
+ [`hotword`](services/hotword/README.md) - Detect specific _hot_ words
+ [`mqtt`](services/mqtt/README.md) - MQTT message broker service
+ [`motion2mqtt`](services/motion2mqtt/README.md) - transmit motion detected images to MQTT
+ [`mqtt2kafka`](services/mqtt2kafka/README.md) - relay MQTT traffic to Kafka
+ [`mqtt2mqtt`](services/mqtt2mqtt/README.md) - Relay MQTT traffic
+ [`nmap`](services/nmap/README.md) - Provide network map 
+ [`noize`](services/noize/README.md) - Capture noise from silence
+ [`record`](services/record/README.md) - Record audio from a microphone
+ [`wan`](services/wan/README.md) - provide Wide-Area-Network information
+ [`yolo`](services/yolo/README.md) - recognize entities from USB camera
+ [`yolo2msghub`](services/yolo2msghub/README.md) - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka
+ [`yolo4motion`](services/yolo4motion/README.md) - subscribe to MQTT _topics_ from `motion2mqtt`,  recognize entities, and publish results

There are _utility_ services that are used for command and control:

+ [`startup`](services/startup/README.md) - send and receive device information and configuration using ESS/CSS (and Kafka)
+ [`hzncli`](services/hzncli/README.md) - service container with `hzn` command-line-interface installed
+ [`hznsetup`](services/hznsetup/README.md) - Setup new devices as nodes
+ [`hznmonitor`](services/hznmonitor/README.md) - Monitor exchange, organization, patterns, services, nodes, and Kafka for `startup`

There are _base_ containers that are used by the other services:

+ [`base-alpine`](services/base-alpine/README.md) - base container for Alpine LINUX
+ [`base-ubuntu`](services/base-ubuntu/README.md) - base container for Ubuntu LINUX
+ [`apache-ubuntu`](services/apache-ubuntu/README.md) - Apache Web server for Ubuntu
+ [`apache-alpine`](services/apache-alpine/README.md) - Apache Web server for Alpine

Finally, there are services specialized for the [nVidia](http://nvidia.com) GPU enabled computers:

+ [`yolo-cuda`](services/yolo-cuda/README.md) - `yolo` for ARMv8 devices
+ [`yolo-tegra`](services/yolo-tegra/README.md) - `yolo` for ARMv8 devices
+ [`yolo-cuda4motion`](services/yolo-cuda4motion/README.md) - `yolo4motion` for ARMv8 devices
+ [`yolo-tegra4motion`](services/yolo-tegra4motion/README.md) - `yolo4motion` for ARMv8 devices

#  Further Information 

See [`SERVICE.md`][service-md] and [`PATTERN.md`][pattern-md] for more information on building services and patterns.
Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

# Changelog & Releases

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
[edge-slack]: https://ibm-cloudplatform.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup-readme-md]: setup/README.md
[service-md]: docs/SERVICE.md
[cicd-md]: docs/CICD.md
[pattern-md]: docs/PATTERN.md
[status-md]: STATUS.md
[beta-md]: BETA.md

## `CLOC`

Language|files|blank|comment|code
:-------|-------:|-------:|-------:|-------:
Markdown|72|2965|0|16211
JSON|147|1|0|15388
Bourne Shell|202|2386|2354|13309
Dockerfile|38|479|310|1874
make|6|308|231|1146
YAML|4|47|271|733
Bourne Again Shell|16|51|33|340
Python|6|89|106|304
HTML|6|236|2034|220
TOML|5|30|0|205
awk|1|4|0|16
Expect|1|0|0|5
--------|--------|--------|--------|--------
SUM:|504|6596|5339|49751

## Stargazers
[![Stargazers over time](https://starchart.cc/dcmartin/open-horizon.svg)](https://starchart.cc/dcmartin/open-horizon)

<img width="1" src="http://clustrmaps.com/map_v2.png?cl=ada6a6&w=1024&t=n&d=b6TnAROswVvp8u4K3_6FHn9fu7NGlN6T_Rt3dSYwPqI&co=ffffff&ct=050505">