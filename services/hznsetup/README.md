# &#127973;  `hznsetup` - new node configurator

Configure new devices into Open Horizon nodes in the specified _organization_ and _exchange_, with the specified _pattern_.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_hznsetup.svg)](https://microbadger.com/images/dcmartin/amd64_hznsetup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_hznsetup.svg)](https://microbadger.com/images/dcmartin/amd64_hznsetup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_hznsetup
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_hznsetup.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_hznsetup.svg)](https://microbadger.com/images/dcmartin/arm_hznsetup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_hznsetup.svg)](https://microbadger.com/images/dcmartin/arm_hznsetup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_hznsetup
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_hznsetup.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_hznsetup.svg)](https://microbadger.com/images/dcmartin/arm64_hznsetup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_hznsetup.svg)](https://microbadger.com/images/dcmartin/arm64_hznsetup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_hznsetup
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_hznsetup.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `hznsetup`
+ `version` - `0.0.1`

## Service variables

+ `HZNSETUP_EXCHANGE_URL` - URL of exchange in which to setup device; default: `${HZN_EXCHANGE_URL}`
+ `HZNSETUP_EXCHANGE_ORG` - organization in which to setup device; default `${HZN_ORG_ID}`
+ `HZNSETUP_EXCHANGE_APIKEY` - IBM Cloud platform API key; default `${HZN_EXCHANGE_APIKEY}`
+ `HZNSETUP_APPROVE` - default `"auto"`; options: { `auto`, `serial`, `mac`, `both` }
+ `HZNSETUP_VENDOR` - default `"any"` or value matching database `vendor` string
+ `HZNSETUP_BASENAME` - string prepended when approve is `"auto"`; default: `""`
+ `HZNSETUP_PATTERN` - default pattern when non-specified; default: `""`
+ `HZNSETUP_PORT` - port on which to listen for new devices; default: `3093` (aka **&#398;Dg&#398;**)
+ `HZNSETUP_PERIOD` - seconds between watchdog checks; default: `30`
+ `LOGTO` - specify place to log; default: `"/dev/stderr"`; use `""` for `"${TMPDIR}/${0##*/}.log"`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`; currently ignored)
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

## Pattern Services

### [`hznmonitor`](../hznmonitor/README.md)
+ `HZNMONITOR_EXCHANGE_URL` - URL of exchange in which to setup device; default: `${HZN_EXCHANGE_URL}`
+ `HZNMONITOR_EXCHANGE_ORG` - organization in which to setup device; default `${HZN_ORG_ID}`
+ `HZNMONITOR_EXCHANGE_APIKEY` - IBM Cloud platform API key; default `${HZN_EXCHANGE_APIKEY}`

## Description
This service listens for new node requests from devices over the network.  Devices requesting node identification and tokens are booted from identitical media that has been creating using the standard IBM edge fabric installation instructions.

In addition, a short initialization script is added to enable the device to identify its hardware serial number, product identifier, and network connections, provide that information to this service, and -- **if approved** -- receive identification, authorization token, and any initial pattern; for example a client request:

```
{
    "product": "jetson-nano",
    "serial": "042111900396808083fb",
    "mac": "00:04:4b:cc:4a:a6",
    "inet": "192.168.1.87/24"
}
```

### Device approval
Devices are only candidates for approval as a new node based on the `HZNSETUP_VENDOR` variable:

+ `"any"` - approve new devices from any vendor product string
+ `"<string>"` - approve new devices matching database vendor product string

Candidate devices are approved based on the following settings for `HZNSETUP_APPROVE`:

+ `auto` - automatically approve any new device which provides a conforming serial # and MAC address
+ `serial` - approve only devices which provide serial numbers found in the database
+ `mac` - approve only devices which provide MAC address found in the database
+ `both` - approve only devices which provide matching serial number and MAC address

Approved devices will receive a JSON payload with identifier and token; if approved, and and a pattern is specified, the device register for that pattern.  Non-approved devices will receive JSON error payload. 

## How To Use

### Create master media

1. Start with **supported** vendor operating system distribution
 + LINUX (Debian) on AMD64, ARM64, ARM(v6+), and PPC64 (little-endian)
 + Suport for Docker community edition, version 18+
2. Install pre-requisite & edge software
 + LINUX utility: `lshw`
 + Docker installation documentation & script (get.docker.com)
 + IBM Edge Fabric [documentation](https://github.ibm.com/Edge-Fabric/staging-docs)
 + *Examples*: Raspbian for [RaspberryPi](../setup/RPI.md), JetPack™for nVidia Jetson [Nano](../setup/NANO.md) and [TX2](../setup/TX2.md)
3. Add start-up script
 + Copy script `/mkrequest.sh` to master device
 + Modify `/etc/rc.local` to invoke `/mkrequest.sh` with specified `hznsetup` server

### Duplicate master media
 
1. Remove media from master device
 + Perform shutdown
 + Power-off device
 + Remove uSD card
2. Duplicate uSD card
 + Insert uSD into USB or SD card adapter
 + Insert adapter into LINUX or macOS computer
 + Copy from media to local file using `dd`
 + Safely eject adapter
3. Create new media
 + Insert new uSD card into adapter
 + Copy file to device using `dd`

**Commercial duplication services** will copy the master media to new media in lots of 100+ units; costs range from US$5 and up for a 16 Gbyte uSD card, depending on quantity and delivery.

## Device database (unimplemented)
The default approval method `auto` provides a new identifier and token for any valid request; other approval methods depend on the contents of a valid request, notably the approval method `serial` requires that the client request serial number be found in the device database.

The device database may be any [CouchDB](http://couchdb.org) compliant database, e.g. IBM [Cloudant](http://cloud.ibm.com/cloudant).  The database is specified with three `userInput` variables:

+ `HZNSETUP_DB` - the URL of the database server; default: `""` (example: `"https://<db>.cloudant.com"`)
+ `HZNSETUP_DB_USERNAME` - the username for access; default: `""`
+ `HZNSETUP_DB_PASSWORD` - the password for access; default: `""`

These values should be specified in the [`userinput.json`](userinput.json) file used to invoke this service as a pattern.

### Database structure
The database stores information about each device; a device record is defined by the following JSON structure:

```
{
  "exchange": "http://exchange:3090/v1",
  "org": "github@dcmartin.com",
  "pattern": "none",
  "device":  {
    "product": "jetson-nano",
    "serial": "042111900396808083fb",
    "mac": "00:04:4b:cc:4a:a6",
    "inet": "192.168.1.87/24"
  },
  "node": {
    "serial": "042111900396808083fb",
    "device": "test-00044bcc4aa6",
    "exchange": {
      "token": "********",
      "name": "test-00044bcc4aa6",
      "owner": "github@dcmartin.com/github@dcmartin.com",
      "pattern": "",
      "registeredServices": [],
      "msgEndPoint": "",
      "softwareVersions": {},
      "lastHeartbeat": "2019-04-27T00:40:58.904Z[UTC]",
      "publicKey": "",
      "id": "github@dcmartin.com/test-00044bcc4aa6"
    },
    "token": "e16b73d92d490df288fdfea68406d74935b90124"
  },
  "date": 1556325659
}
```

## EXAMPLE

### Client request
Clients request node status by submitting a JSON payload containing device details, for example:

```
curl 'localhost:3093' -X POST -H "Content-Type: application/json" --data-binary @client-request.json 
```

The `client-request.json` file contains the device specific details:

```
{
    "product": "jetson-nano",
    "serial": "042111900396808083fb",
    "mac": "00:04:4b:cc:4a:a6",
    "inet": "192.168.1.87/24"
}
```

There are multiple samples provides in the `samples/` directory.


### Service reponse
When the service registers the device, the service response (JSON) provides node information to the device:

```
{
  "exchange": "http://exchange:3090/v1",
  "org": "github@dcmartin.com",
  "pattern": "",
  "node": {
    "serial": "042111900396808083fb",
    "device": "test-00044bcc4aa6",
    "exchange": {
      "token": "********",
      "name": "test-00044bcc4aa6",
      "owner": "github@dcmartin.com/github@dcmartin.com",
      "pattern": "",
      "registeredServices": [],
      "msgEndPoint": "",
      "softwareVersions": {},
      "lastHeartbeat": "2019-04-27T00:40:58.904Z[UTC]",
      "publicKey": "",
      "id": "github@dcmartin.com/test-00044bcc4aa6"
    },
    "token": "e16b73d92d490df288fdfea68406d74935b90124"
  },
  "date": 1556325659
}

```
If the `pattern` is defined an additional attribute, `input`, is defined with the requisite JSON.

## How to Build

Copy this [repository][repository], change to the repository directory (e.g. `~/gitdir`), and then the `hznsetup` directory; then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon
% make build
% cd hznsetup
% make start
```

Once the service is started, it's status can be checked by running the following commnd:

```
% make check
```
Which will produce a status result:

```
{
  "hznsetup": {
    "nodes": 56,
    "date": 1556325635,
    "pid": 52
  },
  "date": 1556325635,
  "hzn": {
    "agreementid": "175ac3b3a3bb6485f22486fda800ff772b5ac7cfdfb8d698f005d3185e6bcb5a",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "http://exchange:3090/v1",
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
    "tmpdir": "/tmp",
    "logto": "/dev/stderr",
    "log_level": "info",
    "debug": true,
    "org": "github@dcmartin.com",
    "exchange": "http://exchange:3090/v1",
    "pattern": "",
    "port": 3093,
    "db": "https://515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix.cloudant.com",
    "username": "515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix",
    "pkg": {
      "url": "http://pkg.bluehorizon.network/",
      "key": "http://pkg.bluehorizon.network/bluehorizon.network-public.key"
    },
    "basename": "test-",
    "approve": "auto",
    "vendor": "any",
    "services": null
  },
  "service": {
    "label": "hznsetup",
    "version": "0.0.1"
  }
}
```

## Running pattern
The `hznsetup` service is also configured to be run as a pattern in conjunction with the [`hznmonitor`](../hznmonitor/README.md) service, which provides both HTML and CGI interfaces to the _exchange_ and the NoSQL database.

The pattern can only be published once both services have been built for all the supported architectures, pushed to Docker hub (or chosen registry) published to *exchange*.  As these services are dependent on other service containers, notably `base-alpine` and `apache`, those containers must also be built.

To build and push all service containers for all supported architectures, run the following command (n.b. **works on &#63743; macOS computers that inherently support AMD, ARM, and ARM64 architectures**):

```
% cd ~/gitdir/open-horizon
% make service-build
```

To publish the `hznmonitor` service to the exchange -- and push to the container registry -- run the following commands:

```
% cd ~/gitdir/open-horizon/hznmonitor
% make service-publish
```

To publish the `hznsetup` service, and push its container, as well as publish the pattern, run the following commands:

```
% cd ~/gitdir/open-horizon/hznsetup
% make service-publish
% make pattern-publish
```

With the services and pattern published, the pattern may be deployed to test nodes; note the default test node is the `localhost` which requires the Horizon `anax` agent to be running; **on &#63743; macOS run the `horizon-container start` command**); run the following command to create test node(s):

```
% make nodes
```

The Web service can be contacted at exposed port on the localhost, for example:

```
% open http://localhost:3094/
```

See the [`hzmonitor`](../hznmonitor/README.md) service for more information.


## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../hznsetup/userinput.json
[service-json]: ../hznsetup/service.json
[build-json]: ../hznsetup/build.json
[dockerfile]: ../hznsetup/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
