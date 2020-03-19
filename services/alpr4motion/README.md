# `alpr4motion` - &#128663;`alpr` listening for &#127916;`motion`

Provides automated license plate reader as micro-service listening for MQTT messages.  This service is built from the [`alpr`](../alpr/README.md) service.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.alpr4motion`
+ `version` - `0.0.1`

## Service variables 
+ `ALPR_COUNTRY` - configuration of ALPR; `us`, `eu`
+ `ALPR_PATTERN` - pattern to recognize, for example `va`; defaults to _none_
+ `ALPR_TOPN` - number of interpretations for each plate; default `10`; range `1` to `20`
+ `MQTT_HOST` - hostname or IP address of MQTT broker; defaults to `mqtt`
+ `MQTT_PORT` - port for MQTT; defaults to `1883`
+ `MQTT_USERNAME` - username for MQTT access; default "" (_empty string_)
+ `MQTT_PASSWORD` - password for MQTT access; default "" (_empty string_)
+ `ALPR4MOTION_GROUP` - topic group; default `+` (_all_)
+ `ALPR4MOTION_DEVICE` - topic device; default `+` (_all_)
+ `ALPR4MOTION_CAMERA` - topic camera; default `+` (_all_)
+ `ALPR4MOTION_TOPIC_EVENT` - topic event; default `event/end`
+ `ALPR4MOTION_TOO_OLD` - events older in seconds are ignored; default `300`
+ `ALPR4MOTION_USE_MOCK` - generate mock events for testing
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use

Copy this [repository][repository], change to the `alpr4motion` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/alpr4motion
% make
...
{
  "mqtt": null,
  "alpr4motion": {
    "timestamp": "2020-03-02T21:12:27Z",
    "log_level": "debug",
    "debug": true,
    "group": "motion",
    "device": "+",
    "camera": "+",
    "event": null,
    "old": 300,
    "payload": "image",
    "topic": "motion/+/+",
    "services": [
      {
        "name": "mqtt",
        "url": "http://mqtt"
      }
    ],
    "mqtt": {
      "host": "mqtt.dcmartin.com",
      "port": 1883,
      "username": "username",
      "password": "password"
    },
    "alpr": {
      "log_level": "debug",
      "debug": true,
      "timestamp": "2020-03-02T21:12:27Z",
      "date": 1583183547,
      "period": 10,
      "pattern": "",
      "scale": "none",
      "country": "us",
      "topn": 10,
      "services": [
        {
          "name": "mqtt",
          "url": "http://mqtt"
        }
      ],
      "countries": [
        "br2",
        "in",
        "vn2",
        "br",
        "kr2",
        "sg",
        "mx",
        "kr",
        "auwide",
        "fr",
        "us",
        "eu",
        "au",
        "gb"
      ]
    },
    "date": 1583183547
  },
  "timestamp": "2020-03-02T21:12:27Z",
  "date": 1583183547,
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
  "config": {
    "timestamp": "2020-03-02T21:12:27Z",
    "log_level": "debug",
    "debug": true,
    "group": "motion",
    "device": "+",
    "camera": "+",
    "event": "event/end",
    "old": 300,
    "payload": "image",
    "topic": "motion/+/+",
    "services": [
      {
        "name": "mqtt",
        "url": "http://mqtt"
      }
    ],
    "mqtt": {
      "host": "mqtt.dcmartin.com",
      "port": 1883,
      "username": "username",
      "password": "password"
    },
    "alpr": {
      "log_level": "debug",
      "debug": true,
      "timestamp": "2020-03-02T21:12:27Z",
      "date": 1583183547,
      "period": 10,
      "pattern": "",
      "scale": "none",
      "country": "us",
      "topn": 10,
      "services": [
        {
          "name": "mqtt",
          "url": "http://mqtt"
        }
      ],
      "countries": [
        "br2",
        "in",
        "vn2",
        "br",
        "kr2",
        "sg",
        "mx",
        "kr",
        "auwide",
        "fr",
        "us",
        "eu",
        "au",
        "gb"
      ]
    }
  },
  "service": {
    "label": "alpr4motion",
    "version": "0.0.1",
    "port": 0
  }
}
```

## Sample 

![](samples/sample.jpg?raw=true "ALPR4MOTION")

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../alpr4motion/userinput.json
[service-json]: ../alpr4motion/service.json
[build-json]: ../alpr4motion/build.json
[dockerfile]: ../alpr4motion/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
