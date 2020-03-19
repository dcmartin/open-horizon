# `yolo4motion` - &#128065;`yolo-tegra` listening for &#127916;`motion`

Provides entity count information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra4motion
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra4motion.svg
[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo-tegra4motion`
+ `version` - `0.1.2`

## Service variables 
+ `YOLO_CONFIG` - configuration: `tiny`|`tinyv2`, `tinyv3`, `v2`, `v3`; default: `tiny`
+ `YOLO_SCALE` - width and height to scale image; defaults to `none`
+ `YOLO_ENTITY` - entity to count; defaults to `all`
+ `YOLO_THRESHOLD` - entity to count; defaults to `0.25`
+ `YOLO_PERIOD` - seconds between updates; defaults to `60`
+ `MQTT_HOST` - hostname or IP address of MQTT broker; defaults to `mqtt`
+ `MQTT_PORT` - port for MQTT; defaults to `1883`
+ `MQTT_USERNAME` - username for MQTT access; default "" (_empty string_)
+ `MQTT_PASSWORD` - password for MQTT access; default "" (_empty string_)
+ `YOLO4MOTION_GROUP` - topic group; default `+` (_all_)
+ `YOLO4MOTION_DEVICE` - topic device; default `+` (_all_)
+ `YOLO4MOTION_CAMERA` - topic camera; default `+` (_all_)
+ `YOLO4MOTION_TOPIC_EVENT` - topic event; default 'event/end'
+ `YOLO4MOTION_TOPIC_PAYLOAD` - topic payload; default `image`
+ `YOLO4MOTION_TOO_OLD` - events older in seconds are ignored; default `300`
+ `YOLO4MOTION_USE_MOCK` - generate mock events for testing
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## &#9995; nVidia Jetson _only_
This container will only run on nVidia Jetson computers, e.g. Jetson Nano or TX2, with the latest JetPack installed.  In addition, Docker must be configured to use the nVidia Container runtime as the default; for example `/etc/docker/daemon.json` should contain:

```
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

## How To Use
Please see the [`yolo4motion`](../yolo4motion/README.md) documentation for more information.

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
