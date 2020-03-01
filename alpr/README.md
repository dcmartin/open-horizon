# &#128663; `alpr` - Automated license plate reader

Provides license plate information as micro-service; updates periodically (default `0` seconds).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.alpr.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.alpr.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.alpr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.alpr.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.alpr "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.alpr
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.alpr.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.alpr.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.alpr`
+ `version` - `0.0.8`

## Service variables
+ `ALPR_CONFIG` - configuration of ALPR; `us`, `eu`
+ `ALPR_PATTERN` - pattern to recognize, for example `va`; defaults to _none_
+ `ALPR_PERIOD` - seconds between updates; defaults to `0`
+ `ALPR_TOPN` - number of interpretations for each plate; default `10`; range `1` to `20`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - turn on debugging output; `true` or `false`; default `false`

## How To Use

Copy this [repository][repository], change to the `alpr` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/alpr
% make
...

```

The `alpr` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:

```
```

## Example

![](samples/ea7the-alpr.jpg?raw=true "EA7THE")
![](samples/h786poj-alpr.jpg?raw=true "H786POJ")

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../alpr/userinput.json
[service-json]: ../alpr/service.json
[build-json]: ../alpr/build.json
[dockerfile]: ../alpr/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
