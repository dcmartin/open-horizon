# `nosqldb` - PouchDB Server

This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.nosqldb.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.nosqldb "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.nosqldb.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.nosqldb "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.nosqldb
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.nosqldb.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.nosqldb.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.nosqldb "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.nosqldb.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.nosqldb "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.nosqldb
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.nosqldb.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.nosqldb.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.nosqldb "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.nosqldb.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.nosqldb "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.nosqldb
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.nosqldb.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.nosqldb`
+ `version` - `0.0.2`

## Service variables
+ `NOSQLDB_PORT` - port; default: `5984`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debug settings; boolean; default `false`

## How To Use

Copy this [repository][repository], change to the `nosqldb` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/nosqldb
% make
...
{
  "nosqldb": null,
  "date": 1554315853,
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
    "ram": 0,
    "pattern": null
  },
  "config": null,
  "service": {
    "label": "nosqldb",
    "version": "0.0.2"
  }
}
```

The `nosqldb` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:

```
{
  "nosqldb": {
    "date": 1554315868,
    "pid": 30,
    "version": "mosquitto version 1.4.15",
    "broker": {
      "bytes": {
        "received": 8304505370,
        "sent": 7894992284
      },
      "clients": {
        "connected": 1
      },
      "load": {
        "messages": {
          "sent": {
            "one": 922.8,
            "five": 967.88,
            "fifteen": 1043.74
          },
          "received": {
            "one": 2484.32,
            "five": 2687,
            "fifteen": 2903.34
          }
        }
      },
      "publish": {
        "messages": {
          "received": 1021075,
          "sent": 30789,
          "dropped": 0
        }
      },
      "subscriptions": {
        "count": 153
      }
    }
  },
  "date": 1554315853,
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
    "ram": 0,
    "pattern": null
  },
  "config": null,
  "service": {
    "label": "nosqldb",
    "version": "0.0.2"
  }
}
```

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## User Input (options)
Nodes should _register_ using a derivative of the template `userinput.json` [file][userinput].  Options include:
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debugging mode; boolean; default `false`

## About Open Horizon

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.

## Credentials

**Note:** _You will need an IBM Cloud [account][ibm-registration]_

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your IBMid.  An API key will be provided for an IBM sponsored Kafka service during the alpha phase.  The same API key is used for both the CPU and SDR addon-patterns.

# Setup

Refer to these [instructions][setup].  Installation package for macOS is also [available][macos-install]

# Further Information

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../nosqldb/userinput.json
[service-json]: ../nosqldb/service.json
[build-json]: ../nosqldb/build.json
[dockerfile]: ../nosqldb/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
