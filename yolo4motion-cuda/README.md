# `yolo4motion` - `yolo` listening for `motion`

Provides entity count information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo4motion.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo4motion.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo4motion
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo4motion.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.yolo4motion.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo4motion "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo4motion.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo4motion "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo4motion
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo4motion.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo4motion`
+ `version` - `0.0.1`

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

## How To Use

Copy this [repository][repository], change to the `yolo4motion` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo4motion
% make
...
{
  "yolo4motion": null,
  "date": 1554317838,
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
    "label": "yolo4motion",
    "version": "0.0.4.3"
  }
}
```

The `yolo4motion` service will not operate successfully without an attached camera; when the service is deployed in conjunction with another service, the status output:

```
{
  "yolo4motion": {
    "date": 1548702367,
    "device": "test-cpu-2",
    "log_level": "info",
    "debug": "false",
    "period": 0,
    "entity": "person",
    "time": 38.565109,
    "count": 0,
    "width": 320,
    "height": 240,
    "scale": "320x240",
    "mock": "false",
    "image": "<redacted>"
  },
  "date": 1554174883,
  "hzn": {
    "agreementid": "",
    "arch": "arm",
    "cpus": 1,
    "device_id": "test-cpu-3",
    "exchange_url": "https://alpha.edge-fabric.com/v1/",
    "host_ips": [
      "127.0.0.1",
      "192.168.160.1",
      "192.168.1.167",
      "172.17.0.1"
    ],
    "organization": "github@dcmartin.com",
    "ram": 0,
    "pattern": "github@dcmartin.com/motion2mqtt"
  },
  "config": null,
  "service": {
    "label": "yolo4motion",
    "version": "0.0.4.3"
  }
}
```
## Sample 

![sample.png](samples/sample.png?raw=true "YOLO4MOTION")

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../yolo4motion/userinput.json
[service-json]: ../yolo4motion/service.json
[build-json]: ../yolo4motion/build.json
[dockerfile]: ../yolo4motion/Dockerfile


[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
