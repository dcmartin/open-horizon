# `jetson-jetpack` - Base container for Jetson devices with JetPack

This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.jetson-jetpack.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.jetson-jetpack "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.jetson-jetpack.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.jetson-jetpack "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.jetson-jetpack
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.jetson-jetpack.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.jetson-jetpack.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.jetson-jetpack "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.jetson-jetpack.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.jetson-jetpack "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.jetson-jetpack
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.jetson-jetpack.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.jetson-jetpack.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.jetson-jetpack "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.jetson-jetpack.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.jetson-jetpack "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.jetson-jetpack
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.jetson-jetpack.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.jetson-jetpack`
+ `version` - `0.0.1`

## Service variables
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debug settings; boolean; default `false`

## How To Use

Specify `dcmartin/com.github.dcmartin.open-horizon.jetson-jetpack:0.0.2` in service `build.json`

### Building this continer

Copy this [repository][repository], change to the `base` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/base
% make
...
{
  "hostname": "abec6ffa6455-172017000002",
  "org": "github@dcmartin.com",
  "pattern": "base",
  "device": "tx2.local",
  "pid": 0,
  "jetson-jetpack": {
    "log_level": "info",
    "debug": "false"
  }
}
```

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
