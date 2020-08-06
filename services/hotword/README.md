# &#128483; `hotword` - listen for commands

Processes sound and recognizes hotwords from a specified model. This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_hotword.svg)](https://microbadger.com/images/dcmartin/amd64_hotword "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_hotword.svg)](https://microbadger.com/images/dcmartin/amd64_hotword "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_hotword
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_hotword.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_hotword.svg)](https://microbadger.com/images/dcmartin/arm_hotword "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_hotword.svg)](https://microbadger.com/images/dcmartin/arm_hotword "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_hotword
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_hotword.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_hotword.svg)](https://microbadger.com/images/dcmartin/arm64_hotword "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_hotword.svg)](https://microbadger.com/images/dcmartin/arm64_hotword "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_hotword
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_hotword.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `hotword`
+ `version` - `0.0.1`

## Service variables
+ `HOTWORD_GROUP` - group name (aka top-level topic); defaults to `"hotword"`
+ `HOTWORD_CLIENT` - client name; default: `""`; set to `HZN_DEVICE_ID` or `hostname`
+ `HOTWORD_EVENT` - topic for sound event detected; default: `"+/+/+/event/start"`
+ `HOTWORD_PAYLOAD` - extension to event topic to collect payload; default: `"sound"`
+ `HOTWORD_MODEL` - default: `"alexa"`
+ `HOTWORD_INCLUDE_WAV` - include audio as base64 encoded WAV; default: `false`
+ `LOGTO` - specify place to log; default: `"/dev/stderr"`; use `""` for `${TMPDIR}/${0##*/}.log`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`; currently ignored)
+ `DEBUG` - default: `false`

## Required Services

### [`mqtt`](../mqtt/README.md)
+ `MQTT_PORT` - port number; defaults to `1883`
+ `MQTT_USERNAME` - MQTT username; defaults to ""
+ `MQTT_PASSWORD` - MQTT password; defaults to ""

## How To Use
Copy this [repository][repository], change to the `hotword` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hotword
% make
...
```

The `hotword` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

```
```

**EXAMPLE**

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../hotword/userinput.json
[service-json]: ../hotword/service.json
[build-json]: ../hotword/build.json
[dockerfile]: ../hotword/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
