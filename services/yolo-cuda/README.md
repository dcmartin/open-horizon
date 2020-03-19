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

## &#9995; AMD64/nVidia GPU _only_
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

## Install `nvidia-container-runtime`

```
sudo apt install gnupg2 pass
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
sudo apt-get install nvidia-container-runtime
```

## How To Use
Please see the [`yolo`](../yolo/README.md) documentation for more information.

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
