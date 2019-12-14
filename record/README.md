# &#127908; `record` - record sound periodically

Monitors attached microphone and provides `arecord` functionality as micro-service, providing WAV data.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status &#128679;

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.record "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.record "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.record
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.record.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.record "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.record "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.record
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.record.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.record "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.record "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.record
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.record.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.record`
+ `version` - `0.0.1`

## Service variables
+ `RECORD_DEVICE` - device to record sound; default: `PS3 Eye camera microphone identifier`
+ `RECORD_PERIOD` - interval to poll audio device; default: `10` seconds
+ `RECORD_SECONDS` - amount of time to record; default: `5` seconds
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - default: `false`

## How To Use
Copy this [repository][repository], change to the `record` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/record
% make
...
```

The `record` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

**EXAMPLE**

```
{   
  "date": 1555192656,
  "hzn": { "agreementid": "ca200f9e5620cde9ad9d36384de52c0fcd307e8f0b22428a2f55da71ef4ac403", "arch": "arm", "cpus": 1, "device_id": "test-cpu-2", "exchange_url": "https://alpha.edge-fabric.com/v1/", "host_ips": [ "127.0.0.1", "192.168.1.52", "172.17.0.1", "172.18.0.1", "169.254.179.194" ], "organization": "github@dcmartin.com", "ram": 0, "pattern": "record" },
  "service": { "label": "record", "version": "0.0.1", "port": "9192" },
  "config": {
    "log_level": "info",
    "debug": true,
    "device": "/dev/video0",
    "period": 10,
    "seconds": 5,
    "sample_rate": 19200,
    "services": null
  },  
  "record": {
    "type": "WAV",
    "start": 1555541712,
    "finish": 1555541717,
    "id": "test-cpu-1-20190417225512",
    "audio": "<redacted>",
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

[userinput]: ../record/userinput.json
[service-json]: ../record/service.json
[build-json]: ../record/build.json
[dockerfile]: ../record/Dockerfile


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
