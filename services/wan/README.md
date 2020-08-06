# `wan` - Wide-Area-Network monitoring service

Monitors Internet access information as micro-service; updates periodically (default `1800` seconds or 15 minutes).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_wan.svg)](https://microbadger.com/images/dcmartin/amd64_wan "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_wan.svg)](https://microbadger.com/images/dcmartin/amd64_wan "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_wan
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_wan.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_wan.svg)](https://microbadger.com/images/dcmartin/arm_wan "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_wan.svg)](https://microbadger.com/images/dcmartin/arm_wan "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_wan
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_wan.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_wan.svg)](https://microbadger.com/images/dcmartin/arm64_wan "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_wan.svg)](https://microbadger.com/images/dcmartin/arm64_wan "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_wan
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_wan.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `wan`
+ `version` - `0.0.1`

## Service variables
+ `WAN_PERIOD` - seconds between updates; defaults to `1800`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use

Copy this [repository][repository], change to the `wan` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/wan
% make
...
{
  "wan": {
    "date": 1554316055
  },
  "date": 1554316055,
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
    "period": "1800",
    "services": null
  },
  "service": {
    "label": "wan",
    "version": "0.0.3"
  }
}
```

The `wan` payload will be incomplete until the service initiates; subsequent `make check` will return complete; see below:

```
{
  "wan": {
    "date": 1554316080,
    "speedtest": {
      "client": {
        "rating": "0",
        "loggedin": "0",
        "isprating": "3.7",
        "ispdlavg": "0",
        "ip": "67.169.35.196",
        "isp": "Comcast Cable",
        "lon": "-121.7875",
        "ispulavg": "0",
        "country": "US",
        "lat": "37.2329"
      },
      "bytes_sent": 17776640,
      "download": 293909407.83393836,
      "timestamp": "2019-04-03T18:27:35.965955Z",
      "share": null,
      "bytes_received": 368444545,
      "ping": 11.965,
      "upload": 11112862.225383956,
      "server": {
        "latency": 11.965,
        "name": "San Jose, CA",
        "url": "http://speedtest.sjc.sonic.net/speedtest/upload.php",
        "country": "United States",
        "lon": "-121.8727",
        "cc": "US",
        "host": "speedtest.sjc.sonic.net:8080",
        "sponsor": "Sonic.net, Inc.",
        "lat": "37.3041",
        "id": "17846",
        "d": 10.9325856080155
      }
    }
  },
  "date": 1554316055,
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
    "period": "1800",
    "services": null
  },
  "service": {
    "label": "wan",
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

[userinput]: ../wan/userinput.json
[service-json]: ../wan/service.json
[build-json]: ../wan/build.json
[dockerfile]: ../wan/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
