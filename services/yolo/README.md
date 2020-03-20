# &#128064; `yolo` - You Only Look Once service

Provides entity count information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

### CPU _only_

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo)
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.yolo.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo)
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.yolo.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.yolo
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.yolo.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo)
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

### GPU _accelerated_

[docker-cuda]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda
[pulls-cuda]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda.svg
[cuda-shield]: https://img.shields.io/badge/cuda-yes-green.svg
[![Supports cuda Architecture][cuda-shield]](../yolo-cuda/README.md)
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda)
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-cuda]][docker-cuda]

[docker-tegra]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra
[pulls-tegra]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra.svg
[tegra-shield]: https://img.shields.io/badge/tegra-yes-green.svg
[![Supports tegra Architecture][tegra-shield]](../yolo-tegra/README.md)
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra)
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo-tegra "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-tegra]][docker-tegra]


## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo`
+ `version` - `0.1.2`

## Service variables
+ `YOLO_CONFIG` - configuration of YOLO; `tinyv2`, `tinyv3`,`v2`, or `v3`
+ `YOLO_ENTITY` - entity to count; defaults to `all`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `YOLO_THRESHOLD` - minimum probability; default `0.25`; range `0.0` to `1.0`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - turn on debugging output; `true` or `false`; default `false`

## GPU-enabled versions
There are two version of this service which are enabled with nVidia GPU capabilities, drastically reducing the time required to perform a prediction.

+ [`yolo-cuda`](../yolo-cuda/README.md) - For AMD/Intel 64-bit systems with nVidia GPU supporting CUDA version 10
+ [`yolo-tegra`](../yolo-tegra/README.md) - For nVidia Jetson Nano and other `tegra` devices with JetPack v3.2

For both services the default container run-time for Docker **must** be the `nvidia-container-runtime`.  The `/etc/docker/daemon.json` file must contain the following:

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

Copy this [repository][repository], change to the `yolo` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo
% make
...
{
  "yolo": null,
  "date": 1554316177,
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
    "log_level": "info",
    "debug": false,
    "date": 1554316177,
    "period": 0,
    "entity": "all",
    "scale": "none",
    "config": "tiny",
    "device": "/dev/video0",
    "threshold": 0.25,
    "services": null,
    "names": [
      "person", "bicycle", "car", "motorbike", "aeroplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "sofa", "pottedplant", "bed", "diningtable", "toilet", "tvmonitor", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
    ]
  },
  "service": {
    "label": "yolo",
    "version": "0.0.8"
  }
}
```

The `yolo` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:

```
{
  "yolo": {
    "mock": "eagle",
    "info": {
      "type": "JPEG",
      "size": "773x512",
      "bps": "8-bit",
      "color": "sRGB"
    },
    "time": 0.861101,
    "count": 1,
    "detected": [
      {
        "entity": "bird",
        "count": 1
      }
    ],
    "image": "<redacted>",
    "date": 1554316261
  },
  "date": 1554316177,
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
    "log_level": "info",
    "debug": false,
    "date": 1554316177,
    "period": 0,
    "entity": "all",
    "scale": "none",
    "config": "tiny",
    "device": "/dev/video0",
    "threshold": 0.25,
    "services": null,
    "names": [
      "person", "bicycle", "car", "motorbike", "aeroplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "sofa", "pottedplant", "bed", "diningtable", "toilet", "tvmonitor", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
    ]
  },
  "service": {
    "label": "yolo",
    "version": "0.0.8"
  }
}
```

## Example

![mock-output.jpg](samples/mock-output.jpg?raw=true "YOLO")

## RaspberryPi Camera Module
The Pi’s camera has a discrete set of input modes. On the V2 camera these are as follows:

Number|Resolution|Aspect Ratio|Framerates|Video|Image|FoV|Binning
:-------|-------|-------|-------|-------|-------|-------|-------
1|1920x1080|16:9|0.1-30fps|x|||Partial|None
2|3280x2464|4:3|0.1-15fps|x|x|Full|None
3|3280x2464|4:3|0.1-15fps|x|x|Full|None
4|1640x1232|4:3|0.1-40fps|x|||Full|2x2
5|1640x922|16:9|0.1-40fps|x|||Full|2x2
6|1280x720|16:9|40-90fps|x|||Partial|2x2
7|640x480|4:3|40-90fps|x|||Partial|2x2

### Field-of-View
<img src="https://picamera.readthedocs.io/en/release-1.12/_images/sensor_area_2.png">

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../yolo/userinput.json
[service-json]: ../yolo/service.json
[build-json]: ../yolo/build.json
[dockerfile]: ../yolo/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
