# &#128065; `yolo` - You Only Look Once service

Provides entity count information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda)
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo-cuda.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo-cuda`
+ `version` - `0.1.2`

## Service variables
+ `YOLO_CONFIG` - configuration of YOLO; `tinyv2`, `tinyv3`,`v2`, or `v3`
+ `YOLO_ENTITY` - entity to count; defaults to `all`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `YOLO_THRESHOLD` - minimum probability; default `0.25`; range `0.0` to `1.0`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - turn on debugging output; `true` or `false`; default `false`

## ONLY AMD64/nVidia GPU
This container will only run on AMD64 achitecture with nVidia GPU.  In addition, Docker must be configured to use the nVidia Container runtime as the default; for example `/etc/docker/daemon.json` should contain:

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
