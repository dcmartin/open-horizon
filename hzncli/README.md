# `hzncli` - container with Horizon CLI (Ubuntu)

This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.hzncli.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hzncli "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.hzncli.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hzncli "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.hzncli
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.hzncli.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.hzncli.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hzncli "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.hzncli.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hzncli "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.hzncli
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.hzncli.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.hzncli`
+ `version` - `0.0.3`

## Service variables
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debug settings; boolean; default `false`

## How To Use

Specify `dcmartin/hzn-ubuntu:0.0.1` in service `build.json`

### Building this continer

Copy this [repository][repository], change to the `hzn-ubuntu` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hzn-ubuntu
% make
..
{
  "hzncli": {
    "nodes": null
  },
  "date": 1554314895,
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "https://alpha.edge-fabric.com/v1",
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
    "period": "120",
    "services": null
  },
  "service": {
    "label": "hzncli",
    "version": "0.0.3"
  }
}
```

## &#9937; Service test
To test completely, the service requires instantiation on the development host; use the following commands to set the API key and organizational identifier, then start the service:

```
cd open-horizon/hzncli/
jq '.apiKey' ../apiKey.json > HZN_EXCHANGE_APIKEY
echo '"'${HZN_ORG_ID}'"' > HZN_ORG_ID
make service-start
```

Then a test of the service is performed using:

```
make test
```

The output of the test:

```
>>> MAKE -- 11:15:37 -- testing container: hzncli; tag: dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli:0.0.3
./test.sh "dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli:0.0.3"
--- INFO -- ./test.sh 55960 -- No host specified; assuming 127.0.0.1
+++ WARN ./test.sh 55960 -- No port specified; assuming port 80
+++ WARN ./test.sh 55960 -- No protocol specified; assuming http
--- INFO -- ./test.sh 55960 -- Testing hzncli in container tagged: dcmartin/amd64_com.github.dcmartin.open-horizon.hzncli:0.0.3 at Wed Apr 3 11:15:37 PDT 2019
{"hzncli":{"nodes":"null"},"date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"log_level":"string","debug":"boolean","period":"string","services":"null"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./test.sh 55960 -- test /Volumes/dcmartin/GIT/master/open-horizon/hzncli/test-hzncli.sh returned true
true
```

The resulting status JSON file may also be inspected; it will be named (or something similar):

```
test.amd64_com.github.dcmartin.open-horizon.hzncli:0.0.3.json
```

### Example `hzncli` status

```
{
  "hzncli": {
    "nodes": null
  },
  "date": 1554315330,
  "hzn": {
    "agreementid": "1adcde3cb4a1609eee846b3cc07fed0ad60cbc43e5cbc653dbc41378922503dd",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "https://alpha.edge-fabric.com/v1",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.26",
      "192.168.1.27",
      "9.80.109.129"
    ],
    "organization": "github@dcmartin.com",
    "ram": 1024,
    "pattern": null
  },
  "config": {
    "log_level": "info",
    "debug": false,
    "period": "120",
    "services": null
  },
  "service": {
    "label": "hzncli",
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

[userinput]: ../hzn-ubuntu/userinput.json
[service-json]: ../hzn-ubuntu/service.json
[build-json]: ../hzn-ubuntu/build.json
[dockerfile]: ../hzn-ubuntu/Dockerfile


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
