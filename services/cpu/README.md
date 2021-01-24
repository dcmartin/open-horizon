# `cpu` - CPU usage

Provides CPU usage information as micro-service; updates periodically (default `60` seconds or 1 minute).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_cpu.svg)](https://microbadger.com/images/dcmartin/amd64_cpu "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_cpu.svg)](https://microbadger.com/images/dcmartin/amd64_cpu "Get your own version badge on microbadger.com")
[![](https://img.shields.io/docker/pulls/dcmartin/amd64_cpu.svg)](https://hub.docker.com/r/dcmartin/amd64_cpu)

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_cpu.svg)](https://microbadger.com/images/dcmartin/arm_cpu "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_cpu.svg)](https://microbadger.com/images/dcmartin/arm_cpu "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_cpu
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_cpu.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_cpu.svg)](https://microbadger.com/images/dcmartin/arm64_cpu "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_cpu.svg)](https://microbadger.com/images/dcmartin/arm64_cpu "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_cpu
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_cpu.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `cpu`
+ `version` - `0.0.3`

## Service variables

+ `CPU_PERIOD` - seconds between updates; defaults to `60`
+ `CPU_INTERVAL` - seconds between CPU tests; defaults to `1`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use
Copy this [repository][repository], change to the `cpu` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/cpu
% make
...
{
  "cpu": {
    "date": 1554314683
  },
  "date": 1554314683,
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
    "period": "60",
    "interval": "1",
    "services": null
  },
  "service": {
    "label": "cpu",
    "version": "0.0.3"
  }
}
```
The `cpu` payload will be incomplete until the service initiates; subsequent `make check` will return complete; see below:
```
{
  "cpu": {
    "date": 1554314684,
    "percent": 5.27
  },
  "date": 1554314683,
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
    "period": "60",
    "interval": "1",
    "services": null
  },
  "service": {
    "label": "cpu",
    "version": "0.0.3"
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/cpu/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/cpu/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/cpu/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/cpu/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
