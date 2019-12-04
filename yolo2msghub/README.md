# &#128083; `yolo2msghub` - count an entity and send to Kafka

Send YOLO classified image entity counts to Kafka; updates as often as underlying services provide.
This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.yolo2msghub.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.yolo2msghub.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.yolo2msghub`
+ `version` - `0.0.11`

## Service variables 
+ `YOLO2MSGHUB_APIKEY` - **REQUIRED** message hub API key
+ `YOLO2MSGHUB_PERIOD` - seconds between updates; defaults to `30`
+ `YOLO2MSGHUB_ADMIN_URL` - administrative URL for REStful API
+ `YOLO2MSGHUB_BROKER` - message hub brokers
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`). 
+ `DEBUG` - including debugging output; `true` or `false`; default: `false`

## Required services

This _service_ includes the following services:

+ [`yolo`][yolo-service] - captures images from camera and counts specified entity
+ [`hal`][hal-service] - provides hardware inventory layer API for client
+ [`cpu`][cpu-service] - provides CPU percentage API for client
+ [`wan`][wan-service] - provides wide-area-network information API for client

[yolo-service]: ../yolo/README.md
[hal-service]: ../hal/README.md
[cpu-service]: ../cpu/README.md
[wan-service]: ../wan/README.md

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
  "label": "yolo2msghub",
  "description": "yolo and friends as a pattern",
  "services": [
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "amd64",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm64",
      "serviceVersions": [
        {
          "version": "0.0.11"
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
Publish the pattern in the exchange for the organization.  , for example:

```
hzn exchange pattern publish -o "${HZN_ORG_ID}" -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY} -f pattern.json -p ${PATTERN} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}
```

### Step 5
Confirm pattern publishing; there may be more than one pattern in the organization; look for `yolo2msghub`:

```
% hzn exchange pattern list -o ${HZN_ORG_ID} -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}
[
  "<YOUR_ORGANIZATION_ID>/yolo2msghub"
]
```

### Step 6
Create a `userinput.json` file containing the environment variables for each service; change the value for `YOLO2MSGHUB_APIKEY`:

```
{
 "global": [],
 "services": [
   {
     "org": "${HZN_ORG_ID}",
     "url": "com.github.dcmartin.open-horizon.yolo2msghub",
     "versionRange": "[0.0.0,INFINITY)",
     "variables": { 
       "YOLO2MSGHUB_APIKEY": "<YOUR_KAFKA_APIKEY>",
       "LOG_LEVEL": "info",
       "DEBUG": true }
   },
   {
     "org": "${HZN_ORG_ID}",
     "url": "com.github.dcmartin.open-horizon.yolo",
     "versionRange": "[0.0.0,INFINITY)",
     "variables": {
       "YOLO_ENTITY": "person",
       "YOLO_PERIOD": 60,
       "YOLO_CONFIG": "tiny" }
   },
   {
     "org": "${HZN_ORG_ID}",
     "url": "com.github.dcmartin.open-horizon.cpu",
     "versionRange": "[0.0.0,INFINITY)",
     "variables": { "CPU_PERIOD": 60 }
   },
   {
     "org": "${HZN_ORG_ID}",
     "url": "com.github.dcmartin.open-horizon.wan",
     "versionRange": "[0.0.0,INFINITY)",
     "variables": { "WAN_PERIOD": 900 }
   },
   {
     "org": "${HZN_ORG_ID}",
     "url": "com.github.dcmartin.open-horizon.hal",
     "versionRange": "[0.0.0,INFINITY)",
     "variables": { "HAL_PERIOD": 1800 }
   }
 ]
}
```

### Step 7
Specify pattern (`PATTERN`), device identifier (`ID`) and device password (`PW`):

```
PATTERN=${HZN_ORG_ID}/yolo2msghub
ID=$(hostname)
PW=$(read -p "Enter password: " -s)
```

### Step 8
Use the `hzn` command-line-interface (CLI) application to register the device for the pattern, for example:

```
hzn register ${HZN_ORG_ID} -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY} ${PATTERN} -f userinput.json -n "${ID}:${PW}"
```

### Step 9
Inspect the device to determine proper node configuration, for example:

```
% hzn node list
{
  "id": "test-amd64-1",
  "organization": "<YOUR_ORGANIZATION_ID>",
  "pattern": "<YOUR_ORGANIZATION_ID>/yolo2msghub",
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
% hzn services list
[
  {
    "url": "com.github.dcmartin.open-horizon.wan",
    "org": "${HZN_ORG_ID}",
    "version": "0.0.3",
    "arch": "amd64",
    "variables": {
      "WAN_PERIOD": 900
    }
  },
  {
    "url": "com.github.dcmartin.open-horizon.yolo",
    "org": "${HZN_ORG_ID}",
    "version": "0.0.8",
    "arch": "amd64",
    "variables": {
      "YOLO_CONFIG": "tiny",
      "YOLO_ENTITY": "person",
      "YOLO_PERIOD": 60
    }
  },
  {
    "url": "com.github.dcmartin.open-horizon.yolo2msghub",
    "org": "${HZN_ORG_ID}",
    "version": "0.0.11",
    "arch": "amd64",
    "variables": {
      "DEBUG": true,
      "LOG_LEVEL": "info",
      "YOLO2MSGHUB_APIKEY": "<YOUR_APIKEY>"
    }
  },
  {
    "url": "com.github.dcmartin.open-horizon.cpu",
    "org": "${HZN_ORG_ID}",
    "version": "0.0.3",
    "arch": "amd64",
    "variables": {
      "CPU_PERIOD": 60
    }
  },
  {
    "url": "com.github.dcmartin.open-horizon.hal",
    "org": "${HZN_ORG_ID}",
    "version": "0.0.3",
    "arch": "amd64",
    "variables": {
      "HAL_PERIOD": 1800
    }
  }
]
```

### Step 11 
Confirm successful transmission of data to Kafka and process payload using the `kafkacat.sh` script.  This script will collect messages sent to the `yolo2msghub` topic using the `YOLO2MSGHUB_APIKEY` file contents, which should be a quoted JSON string; the script will output summary data for the most recently received payload as well as the historical payload data, organized by device and average number of entities -- default `person` -- seen per unit time.

```
% ./kafkacat.sh
--- INFO ./kafkacat.sh 6696 -- listening for topic yolo2msghub
### DATA ./kafkacat.sh 6696 -- received at: 11:55:26; bytes: 29359; total bytes: 29359; bytes/sec: 14679.50000000000000000000
>>> ./kafkacat.sh 6696 -- 11:55:26
{
  "id": "david-green-rpi",
  "entity": "person",
  "date": 1558367623,
  "started": 97301,
  "count": 1,
  "mock": 0,
  "seen": 0,
  "first": 0,
  "last": 0,
  "average": 0,
  "download": 17746843.871214524,
  "percent": 80.33,
  "product": "Raspberry Pi 3 Model B Plus Rev 1.3"
}
### DATA ./kafkacat.sh 6696 -- received at: 11:55:40; bytes: 35824; total bytes: 65183; bytes/sec: 3834.29411764705882352941
### DATA ./kafkacat.sh 6696 -- david-white-rpi; ago: 37; person seen: 2
>>> ./kafkacat.sh 6696 -- 11:55:40
{
  "id": "david-white-rpi",
  "entity": "person",
  "date": 1558464939,
  "started": 97380,
  "count": 1,
  "mock": 0,
  "seen": 2,
  "first": 1558464902,
  "last": 1558464902,
  "average": 1,
  "download": 11393308.400382336,
  "percent": 25.62,
  "product": "Raspberry Pi 3 Model B Plus Rev 1.3",
  "interval": 0,
  "ago": 37
}
{"id":"david-green-rpi","entity":"person","date":1558367623,"started":97301,"count":1,"mock":0,"seen":0,"first":0,"last":0,"average":0,"download":17746843.871214524,"percent":80.33,"product":"Raspberry Pi 3 Model B Plus Rev 1.3"}
{"id":"david-white-rpi","entity":"person","date":1558464939,"started":97380,"count":1,"mock":0,"seen":2,"first":1558464902,"last":1558464902,"average":1,"download":11393308.400382336,"percent":25.62,"product":"Raspberry Pi 3 Model B Plus Rev 1.3","interval":0,"ago":37}
```


## How To Build
Copy this [repository][repository], change to the `yolo4motion` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo4motion
% make
...
{
  "wan": null,
  "cpu": null,
  "hal": null,
  "yolo2msghub": {
    "date": 1554316356,
    "entity": null,
    "config": null,
    "detected": null,
    "mock": null,
    "cpu": false,
    "wan": false,
    "hal": false,
    "yolo": false
  },
  "date": 1554316356,
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
    "date": 1554316356,
    "log_level": "info",
    "debug": false,
    "services": [
      {
        "name": "hal",
        "url": "http://hal"
      },
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "wan",
        "url": "http://wan"
      }
    ],
    "period": 30
  },
  "service": {
    "label": "yolo2msghub",
    "version": "0.0.11"
  }
}
```

## &#9937; Service test
To test completely, the service requires instantiation on the development host; use the following commands to set the API key and organizational identifier, then start the service:

```
cd open-horizon/yolo2msghub/
make service-start
```

Then a test of the service is performed using:

```
make test
```

The output of the test:

```
>>> MAKE -- 11:51:40 -- testing container: yolo2msghub; tag: dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub:0.0.11
./test.sh "dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub:0.0.11"
--- INFO -- ./test.sh 65358 -- No host specified; assuming 127.0.0.1
+++ WARN ./test.sh 65358 -- No port specified; assuming port 8587
+++ WARN ./test.sh 65358 -- No protocol specified; assuming http
--- INFO -- ./test.sh 65358 -- Testing yolo2msghub in container tagged: dcmartin/amd64_com.github.dcmartin.open-horizon.yolo2msghub:0.0.11 at Wed Apr 3 11:51:40 PDT 2019
{"wan":{"date":"number","speedtest":{"client":{"rating":"string","loggedin":"string","isprating":"string","ispdlavg":"string","ip":"string","isp":"string","lon":"string","ispulavg":"string","country":"string","lat":"string"},"bytes_sent":"number","download":"number","timestamp":"string","share":"null","bytes_received":"number","ping":"number","upload":"number","server":{"latency":"number","name":"string","url":"string","country":"string","lon":"string","cc":"string","host":"string","sponsor":"string","lat":"string","id":"string","d":"number"}}},"cpu":{"date":"number","percent":"number"},"hal":{"date":"number","lshw":{"id":"string","class":"string","claimed":"boolean","handle":"string","description":"string","product":"string","version":"string","serial":"string","width":"number","configuration":{"boot":"string","sku":"string","uuid":"string"},"capabilities":{"0":"","vsyscall32":"string"},"children":["object","object"]},"lsusb":[],"lscpu":{"Architecture":"string","CPU_op_modes":"string","Byte_Order":"string","CPUs":"string","On_line_CPUs_list":"string","Threads_per_core":"string","Cores_per_socket":"string","Sockets":"string","Vendor_ID":"string","CPU_family":"string","Model":"string","Model_name":"string","Stepping":"string","CPU_MHz":"string","BogoMIPS":"string","L1d_cache":"string","L1i_cache":"string","L2_cache":"string","L3_cache":"string","Flags":"string"},"lspci":["object","object","object","object","object","object","object","object","object"],"lsblk":["object","object","object","object"],"lsdf":["object"]},"yolo2msghub":{"date":"number","yolo":{"mock":"string","info":{"type":"string","size":"string","bps":"string","color":"string"},"time":"number","count":"number","detected":["object"],"image":"string","date":"number"}},"date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"date":"number","log_level":"string","debug":"boolean","services":["object","object","object"],"period":"number"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./test.sh 65358 -- test /Volumes/dcmartin/GIT/master/open-horizon/yolo2msghub/test-yolo2msghub.sh returned true
true
```

The resulting status JSON file may also be inspected; it will be named (or something similar):

```
test.amd64_com.github.dcmartin.open-horizon.yolo2msghub:0.0.11.json
```

### `kafkacat.sh`
The shell script `kafkacat.sh` may be used to listen to the `yolo2msghub` topic; it is designed to work with the command-line program `kafkacat`; the most recent version is required and available for macOS using [HomeBrew](http://brew.sh) and Ubuntu LINUX using `apt install -y kafkacat`.  Versions available for Alpine and Raspbian LINUX are insufficient.

## Example `yolo2msghub` status

```
{
  "wan": {
    "date": 1554316851,
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
      "bytes_sent": 12484608,
      "download": 229380672.22410062,
      "timestamp": "2019-04-03T18:40:21.834764Z",
      "share": null,
      "bytes_received": 289524284,
      "ping": 12.907,
      "upload": 5530006.94234574,
      "server": {
        "latency": 12.907,
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
  "cpu": {
    "date": 1554317480,
    "percent": 25.8
  },
  "hal": {
    "date": 1554316821,
    "lshw": {
      "id": "94bcb425cd0e",
      "class": "system",
      "claimed": true,
      "handle": "DMI:0001",
      "description": "Computer",
      "product": "BHYVE (None)",
      "version": "1.0",
      "serial": "None",
      "width": 64,
      "configuration": {
        "boot": "normal",
        "sku": "None",
        "uuid": "1943F97B-0000-0000-984D-D2936121B805"
      },
      "capabilities": {
        "smbios-3.0": "SMBIOS version 3.0",
        "dmi-3.0": "DMI version 3.0",
        "vsyscall32": "32-bit processes"
      },
      "children": [
        {
          "id": "core",
          "class": "bus",
          "claimed": true,
          "description": "Motherboard",
          "physid": "0",
          "children": [
            {
              "id": "firmware",
              "class": "memory",
              "claimed": true,
              "description": "BIOS",
              "vendor": "BHYVE",
              "physid": "0",
              "version": "1.00",
              "date": "03/14/2014",
              "units": "bytes",
              "size": 65536,
              "capabilities": {
                "isa": "ISA bus",
                "pci": "PCI bus",
                "shadowing": "BIOS shadowing",
                "cdboot": "Booting from CD-ROM/DVD",
                "edd": "Enhanced Disk Drive extensions",
                "acpi": "ACPI",
                "biosbootspecification": "BIOS boot specification",
                "virtualmachine": "This machine is a virtual machine"
              }
            },
            {
              "id": "cpu:0",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0003",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "3",
              "businfo": "cpu@0",
              "serial": "None",
              "slot": "CPU #0",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "cpu:1",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0004",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "4",
              "businfo": "cpu@1",
              "serial": "None",
              "slot": "CPU #1",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "cpu:2",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0005",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "5",
              "businfo": "cpu@2",
              "serial": "None",
              "slot": "CPU #2",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "cpu:3",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0006",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "6",
              "businfo": "cpu@3",
              "serial": "None",
              "slot": "CPU #3",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "memory",
              "class": "memory",
              "claimed": true,
              "handle": "DMI:0007",
              "description": "System Memory",
              "physid": "7",
              "slot": "System board or motherboard",
              "units": "bytes",
              "size": 68717379584,
              "children": [
                {
                  "id": "bank:0",
                  "class": "memory",
                  "claimed": true,
                  "handle": "DMI:0008",
                  "product": "None",
                  "physid": "0",
                  "serial": "None",
                  "units": "bytes",
                  "size": 34358689792,
                  "width": 64
                },
                {
                  "id": "bank:1",
                  "class": "memory",
                  "claimed": true,
                  "handle": "DMI:0009",
                  "product": "None",
                  "physid": "1",
                  "serial": "None",
                  "units": "bytes",
                  "size": 34358689792,
                  "width": 64
                }
              ]
            },
            {
              "id": "pci",
              "class": "bridge",
              "claimed": true,
              "handle": "PCIBUS:0000:00",
              "description": "Host bridge",
              "product": "Network Appliance Corporation",
              "vendor": "Network Appliance Corporation",
              "physid": "100",
              "businfo": "pci@0000:00:00.0",
              "version": "00",
              "width": 32,
              "clock": 33000000,
              "children": [
                {
                  "id": "network:0",
                  "class": "network",
                  "claimed": true,
                  "handle": "PCI:0000:00:01.0",
                  "description": "Ethernet controller",
                  "product": "Virtio network device",
                  "vendor": "Red Hat, Inc",
                  "physid": "1",
                  "businfo": "pci@0000:00:01.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "virtio-pci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "msix": "MSI-X",
                    "msi": "Message Signalled Interrupts",
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:0",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:02.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "2",
                  "businfo": "pci@0000:00:02.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "network:1",
                  "class": "network",
                  "claimed": true,
                  "handle": "PCI:0000:00:03.0",
                  "description": "Ethernet controller",
                  "product": "Red Hat, Inc",
                  "vendor": "Red Hat, Inc",
                  "physid": "3",
                  "businfo": "pci@0000:00:03.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "virtio-pci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "msix": "MSI-X",
                    "msi": "Message Signalled Interrupts",
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:1",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:04.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "4",
                  "businfo": "pci@0000:00:04.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:2",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:05.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "5",
                  "businfo": "pci@0000:00:05.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:3",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:06.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "6",
                  "businfo": "pci@0000:00:06.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "generic",
                  "class": "generic",
                  "claimed": true,
                  "handle": "PCI:0000:00:07.0",
                  "description": "Network and computing encryption device",
                  "product": "Virtio RNG",
                  "vendor": "Red Hat, Inc",
                  "physid": "7",
                  "businfo": "pci@0000:00:07.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "virtio-pci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "msix": "MSI-X",
                    "msi": "Message Signalled Interrupts",
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "isa",
                  "class": "bridge",
                  "claimed": true,
                  "handle": "PCI:0000:00:1f.0",
                  "description": "ISA bridge",
                  "product": "82371SB PIIX3 ISA [Natoma/Triton II]",
                  "vendor": "Intel Corporation",
                  "physid": "1f",
                  "businfo": "pci@0000:00:1f.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "latency": "0"
                  },
                  "capabilities": {
                    "isa": true,
                    "bus_master": "bus mastering"
                  }
                }
              ]
            },
            {
              "id": "scsi:0",
              "class": "storage",
              "claimed": true,
              "physid": "1",
              "logicalname": "scsi0",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "disk",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:00:00:00:00",
                  "description": "ATA Disk",
                  "product": "BHYVE SATA DISK",
                  "physid": "0.0.0",
                  "businfo": "scsi@0:0.0.0",
                  "logicalname": "/dev/sda",
                  "dev": "8:0",
                  "version": "001",
                  "serial": "BHYVE-CE00-045F-3FC6",
                  "units": "bytes",
                  "size": 255999344640,
                  "configuration": {
                    "ansiversion": "5",
                    "logicalsectorsize": "512",
                    "sectorsize": "4096",
                    "signature": "9fd2782c"
                  },
                  "capabilities": {
                    "partitioned": "Partitioned disk",
                    "partitioned:dos": "MS-DOS partition table"
                  },
                  "children": [
                    {
                      "id": "volume",
                      "class": "volume",
                      "claimed": true,
                      "description": "EXT4 volume",
                      "vendor": "Linux",
                      "physid": "1",
                      "businfo": "scsi@0:0.0.0,1",
                      "logicalname": [
                        "/dev/sda1",
                        "/etc/resolv.conf",
                        "/etc/hostname",
                        "/etc/hosts"
                      ],
                      "dev": "8:1",
                      "version": "1.0",
                      "serial": "706d5909-b68c-404c-8cf9-841e5396e0d0",
                      "size": 255998296064,
                      "capacity": 255998296064,
                      "configuration": {
                        "created": "2018-10-23 13:21:43",
                        "filesystem": "ext4",
                        "lastmountpoint": "/var/lib",
                        "modified": "2019-03-27 17:16:59",
                        "mount.fstype": "ext4",
                        "mount.options": "rw,relatime,data=ordered",
                        "mounted": "2019-03-27 17:16:59",
                        "state": "mounted"
                      },
                      "capabilities": {
                        "primary": "Primary partition",
                        "bootable": "Bootable partition (active)",
                        "journaled": true,
                        "extended_attributes": "Extended Attributes",
                        "large_files": "4GB+ files",
                        "huge_files": "16TB+ files",
                        "dir_nlink": "directories with 65000+ subdirs",
                        "recover": "needs recovery",
                        "64bit": "64bit filesystem",
                        "extents": "extent-based allocation",
                        "ext4": true,
                        "ext2": "EXT2/EXT3",
                        "initialized": "initialized volume"
                      }
                    }
                  ]
                }
              ]
            },
            {
              "id": "scsi:1",
              "class": "storage",
              "claimed": true,
              "physid": "2",
              "logicalname": "scsi6",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "cdrom",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:06:00:00:00",
                  "description": "DVD reader",
                  "physid": "0.0.0",
                  "businfo": "scsi@6:0.0.0",
                  "logicalname": "/dev/sr0",
                  "dev": "11:0",
                  "configuration": {
                    "status": "ready"
                  },
                  "capabilities": {
                    "audio": "Audio CD playback",
                    "dvd": "DVD playback"
                  }
                }
              ]
            },
            {
              "id": "scsi:2",
              "class": "storage",
              "claimed": true,
              "physid": "8",
              "logicalname": "scsi12",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "cdrom",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:12:00:00:00",
                  "description": "DVD reader",
                  "physid": "0.0.0",
                  "businfo": "scsi@12:0.0.0",
                  "logicalname": "/dev/sr1",
                  "dev": "11:1",
                  "configuration": {
                    "status": "ready"
                  },
                  "capabilities": {
                    "audio": "Audio CD playback",
                    "dvd": "DVD playback"
                  }
                }
              ]
            },
            {
              "id": "scsi:3",
              "class": "storage",
              "claimed": true,
              "physid": "9",
              "logicalname": "scsi18",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "cdrom",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:18:00:00:00",
                  "description": "DVD reader",
                  "physid": "0.0.0",
                  "businfo": "scsi@18:0.0.0",
                  "logicalname": "/dev/sr2",
                  "dev": "11:2",
                  "configuration": {
                    "status": "ready"
                  },
                  "capabilities": {
                    "audio": "Audio CD playback",
                    "dvd": "DVD playback"
                  }
                }
              ]
            }
          ]
        },
        {
          "id": "network",
          "class": "network",
          "claimed": true,
          "description": "Ethernet interface",
          "physid": "1",
          "logicalname": "eth0",
          "serial": "02:42:c0:a8:10:02",
          "units": "bit/s",
          "size": 10000000000,
          "configuration": {
            "autonegotiation": "off",
            "broadcast": "yes",
            "driver": "veth",
            "driverversion": "1.0",
            "duplex": "full",
            "ip": "192.168.16.2",
            "link": "yes",
            "multicast": "yes",
            "port": "twisted pair",
            "speed": "10Gbit/s"
          },
          "capabilities": {
            "ethernet": true,
            "physical": "Physical interface"
          }
        }
      ]
    },
    "lsusb": [],
    "lscpu": {
      "Architecture": "x86_64",
      "CPU_op_modes": "32-bit, 64-bit",
      "Byte_Order": "Little Endian",
      "CPUs": "4",
      "On_line_CPUs_list": "0-3",
      "Threads_per_core": "1",
      "Cores_per_socket": "1",
      "Sockets": "4",
      "Vendor_ID": "GenuineIntel",
      "CPU_family": "6",
      "Model": "158",
      "Model_name": "Intel(R) Core(TM) i7-7700K CPU @ 4.20GHz",
      "Stepping": "9",
      "CPU_MHz": "4200.000",
      "BogoMIPS": "8400.00",
      "L1d_cache": "32K",
      "L1i_cache": "32K",
      "L2_cache": "256K",
      "L3_cache": "8192K",
      "Flags": "fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht pbe syscall nx pdpe1gb lm constant_tsc rep_good nopl xtopology nonstop_tsc pni pclmulqdq dtes64 ds_cpl ssse3 sdbg fma cx16 xtpr pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch kaiser fsgsbase bmi1 hle avx2 bmi2 erms rtm xsaveopt arat"
    },
    "lspci": [
      {
        "slot": "00:00.0",
        "device_class_id": "0600",
        "vendor_class_id": "1275",
        "device_id": "1275",
        "vendor_id": "0000"
      },
      {
        "slot": "00:03.0",
        "device_class_id": "0200",
        "vendor_class_id": "1af4",
        "device_id": "103f",
        "vendor_id": "1af4"
      },
      {
        "slot": "00:06.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:02.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:05.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:1f.0",
        "device_class_id": "0601",
        "vendor_class_id": "8086",
        "device_id": "7000",
        "vendor_id": "0000"
      },
      {
        "slot": "00:01.0",
        "device_class_id": "0200",
        "vendor_class_id": "1af4",
        "device_id": "1000",
        "vendor_id": "1af4"
      },
      {
        "slot": "00:04.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:07.0",
        "device_class_id": "1000",
        "vendor_class_id": "1af4",
        "device_id": "1005",
        "vendor_id": "1af4"
      }
    ],
    "lsblk": [
      {
        "name": "sda",
        "maj:min": "8:0",
        "rm": "0",
        "size": "238.4G",
        "ro": "0",
        "type": "disk",
        "mountpoint": null,
        "children": [
          {
            "name": "sda1",
            "maj:min": "8:1",
            "rm": "0",
            "size": "238.4G",
            "ro": "0",
            "type": "part",
            "mountpoint": "/etc/hosts"
          }
        ]
      },
      {
        "name": "sr0",
        "maj:min": "11:0",
        "rm": "1",
        "size": "477.4M",
        "ro": "0",
        "type": "rom",
        "mountpoint": null
      },
      {
        "name": "sr1",
        "maj:min": "11:1",
        "rm": "1",
        "size": "120K",
        "ro": "0",
        "type": "rom",
        "mountpoint": null
      },
      {
        "name": "sr2",
        "maj:min": "11:2",
        "rm": "1",
        "size": "961.1M",
        "ro": "0",
        "type": "rom",
        "mountpoint": null
      }
    ],
    "lsdf": [
      {
        "mount": "/dev/sda1",
        "spacetotal": "235G",
        "spaceavail": "185G"
      }
    ]
  },
  "yolo2msghub": {
    "date": 1554317495,
    "yolo": {
      "mock": "horses",
      "info": {
        "type": "JPEG",
        "size": "773x512",
        "bps": "8-bit",
        "color": "sRGB"
      },
      "time": 0.963922,
      "count": 0,
      "detected": [
        {
          "entity": "person",
          "count": 0
        }
      ],
      "image": "<redacted>",
      "date": 1554317493
    }
  },
  "date": 1554316824,
  "hzn": {
    "agreementid": "3028e0a0e1156f7961d73dc8c9144a867ad73e5ac3c6c354f9c6c25e9dc74634",
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
    "date": 1554316824,
    "log_level": "info",
    "debug": false,
    "services": [
      {
        "name": "hal",
        "url": "http://hal"
      },
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "wan",
        "url": "http://wan"
      }
    ],
    "period": 30
  },
  "service": {
    "label": "yolo2msghub",
    "version": "0.0.11"
  }
}
```

# Registering as Pattern

```
{
  "global": [],
  "services": [
    {
      "org": "github@dcmartin.com",
      "url": "com.github.dcmartin.open-horizon.yolo2msghub",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "YOLO2MSGHUB_APIKEY": null, "LOG_LEVEL": "info", "DEBUG": false }
    },
    {
      "org": "github@dcmartin.com",
      "url": "com.github.dcmartin.open-horizon.yolo",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "YOLO_ENTITY": "person", "YOLO_PERIOD": 60, "YOLO_CONFIG": "tiny", "YOLO_THRESHOLD": 0.25 }
    },
    {
      "org": "github@dcmartin.com",
      "url": "com.github.dcmartin.open-horizon.cpu",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "CPU_PERIOD": 60 }
    },
    {
      "org": "github@dcmartin.com",
      "url": "com.github.dcmartin.open-horizon.wan",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "WAN_PERIOD": 900 }
    },
    {
      "org": "github@dcmartin.com",
      "url": "com.github.dcmartin.open-horizon.hal",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": { "HAL_PERIOD": 1800 }
    }
  ]
}
```


### Pattern registration
Register nodes using a derivative of the template [`userinput.json`][userinput].  Variables may be modified in the `userinput.json` file, _or_ may be defined in a file of the same name; **contents should be JSON**, e.g. quoted strings; extract from downloaded API keys using `jq` command:  

```
% jq '.api_key' {kafka-apiKey-file} > YOLO2MSGHUB_APIKEY
```

**NOTE:** Refer to _Required Services_ for their variables.

#### Example registration
```
% hzn register -u ${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:{apikey} -n {nodeid}:{token} -e ${HZN_ORG_ID} -f userinput.json
```
# Sample

![sample.png](samples/sample.png?raw=true "YOLO2MSGHUB")

# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../yolo2msghub/userinput.json
[service-json]: ../yolo2msghub/service.json
[build-json]: ../yolo2msghub/build.json
[dockerfile]: ../yolo2msghub/Dockerfile
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
