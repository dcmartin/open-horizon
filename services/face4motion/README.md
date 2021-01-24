# `face4motion` - &#9786;`face` listening for &#127916;`motion`

Provides face detection s micro-service listening for MQTT messages.  This service is built from the [`face`](../face/README.md) service.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_face4motion.svg)](https://microbadger.com/images/dcmartin/amd64_face4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_face4motion.svg)](https://microbadger.com/images/dcmartin/amd64_face4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_face4motion
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_face4motion.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_face4motion.svg)](https://microbadger.com/images/dcmartin/arm_face4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_face4motion.svg)](https://microbadger.com/images/dcmartin/arm_face4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_face4motion
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_face4motion.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_face4motion.svg)](https://microbadger.com/images/dcmartin/arm64_face4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_face4motion.svg)](https://microbadger.com/images/dcmartin/arm64_face4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_face4motion
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_face4motion.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `face4motion`
+ `version` - `0.0.1`

## Service variables 
+ `FACE_THRESHOLD` - minimum confidence percent; default `1`; range `1` to `99`
+ `MQTT_HOST` - hostname or IP address of MQTT broker; defaults to `mqtt`
+ `MQTT_PORT` - port for MQTT; defaults to `1883`
+ `MQTT_USERNAME` - username for MQTT access; default "" (_empty string_)
+ `MQTT_PASSWORD` - password for MQTT access; default "" (_empty string_)
+ `FACE4MOTION_GROUP` - topic group; default `+` (_all_)
+ `FACE4MOTION_DEVICE` - topic device; default `+` (_all_)
+ `FACE4MOTION_CAMERA` - topic camera; default `+` (_all_)
+ `FACE4MOTION_TOPIC_EVENT` - topic event; default `event/end`
+ `FACE4MOTION_TOO_OLD` - events older in seconds are ignored; default `300`
+ `FACE4MOTION_USE_MOCK` - generate mock events for testing
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use

Copy this [repository][repository], change to the `face4motion` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/face4motion
% make
...

```

## Sample 

![](samples/sample.jpg?raw=true "FACE4MOTION")

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../face4motion/userinput.json
[service-json]: ../face4motion/service.json
[build-json]: ../face4motion/build.json
[dockerfile]: ../face4motion/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
