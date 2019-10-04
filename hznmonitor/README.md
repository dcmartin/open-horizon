# &#127981; `hznmonitor` - Open Horizon monitor

Monitor the OH exchange and organization patterns, services, and nodes.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.hznmonitor.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hznmonitor "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.hznmonitor.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hznmonitor "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.hznmonitor
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.hznmonitor.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.hznmonitor.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hznmonitor "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.hznmonitor.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hznmonitor "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.hznmonitor
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.hznmonitor.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.hznmonitor.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hznmonitor "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.hznmonitor.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hznmonitor "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.hznmonitor
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.hznmonitor.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.hznmonitor`
+ `version` - `0.0.1`

## Service ports
+ `3094` - Web service for HTML at `/` and CGI scripts at `/cgi-bin`
+ `3095` - `hznmonitor` service status; returns `application/json`

## Required Services
+ **NONE**

## Service variables

+ `HZNMONITOR_EXCHANGE_APIKEY` - API key for _exchange_
+ `HZNMONITOR_EXCHANGE_ORG` - Horizon _organization_ identifier
+ `HZNMONITOR_EXCHANGE_URL` - URL for _exchange_
+ `HZNMONITOR_KAFKA_APIKEY` - API key for **Kafka** message broker(s)
+ `HZNMONITOR_KAFKA_BROKER` - Kafka broker list; default provided
+ `HZNMONITOR_KAFKA_ADMIN_URL` - Kafka admin URL; default provided
+ `HZNMONITOR_KAFKA_TOPIC` - Topic to listen; default `"startup"`
+ `HZNMONITOR_MQTT_HOST` - Hostname (IP address, FQDN) for **MQTT** broker
+ `HZNMONITOR_MQTT_PASSWORD` - Password for MQTT broker
+ `HZNMONITOR_MQTT_USERNAME` - Username for MQTT broker
+ `APACHE_HOST` - default: `"localhost"`
+ `APACHE_PORT` - default: `3094`
+ `APACHE_ADMIN` - default: `"root@localhost.local"`
+ `LOG_LEVEL` - specify level of logging; default: `"info"`; options below
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

## Description
This service provides both HTML and JSON output for status of a Open Horizon organization; the default `index.html` page displays information on the exchange configured and the patterns, services, and nodes listed in the exchange.  There are six (6) sections in the Web user-interface:

+ **Matrix** - A `N`x`N` matrix with each cell representing a node in the exchange.
+ **Catalog** - Listing of all _services_ organized by their  _label_ (e.g. `apache`)
+ **Nodes** - Listing of all _nodes_ in _exchange_ for _organization_
+ **Services** - Listing of all _services_ in _exchange_ for _organization_
+ **Patterns** - Listing of all _patterns_ in _exchange_ or _organization_
+ **Exchange** - Details of _exchange_ 

### Matrix
The nodes in the exchange are displayed in a matrix, sorted from most recent to oldest entries based on `lastHeartbeat`, colored from dark **green** to dark **red**, with the interior cell indicating the node's status.  Nodes which have been registered on a device have the number of _agreements_ and the running and total _services_ and are colored from **green** through **yellow** to **red**.  Nodes which have **never** been registered are colored **white** and include the age of the node.  For example:

<img width="70%" src="samples/dashboard.png">

And for visualizing many node (e.g. 5000+):

<img width="70%" src="samples/dashboard-5k.png">

### Catalog
A listing of services in the exchange organized by the `label` attribute; service URL, version, and architecture(s) are listed, including container size, number of layers, age, and container pulls, for example for all services with the `label` value `apache`:

<img width="100%" src="samples/catalog.png">

### Nodes
Nodes are listed from most recent updatate to oldest; each node is described, for example:
<img  width="100%"  src="samples/node.png">

### Services
Services are listed from most recent updatate to oldest; each service is described, for example:
<img  width="100%" src="samples/service.png">

### Patterns
<img  width="100%" src="samples/pattern.png">

### Exchange
The status of the designated exchange is displayed, including global statistics (e.g. number of nodes), for example:
<img width="50%" src="samples/exchange.png">

## CGI scripts
This service provides common-gateway-interface (CGI) scripts to provide information about the exchange, organization, patterns, services, and nodes.  Each script is accessible through the path `/cgi-bin/<script>`; the following is the list of available scripts:

+ `exchange` - the exchange configured; [sample](samples/exchange.json)
+ `services` - the organization's services; [sample](samples/services.json)
+ `patterns` - the organization's patterns; [sample](samples/patterns.json)
+ `status` - a node status; [sample](samples/status.json)
+ `labels` - return services grouped by label; [sample](samples/labels.json)
+ `nodes` - the organization's nodes; [sample](samples/nodes.json)
+ `users` - the organization's users; [sample](samples/users.json)
+ `summary` - summary statistics from Kafka messages on  topic `startup`; [sample](samples/summary.json); see [`startup`](../startup/README.md)

**EXAMPLE**

```
% curl -sSL localhost:3094/cgi-bin/exchange
```

Produces the following JSON output:

```
{
  "msg": "Exchange server operating normally",
  "numberOfUsers": 84,
  "numberOfNodes": 175,
  "numberOfNodeAgreements": 74,
  "numberOfNodeMsgs": 3,
  "numberOfAgbots": 3,
  "numberOfAgbotAgreements": 100,
  "numberOfAgbotMsgs": 0,
  "dbSchemaVersion": 17,
  "org": "github@dcmartin.com",
  "url": "https://alpha.edge-fabric.com/v1/"
}
```

## How To Use
On a supported device, e.g. RaspberryPi Model 3B+ with Sony Playstation3 Eye camera:

### Step 0
Configure and install the device appropriately:

+ RaspberryPi - [`RPI.md`](../doc/RPI.md)
+ nVidia Jetson Nano - [`NANO.md`](../doc/NANO.md)
+ nVidia Jetson TX2 - [`TX2.md`](../doc/TX2.md)

### Step 1
Collect required exchange information and encode as environment variables; get the `apiKey.json` file by downloading from the IBM Cloud [IAM](http://cloud.ibm.com/iam/apikeys) service. Change the `HZN_ORG_ID` to an appropriate organization value.

```
HZN_ORG_ID="<YOUR_ORGANIZATION_ID>"
HZN_EXCHANGE_APIKEY=$(jq -r '.apiKey' ~/apiKey.json)
```

### Step 2
Create a `pattern.json` file containing the services array for the pattern; for example:

```
{
  "label": "hznmonitor",
  "description": "monitor horizon organization",
  "services": [
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.hznmonitor",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "amd64",
      "serviceVersions": [
        {
          "version": "0.0.1"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.hznmonitor",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "0.0.1"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.hznmonitor",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm64",
      "serviceVersions": [
        {
          "version": "0.0.1"
        }
      ]
    }
  ]
}
```

### Step 3
Generate a public/private key-pair for signing:

```
hzn key create ${HZN_ORG_ID} $(whoami)@$(hostname)
PRIVATE_KEY_FILE=*-private.key
PUBLIC_KEY_FILE=*-public.pem
```

### Step 4
Publish the pattern in the exchange for the organization; for example:

```
hzn exchange pattern publish -o "${HZN_ORG_ID}" -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY} -f pattern.json -p ${PATTERN} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}
```

### Step 5
Confirm pattern publishing; there may be more than one pattern in the organization; look for `hznmonitor`:

```
% hzn exchange pattern list -o ${HZN_ORG_ID} -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}
[
  "<YOUR_ORGANIZATION_ID>/hznmonitor"
]
```

### Step 6
Create a `userinput.json` file containing the environment variables for each service; for example:

```
{
 "global": [],
 "services": [
   {
     "org": "${HZN_ORG_ID}",
     "url": "com.github.dcmartin.open-horizon.hznmonitor",
     "versionRange": "[0.0.0,INFINITY)",
     "variables": { 
       "HZNMONITOR_EXCHANGE_URL": "https://alpha.edge-fabric.com/v1/",
       "HZNMONITOR_EXCHANGE_ORG": "<YOUR_ORGANIZATION_ID>",
       "HZNMONITOR_EXCHANGE_APIKEY": "<YOUR_EXCHANGE_APIKEY>",
       "HZNMONITOR_KAFKA_APIKEY":"<YOUR_KAFKA_APIKEY>",
       "HZNMONITOR_MQTT_HOST":"<YOUR MQTT BROKER IP>",
       "HZNMONITOR_MQTT_USERNAME":"<username>",
       "HZNMONITOR_MQTT_PASSWROD":"<password>",
       "HZNMONITOR_PERIOD": "30",
       "LOG_LEVEL": "info",
       "LOGTO": "",
       "DEBUG": "false"
   }
 ]
}
```

### Step 7
Specify pattern (`PATTERN`), device identifier (`ID`) and device password (`PW`):

```
PATTERN=${HZN_ORG_ID}/hznmonitor
ID=$(hostname)
PW=$(read -p "Enter password: " -s)
```

### Step 8
Use the `hzn` command-line-interface (CLI) application to register the device for the pattern, for example:

```
PATTERN="hznmonitor"
hzn register ${HZN_ORG_ID} -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY} ${PATTERN} -f userinput.json -n "${ID}:${PW}"
```

### Step 9
Inspect the device to determine proper node configuration, for example:

```
% hzn node list
{
  "id": "test-amd64-1",
  "organization": "<YOUR_ORGANIZATION_ID>",
  "pattern": "<YOUR_ORGANIZATION_ID>/hznmonitor",
  "name": "<YOUR_NODE_ID>",
  "token_last_valid_time": "2019-05-15 06:56:53 -0700 PDT",
  "token_valid": true,
  "ha": false,
  "configstate": {
    "state": "configured",
    "last_update_time": "2019-05-15 06:57:09 -0700 PDT"
  },
  "configuration": {
    "exchange_api": "https://alpha.edge-fabric.com/v1/",
    "exchange_version": "1.80.0",
    "required_minimum_exchange_version": "1.73.0",
    "preferred_exchange_version": "1.75.0",
    "architecture": "amd64",
    "horizon_version": "2.23.1"
  },
  "connectivity": {
    "firmware.bluehorizon.network": true,
    "images.bluehorizon.network": true
  }
}
```

### Step 10
Verify operation of device as node running pattern of services, for example:

```
% hzn service list
[
  {
    "url": "com.github.dcmartin.open-horizon.hznmonitor",
    "org": "${HZN_ORG_ID}",
    "version": "0.0.1",
    "arch": "amd64",
    "variables": {
    }
  }
]
```

## How To Build
Copy this [repository][repository], change to the repository directory (e.g. `~/gitdir`), and then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hznmonitor
% make build
% make start
```

After the service has started the status can be inspected; run the following command to check status (and yield `check.json` residual):

```
% make check
```

Produces a JSON status payload; the `status` attribute is a BASE64 encoded HTML web service status [page](../apache/samples/index.png):

```
{
  "hznmonitor": {
    "pid": 44,
    "status": "PCFET0NUWVBFIEhUTUwgUFVCTElDICItLy9XM0MvL0RURCBIVE1MIDMuMiBGaW5hbC8vRU4iPgo8aHRtbD48aGVhZD4KPHRpdGxlPkFwYWNoZSBTdGF0dXM8L3RpdGxlPgo8L2hlYWQ+PGJvZHk+CjxoMT5BcGFjaGUgU2VydmVyIFN0YXR1cyBmb3IgbG9jYWxob3N0ICh2aWEgMTI3LjAuMC4xKTwvaDE+Cgo8ZGw+PGR0PlNlcnZlciBWZXJzaW9uOiBBcGFjaGUvMi40LjM5IChVbml4KTwvZHQ+CjxkdD5TZXJ2ZXIgTVBNOiBwcmVmb3JrPC9kdD4KPGR0PlNlcnZlciBCdWlsdDogQXByICAzIDIwMTkgMTU6NTI6NTcKPC9kdD48L2RsPjxociAvPjxkbD4KPGR0PkN1cnJlbnQgVGltZTogTW9uZGF5LCAyOS1BcHItMjAxOSAxNDo1NTowMiA8L2R0Pgo8ZHQ+UmVzdGFydCBUaW1lOiBNb25kYXksIDI5LUFwci0yMDE5IDE0OjU1OjAyIDwvZHQ+CjxkdD5QYXJlbnQgU2VydmVyIENvbmZpZy4gR2VuZXJhdGlvbjogMTwvZHQ+CjxkdD5QYXJlbnQgU2VydmVyIE1QTSBHZW5lcmF0aW9uOiAwPC9kdD4KPGR0PlNlcnZlciB1cHRpbWU6IDwvZHQ+CjxkdD5TZXJ2ZXIgbG9hZDogMC41OSAwLjE5IDAuMTA8L2R0Pgo8ZHQ+VG90YWwgYWNjZXNzZXM6IDAgLSBUb3RhbCBUcmFmZmljOiAwIGtCIC0gVG90YWwgRHVyYXRpb246IDA8L2R0Pgo8ZHQ+Q1BVIFVzYWdlOiB1MCBzMCBjdTAgY3MwPC9kdD4KPGR0PjwvZHQ+CjxkdD4xIHJlcXVlc3RzIGN1cnJlbnRseSBiZWluZyBwcm9jZXNzZWQsIDQgaWRsZSB3b3JrZXJzPC9kdD4KPC9kbD48cHJlPldfX19fLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4KLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLgouLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uCi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi48L3ByZT4KPHA+U2NvcmVib2FyZCBLZXk6PGJyIC8+CiI8Yj48Y29kZT5fPC9jb2RlPjwvYj4iIFdhaXRpbmcgZm9yIENvbm5lY3Rpb24sIAoiPGI+PGNvZGU+UzwvY29kZT48L2I+IiBTdGFydGluZyB1cCwgCiI8Yj48Y29kZT5SPC9jb2RlPjwvYj4iIFJlYWRpbmcgUmVxdWVzdCw8YnIgLz4KIjxiPjxjb2RlPlc8L2NvZGU+PC9iPiIgU2VuZGluZyBSZXBseSwgCiI8Yj48Y29kZT5LPC9jb2RlPjwvYj4iIEtlZXBhbGl2ZSAocmVhZCksIAoiPGI+PGNvZGU+RDwvY29kZT48L2I+IiBETlMgTG9va3VwLDxiciAvPgoiPGI+PGNvZGU+QzwvY29kZT48L2I+IiBDbG9zaW5nIGNvbm5lY3Rpb24sIAoiPGI+PGNvZGU+TDwvY29kZT48L2I+IiBMb2dnaW5nLCAKIjxiPjxjb2RlPkc8L2NvZGU+PC9iPiIgR3JhY2VmdWxseSBmaW5pc2hpbmcsPGJyIC8+IAoiPGI+PGNvZGU+STwvY29kZT48L2I+IiBJZGxlIGNsZWFudXAgb2Ygd29ya2VyLCAKIjxiPjxjb2RlPi48L2NvZGU+PC9iPiIgT3BlbiBzbG90IHdpdGggbm8gY3VycmVudCBwcm9jZXNzPGJyIC8+CjwvcD4KCgo8dGFibGUgYm9yZGVyPSIwIj48dHI+PHRoPlNydjwvdGg+PHRoPlBJRDwvdGg+PHRoPkFjYzwvdGg+PHRoPk08L3RoPjx0aD5DUFUKPC90aD48dGg+U1M8L3RoPjx0aD5SZXE8L3RoPjx0aD5EdXI8L3RoPjx0aD5Db25uPC90aD48dGg+Q2hpbGQ8L3RoPjx0aD5TbG90PC90aD48dGg+Q2xpZW50PC90aD48dGg+UHJvdG9jb2w8L3RoPjx0aD5WSG9zdDwvdGg+PHRoPlJlcXVlc3Q8L3RoPjwvdHI+Cgo8dHI+PHRkPjxiPjAtMDwvYj48L3RkPjx0ZD40NzwvdGQ+PHRkPjAvMC8wPC90ZD48dGQ+PGI+VzwvYj4KPC90ZD48dGQ+MC4wMDwvdGQ+PHRkPjA8L3RkPjx0ZD4wPC90ZD48dGQ+MDwvdGQ+PHRkPjAuMDwvdGQ+PHRkPjAuMDA8L3RkPjx0ZD4wLjAwCjwvdGQ+PHRkPjEyNy4wLjAuMTwvdGQ+PHRkPmh0dHAvMS4xPC90ZD48dGQgbm93cmFwPjE5Mi4xNjguMzIuMjozMDk0PC90ZD48dGQgbm93cmFwPkdFVCAvc2VydmVyLXN0YXR1cyBIVFRQLzEuMTwvdGQ+PC90cj4KCjwvdGFibGU+CiA8aHIgLz4gPHRhYmxlPgogPHRyPjx0aD5TcnY8L3RoPjx0ZD5DaGlsZCBTZXJ2ZXIgbnVtYmVyIC0gZ2VuZXJhdGlvbjwvdGQ+PC90cj4KIDx0cj48dGg+UElEPC90aD48dGQ+T1MgcHJvY2VzcyBJRDwvdGQ+PC90cj4KIDx0cj48dGg+QWNjPC90aD48dGQ+TnVtYmVyIG9mIGFjY2Vzc2VzIHRoaXMgY29ubmVjdGlvbiAvIHRoaXMgY2hpbGQgLyB0aGlzIHNsb3Q8L3RkPjwvdHI+CiA8dHI+PHRoPk08L3RoPjx0ZD5Nb2RlIG9mIG9wZXJhdGlvbjwvdGQ+PC90cj4KPHRyPjx0aD5DUFU8L3RoPjx0ZD5DUFUgdXNhZ2UsIG51bWJlciBvZiBzZWNvbmRzPC90ZD48L3RyPgo8dHI+PHRoPlNTPC90aD48dGQ+U2Vjb25kcyBzaW5jZSBiZWdpbm5pbmcgb2YgbW9zdCByZWNlbnQgcmVxdWVzdDwvdGQ+PC90cj4KIDx0cj48dGg+UmVxPC90aD48dGQ+TWlsbGlzZWNvbmRzIHJlcXVpcmVkIHRvIHByb2Nlc3MgbW9zdCByZWNlbnQgcmVxdWVzdDwvdGQ+PC90cj4KIDx0cj48dGg+RHVyPC90aD48dGQ+U3VtIG9mIG1pbGxpc2Vjb25kcyByZXF1aXJlZCB0byBwcm9jZXNzIGFsbCByZXF1ZXN0czwvdGQ+PC90cj4KIDx0cj48dGg+Q29ubjwvdGg+PHRkPktpbG9ieXRlcyB0cmFuc2ZlcnJlZCB0aGlzIGNvbm5lY3Rpb248L3RkPjwvdHI+CiA8dHI+PHRoPkNoaWxkPC90aD48dGQ+TWVnYWJ5dGVzIHRyYW5zZmVycmVkIHRoaXMgY2hpbGQ8L3RkPjwvdHI+CiA8dHI+PHRoPlNsb3Q8L3RoPjx0ZD5Ub3RhbCBtZWdhYnl0ZXMgdHJhbnNmZXJyZWQgdGhpcyBzbG90PC90ZD48L3RyPgogPC90YWJsZT4KPGhyIC8+CjxhZGRyZXNzPkFwYWNoZS8yLjQuMzkgKFVuaXgpIFNlcnZlciBhdCBsb2NhbGhvc3QgUG9ydCAzMDk0PC9hZGRyZXNzPgo8L2JvZHk+PC9odG1sPgo="
  },
  "date": 1556549701,
  "hzn": {
    "agreementid": "906360d575ee15646ef9752dbc2514047efbc8c55cec3a0a0e91574fe544fbb3",
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
    "tmpdir": "/tmp",
    "logto": "/dev/stderr",
    "log_level": "info",
    "debug": false,
    "org": "github@dcmartin.com",
    "exchange": "https://alpha.edge-fabric.com/v1/",
    "db": "https://515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix.cloudant.com",
    "username": "515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix",
    "conf": "/etc/apache2/httpd.conf",
    "htdocs": "/var/www/localhost/htdocs",
    "cgibin": "/var/www/localhost/cgi-bin",
    "host": "localhost",
    "port": "3094",
    "admin": "root@localhost.local",
    "pidfile": "/var/run/apache2.pid",
    "rundir": "/var/run/apache2",
    "services": null
  },
  "service": {
    "label": "hznmonitor",
    "version": "0.0.1",
    "port": 3095
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

[userinput]: ../hznmonitor/userinput.json
[service-json]: ../hznmonitor/service.json
[build-json]: ../hznmonitor/build.json
[dockerfile]: ../hznmonitor/Dockerfile


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
