# &#128228; `mqtt2mqtt` - MQTT broker relay

This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2mqtt.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2mqtt.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2mqtt
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.mqtt2mqtt.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2mqtt.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2mqtt.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2mqtt
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.mqtt2mqtt.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.mqtt2mqtt`
+ `version` - `0.0.1`

## Service variables
+ `MQTT2MQTT_HOST` - **REQUIRED** IP or FQDN for mqtt host to receive; defaults to `""`
+ `MQTT_HOST` - MQTT host for in-bound topics; default: `mqtt`
+ `MQTT_PORT` - MQTT port number; defaults to 1883
+ `MQTT_USERNAME` - MQTT username; default `""` (_empty string_); indicating no username
+ `MQTT_PASSWORD` - MQTT password; default `""` (_empty string_); indicating no password
+ `MQTT2MQTT_SUBSCRIBE` - MQTT topic on which to listen for event; defaults to `"+/+/+/event/end"`
+ `MQTT2MQTT_PAYLOAD` - MQTT topic extension for corresponding payload (if any); defaults to `"sound"`
+ `MQTT2MQTT_PUBLISH` - MQTT topic on which to publish; defaults to MQTT receive topic
+ `MQTT2MQTT_TOO_OLD` - events older in seconds are ignored; default `300`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - force debug settings; boolean; default `false`

## Required Services

### [`mqtt`](../mqtt/README.md)
+ `MQTT_PERIOD`
+ `MQTT_PORT`
+ `MQTT_USERNAME`
+ `MQTT_PASSWORD`

### [`wan`](../wan/README.md)
+ `WAN_PERIOD`

## Description
Transmit data received from MQTT broker on specified event and payload topics to specified MQTT broker.

The `MQTT2MQTT_SUBCRIBE` topic is intended to receive JSON payloads containing information about a new sensor event, e.g. motion detection and image classification.

If the `MQTT2MQTT_PAYLOAD` variable is defined, a corresponding payload is retrieved by appending to the receiving topic.

For example, the default `+/+/+/event/end` topic is received as `<group>/<client>/<camera>/event/end`; in the default case, a corresponding payload is expected on the topic `<group>/<client>/<camera>/event/end/image`.

## How To use

Copy this [repository][repository], change to the `mqtt2mqtt` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/mqtt2mqtt
% make
...
{
  "mqtt": null,
  "wan": null,
  "mqtt2mqtt": {
    "date": 1554326429
  },
  "date": 1554326429,
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
    "subscribe": "+/+/+/event/end",
    "payload": "image",
    "publish": "",
    "services": [
      {
        "name": "wan",
        "url": "http://wan"
      },
      {
        "name": "mqtt",
        "url": "http://mqtt"
      }
    ],
    "mqtt": {
      "host": "mqtt",
      "port": 1883,
      "username": "",
      "password": ""
    },
    "wan": null
  },
  "service": {
    "label": "mqtt2mqtt",
    "version": "0.0.1.2"
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
>>> MAKE -- 14:27:22 -- testing container: mqtt2mqtt; tag: dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt:0.0.1
./test.sh "dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt:0.0.1"
--- INFO -- ./test.sh 73518 -- No host specified; assuming 127.0.0.1
+++ WARN ./test.sh 73518 -- No port specified; assuming port 80
+++ WARN ./test.sh 73518 -- No protocol specified; assuming http
--- INFO -- ./test.sh 73518 -- Testing mqtt2mqtt in container tagged: dcmartin/amd64_com.github.dcmartin.open-horizon.mqtt2mqtt:0.0.1 at Wed Apr 3 14:27:22 PDT 2019
{"mqtt":{"date":"number","pid":"number","version":"string","broker":{"bytes":{"received":"number","sent":"number"},"clients":{"connected":"number"},"load":{"messages":{"messages":"object"}},"publish":{"messages":{"messages":"object"}},"subscriptions":{"count":"number"}}},"wan":{"date":"number"},"mqtt2mqtt":{"date":"number"},"date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"log_level":"string","debug":"boolean","subscribe":"string","payload":"string","publish":"string","services":["object","object"],"mqtt":{"host":"string","port":"number","username":"string","password":"string"},"wan":"null"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./test.sh 73518 -- test /Volumes/dcmartin/GIT/master/open-horizon/mqtt2mqtt/test-mqtt2mqtt.sh returned true
true
```

The resulting status JSON file may also be inspected; it will be named (or something similar):

```
test.amd64_com.github.dcmartin.open-horizon.mqtt2mqtt:0.0.1.json
```

### Example `mqtt2mqtt` status

```
{
  "mqtt": {
    "date": 1554331899,
    "pid": 29,
    "version": "mosquitto version 1.4.15",
    "broker": {
      "bytes": {
        "received": 369,
        "sent": 738
      },
      "clients": {
        "connected": 0
      },
      "load": {
        "messages": {
          "sent": {
            "one": 38.97,
            "five": 8.74,
            "fifteen": 2.97
          },
          "received": {
            "one": 38.97,
            "five": 8.74,
            "fifteen": 2.97
          }
        }
      },
      "publish": {
        "messages": {
          "received": 0,
          "sent": 15,
          "dropped": 0
        }
      },
      "subscriptions": {
        "count": 0
      }
    }
  },
  "wan": {
    "date": 1554331890,
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
      "bytes_sent": 17735680,
      "download": 288342084.0949062,
      "timestamp": "2019-04-03T22:51:04.590292Z",
      "share": null,
      "bytes_received": 362642072,
      "ping": 12.53,
      "upload": 10327801.215895178,
      "server": {
        "latency": 12.53,
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
  "mqtt2mqtt": {
    "date": 1554331865
  },
  "date": 1554331865,
  "hzn": {
    "agreementid": "71aa1884c902f0c3baebaff5fc72d8f0e4bd21768eb68faa44591bcc6a2477d8",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "http://exchange:3090/v1",
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
    "subscribe": "+/+/+/event/end",
    "payload": "image",
    "publish": "",
    "services": [
      {
        "name": "wan",
        "url": "http://wan"
      },
      {
        "name": "mqtt",
        "url": "http://mqtt"
      }
    ],
    "mqtt": {
      "host": "mqtt",
      "port": 1883,
      "username": "",
      "password": ""
    },
    "wan": null
  },
  "service": {
    "label": "mqtt2mqtt",
    "version": "0.0.1.2"
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

[userinput]: ../mqtt2mqtt/userinput.json
[service-json]: ../mqtt2mqtt/service.json
[build-json]: ../mqtt2mqtt/build.json
[dockerfile]: ../mqtt2mqtt/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
