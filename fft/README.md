# &#8497; `fft` - perform FFT anomaly analysis

Monitors attached microphone using `record` service and provides FFT functionality as micro-service, processing WAV data and producing JSON and PNG output.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.fft.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.fft "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.fft.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.fft "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.fft
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.fft.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.fft.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.fft "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.fft.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.fft "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.fft
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.fft.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.fft.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.fft)
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.fft.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.fft)
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.fft
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.fft.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.fft`
+ `version` - `0.0.1`

## Service variables

+ `FFT_ANOMALY_GROUP` - group for MQTT topics; default `fft`
+ `FFT_ANOMALY_CLIENT` - client identifier; defaults to `HZN_DEVICE_ID` or `hostname`
+ `FFT_ANOMALY_TYPE` - type of anomaly; default: `"motor"`
+ `FFT_ANOMALY_LEVEL` - level indicating anomaly; default: `0.2` for `motor`
+ `FFT_ANOMALY_MOCK` - generate mock anomaly; default: `false`; options: `true`, `false`
+ `FFT_INCLUDE_RAW` - include raw results; default: `false`; options: `true`, `false`
+ `FFT_INCLUDE_PNG` - include image results; default: `false`; options: `true`, `false`
+ `FFT_INCLUDE_WAV` - include audio; default: `false`; options: `true`, `false`
+ `FFT_PERIOD` - interval to poll for new recording; default: `5`; range: \(0,+\)
+ `MQTT_HOST` - default: `mqtt`
+ `MQTT_PORT` - default: `1883`
+ `MQTT_USERNAME` - default: `""`
+ `MQTT_PASSWORD` - default: `""`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - default: `false`

## Required Services

### [`record`](../record/README.md)
+ `RECORD_DEVICE` - device to record sound; default: *default system device*
+ `RECORD_PERIOD` - interval to poll audio device; default: `10.0` seconds
+ `RECORD_SECONDS` - amount of time to record; default: `5.0` seconds

### [`mqtt`]()
+ `MQTT_PERIOD`

## Description
This service provides a variety of FFT based anomaly detectors to provide data that may be used for temporal analysis of sound.  The service makes use of the `record` service to poll the device's microphone and collect audio.  The `fft` service polls the `record` service output and when updated, performs the specified anomaly detector (n.b. `FFT_ANOMALY_TYPE`), updating its output to include both the BASE64 encoded audio, but also the analysis data in both BASE64 encoded Python `numpy` array as well as a JSON array.

The `fft` service provides a ReStful API on its designated port and returns a JSON payload; see **EXAMPLE** below.

Options for anomaly analysis:


+ `motor` - perform [Welch](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html) power spectral density and compare between readings for variation in top signal and signal strength.
+ `butter` - perform [Butterworth order 3](https://docs.scipy.org/doc/scipy-0.14.0/reference/generated/scipy.signal.butter.html) [signal filter](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.lfilter.html)
+ `welch` - perform [Welch](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html) power spectral density

## How To Use
Copy this [repository][repository], change to the `fft` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/fft
% make
...
```

The `fft` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

**EXAMPLE**

```
{
  "mqtt": {
    "date": 1556054659,
    "pid": 71,
    "version": "mosquitto version 1.4.15",
    "broker": {
      "bytes": {
        "received": 16894449,
        "sent": 2049
      },
      "clients": {
        "connected": 0
      },
      "load": {
        "messages": {
          "sent": {
            "one": 82.43,
            "five": 23.85,
            "fifteen": 8.5
          },
          "received": {
            "one": 105.6,
            "five": 32.46,
            "fifteen": 11.72
          }
        }
      },
      "publish": {
        "messages": {
          "received": 15,
          "sent": 46,
          "dropped": 0
        }
      },
      "subscriptions": {
        "count": 0
      }
    }
  },
  "fft": {
    "date": 1556054668,
    "type": "motor",
    "level": 0.2,
    "id": "davidsimac.local",
    "record": {
      "mock": "mixer_1",
      "date": 1556054666,
      "audio": true
    },
    "motor": {
      "data": [
        6890.625,
        4976.8681640625,
        1205.859375,
        1966.3599853515625,
        "true",
        "true",
        "true",
        "true"
      ],
      "image": true
    }
  },
  "date": 1556054571,
  "hzn": {
    "agreementid": "0001b487674e63737d84fbcdc011eaf365a39477a31f5feb20960040aaad154d",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "https://alpha.edge-fabric.com/v1",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.27",
      "192.168.1.26",
      "9.80.94.82"
    ],
    "organization": "github@dcmartin.com",
    "ram": 1024,
    "pattern": null
  },
  "config": {
    "log_level": "info",
    "debug": true,
    "period": 5,
    "type": "motor",
    "level": 0.2,
    "mock": true,
    "raw": false,
    "wav": true,
    "services": [
      {
        "name": "mqtt",
        "url": "http://mqtt"
      }
    ]
  },
  "service": {
    "label": "fft",
    "version": "0.0.1"
  }
}
```

## SAMPLE
A provided `square.wav` file, which may also be created using the `rootfs/usr/bin/mksqwave.sh` script is used as one of the mock data sets.

### `raw`
<img width=512 src="sample/square.png">

### `butter`
<img width=512 src="sample/butter.png">

### `welch`
<img width=512 src="sample/welch.png">

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../fft/userinput.json
[service-json]: ../fft/service.json
[build-json]: ../fft/build.json
[dockerfile]: ../fft/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
