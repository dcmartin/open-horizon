# `alpr4motion` - `alpr` listening for `motion`

Provides automated license plate reader as micro-service listening for MQTT messages.  This service is built from the [`alpr`](../alpr/README.md) service.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr4motion.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.alpr4motion.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr4motion.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.alpr4motion`
+ `version` - `0.0.1`

## Service variables 
+ `ALPR_COUNTRY` -
+ `ALPR_SCALE` - 
+ `ALPR_PATTERN` - 
+ `ALPR_TOPN` - 
+ `ALPR_PERIOD` - seconds between updates; defaults to `60`
+ `MQTT_HOST` - hostname or IP address of MQTT broker; defaults to `mqtt`
+ `MQTT_PORT` - port for MQTT; defaults to `1883`
+ `MQTT_USERNAME` - username for MQTT access; default "" (_empty string_)
+ `MQTT_PASSWORD` - password for MQTT access; default "" (_empty string_)
+ `ALPR4MOTION_GROUP` - topic group; default `+` (_all_)
+ `ALPR4MOTION_DEVICE` - topic device; default `+` (_all_)
+ `ALPR4MOTION_CAMERA` - topic camera; default `+` (_all_)
+ `ALPR4MOTION_TOPIC_EVENT` - topic event; default 'event/end'
+ `ALPR4MOTION_TOPIC_PAYLOAD` - topic payload; default `image`
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

```

The `alpr4motion` service will not operate successfully without an attached camera; when the service is deployed in conjunction with another service, the status output:

```
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
