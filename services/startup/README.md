# &#128118; `startup` - first pattern for a new node

Provides an initial pattern for a new device to become a node; includes the `cpu`, `hal`, `wan` services to provide details on hardware, devices, local storage, and Internet connectivity. Include `mqtt` for local communications, `apache` for a local web service, and `mqtt2kafka` to transmit device details to the cloud.   This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_startup.svg)](https://microbadger.com/images/dcmartin/amd64_startup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_startup.svg)](https://microbadger.com/images/dcmartin/amd64_startup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_startup
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_startup.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_startup.svg)](https://microbadger.com/images/dcmartin/arm_startup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_startup.svg)](https://microbadger.com/images/dcmartin/arm_startup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_startup
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_startup.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_startup.svg)](https://microbadger.com/images/dcmartin/arm64_startup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_startup.svg)](https://microbadger.com/images/dcmartin/arm64_startup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_startup
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_startup.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `startup`
+ `version` - `0.0.1`

## Service ports
+ `3093` - `startup` service status; returns `application/json`

## Service variables
+ `STARTUP_SYNC_PERIOD` - seconds between ESS/CSS polling; default `10` seconds
+ `STARTUP_HOST_USER` - `ssh` account identifier for device/host
+ `STARTUP_KAFKA_APIKEY` - API key for Kafka; **required**
+ `STARTUP_KAFKA_ADMIN_URL` - Kafka administrative URL; default provided
+ `STARTUP_KAFKA_BROKER` - Kafka brokers; default provided
+ `STARTUP_PERIOD` - seconds between start-up notifications; default: `600` seconds
+ `LOGTO` - specify place to log; default: `"/dev/stderr"`; use `""` for `"${TMPDIR}/${0##*/}.log"`
+ `LOG_LEVEL` - specify level of logging; default: `"info"`; options below
+ `DEBUG` - default: `false`

### Log levels

+ `emerg` - Emergencies - system is unusable.   
+ `alert` - Action must be taken immediately.   
+ `crit` - Critical Conditions.    
+ `error` - Error conditions.   
+ `warn` - Warning conditions.  
+ `notice` - Normal but significant condition.   
+ `info` - Informational.  
+ `debug` - Debug-level messages    

## Required Services
+ [`hal`](../hal/README.md)
+ [`wan`](../wan/README.md)

## Description
Provide an initial pattern to new devices upon automated setup using the `hznsetup` pattern.  Collect local device information using the `hal` and `wan` services and transmit to Kafka in the IBM Cloud.  Provide Apache2 HTTP Web server for HTML pages and CGI scripts with ExtendedStatus enabled (*local* only).

## How To Use


### Configure `ssh` 
Access from the service to the host computer is performed using the `ssh` command. To enable secure access for the `startup` service a public key must be installed on the host device account; in addition the private key must be BASE64 encoded and provided to the service via the _edge sync service_ (ESS).

#### Step 1
Create a public/private key pair; the name should be the same as the `SERVICE_LABEL`; for example, the value `startup`:

```
ssh-keygen -t rsa -f "startup" -N ""
```

#### Step 2
Encode the private key and the account identifier for the target device and store as JSON strings. These files are used in development _only_ and the actual deployed _pattern_ must specify in the `userinput.json` file.

```
echo '"'$(base64 startup)'"' > STARTUP_HOST_KEY
echo '"'$(whoami)'"' > STARTUP_HOST_USER
```

#### Step 3
Add the public key to the targeted device; for example, the default `localhost` device:

```
cat startup.pub >> ~/.ssh/authorized_keys
```

#### Step 4
Test access to the target device(s) using the specified credentials, for example:

```
ssh -i startup -l localhost -l $(whoami)
```


## How To Build
Copy this [repository][repository], change to the `startup` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/startup
% make
...
```

### `make check`
Once the service has been `built`, `run`, and `check` the first time, subsequent `check` will yield status output including the `wan` and `hal` attributes (see below).  In addition, the `hzn` attributes are _only_ defined when the service is run using `make start` (a.k.a. `hzn dev service start` command) or when the service is deployed in a _pattern_.

```
% make check
```

```
{
  "wan": null,
  "hal": null,
  "startup": {
    "timestamp": "2019-06-26T17:17:43Z",
    "date": 1561569463
  },
  "timestamp": "2019-06-26T17:17:43Z",
  "date": 1561569463,
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": "",
    "device_id": "",
    "ess_api_address": "",
    "ess_api_port": "",
    "ess_api_protocol": "",
    "ess_auth": "",
    "ess_cert": "",
    "exchange_url": "",
    "organization": "",
    "ram": "",
    "host_ips": [
      ""
    ],
    "pattern": null
  },
  "config": {
    "logto": "/tmpfs/run.sh.log",
    "date": 1561569463,
    "timestamp": "2019-06-26T17:17:43Z",
    "log_level": "info",
    "debug": false,
    "services": [
      {
        "name": "hal",
        "url": "http://hal"
      },
      {
        "name": "wan",
        "url": "http://wan"
      }
    ],
    "sync": {
      "org": "",
      "period": 10
    },
    "period": 60,
    "kafka": {
      "apikey": "<redacted>",
      "broker": "kafka05-prod02.messagehub.services.us-south.bluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093",
      "admin": "https://kafka-admin-prod02.messagehub.services.us-south.bluemix.net:443"
    }
  },
  "service": {
    "label": "startup",
    "version": "0.0.1.3"
  }
}
```

### `make start`
Starting the service using the `hzn dev service start` command is performed through the `start` target:

```
% make start
>>> MAKE -- 10:31:09 -- stop: amd64_startup-beta
>>> MAKE -- 10:31:09 -- stop-service: startup-beta; directory: horizon/
>>> MAKE -- 10:31:09 -- stop: amd64_startup-beta
Created horizon metadata files in /Volumes/dcmartin/GIT/open-horizon/beta/startup/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 10:31:10 -- fetching dependencies; service: startup; dir: horizon
>>> MAKE -- 10:31:11 -- starting service: startup-beta; directory: horizon
Service project /Volumes/dcmartin/GIT/open-horizon/beta/startup/horizon verified.
Service project /Volumes/dcmartin/GIT/open-horizon/beta/startup/horizon verified.
Service project /Volumes/dcmartin/GIT/open-horizon/beta/startup/horizon verified.
File sync service container openhorizon.hzn-dev.css-api listening on host port 8580
Start service: service(s) hal with instance id prefix hal-beta_0.0.3_ef956903-2af5-4e5d-9cd2-d90499c724e5
Running service.
Start service: service(s) wan with instance id prefix wan-beta_0.0.3_fee3e95d-2da7-4681-a83a-a4556537d81a
Running service.
Start service: service(s) startup with instance id prefix 9ae15635734a85149a2faebebfd0a7d11d6fead7d4c25da2971104245b5ac8dd
Running service.
>>> MAKE -- 10:31:20 -- started service: startup-beta; directory: horizon/
```

The service is now fully operational with both the `hal` and `wan` service running and the local edge sync service.  Using `curl` to access the service status yields [a very large JSON file](samples/service.json) that includes those services output as well as the information available from the Docker socket.

Additional data is captured once host private `SSH` key is provided via the ESS in a configuration update.  When a correct key is received, the service status will include information on both the local network (`nmap`) and the local agent and exchange (`hzn`).


## Edge Sync Service
The [_edge sync service_](http://github.com/open-horizon/edge-sync-service/) (ESS) provides a mechanism to _get_ and _put_ information **from** and **to** the "Cloud" and the nodes in an organization.  The `startup` service _put_ its service output to the ESS and a corresponding service, `hznsetup`, _get_ that information; similarly, the `hznsetup` service will _put_ the `SSH` private key in a configuration update for that node; and finally, the appropriate node will receive that update and will utilize the provided key to access the specified `STARTUP_HOST_ACCOUNT` and retrieve the `nmap` and `hzn` information, which will be included in the next service output update (n.b. provided via ReStful API _and_ ESS).

This process can be tested in the development environment using two special `make` targets for the `startup` service:

### `make css-get`
This target will retrieve the service status output from the locally running `startup` using the ESS; this output is saved as _machine_.json file and may be compared to the `check.son` file created with the `make check` target.

### `make css-put`
This target will send the service a configuration update with the private key for the service, i.e. `startup` file.  This file is created using the `ssh-keygen` command (see Step 1 above).

```
ssh-keygen -t rsa -f "startup" -N ""
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

[userinput]: ../startup/userinput.json
[service-json]: ../startup/service.json
[build-json]: ../startup/build.json
[dockerfile]: ../startup/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
