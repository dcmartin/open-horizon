# &#128249; `motion2mqtt` - detect motion and send to MQTT

Monitors attached camera and provides [motion-project.github.io][motion-project-io] as micro-service, transmitting _events_ and _images_ to a designated [MQTT][mqtt-org] host.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.motion2mqtt.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.motion2mqtt.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.motion2mqtt.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.motion2mqtt`
+ `version` - `0.0.10`

## Service variables
+ `MOTION_GROUP` - group name (aka top-level topic); defaults to `motion`
+ `MOTION_CLIENT` - device name; defaults to `HZN_CLIENT_ID` or `hostname`
+ `MOTION_TIMEZONE` - timezone; default: `GMT`
+ `MOTION_POST_PICTURES` - post pictures; default `off`; options: `on`, `first`, `last`, `best`, and `center`
+ `MOTION_LOCATE_MODE` - default `off`; options: `box`,`cross`,`redbox`,`redcross`
+ `MOTION_EVENT_GAP` - default: `30`
+ `MOTION_FRAMERATE` - default: `2`
+ `MOTION_THRESHOLD` - default: `5000`
+ `MOTION_THRESHOLD_TUNE` - default: `false`
+ `MOTION_NOISE_LEVEL` - default: `32`
+ `MOTION_NOISE_TUNE` - default: `true`
+ `MOTION_LOG_LEVEL` - level of logging for motion2mqtt; default `2`
+ `MOTION_LOG_TYPE` - type of logging for motion2mqtt; default `all`
+ `MOTION_PERIOD` - watchdog check interval in seconds; default: 30
+ `MQTT_HOST` - IP or FQDN for mqtt host; default `mqtt`
+ `MQTT_PORT` - port number; defaults to `1883`
+ `MQTT_USERNAME` - MQTT username; defaults to ""
+ `MQTT_PASSWORD` - MQTT password; defaults to ""
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - default: `false`

## Required Services

### [`yolo4motion`](../yolo4motion)
+ `MOTION_GROUP`
+ `MOTION_CLIENT`
+ `YOLO4MOTION_CAMERA`
+ `YOLO4MOTION_TOPIC_EVENT`
+ `YOLO4MOTION_TOPIC_PAYLOAD`
+ `YOLO4MOTION_USE_MOCK`
+ `YOLO4MOTION_TOO_OLD`
+ `YOLO_CONFIG`
+ `YOLO_ENTITY`
+ `YOLO_SCALE`
+ `MQTT_HOST`
+ `MQTT_PORT`
+ `MQTT_USERNAME`
+ `MQTT_PASSWORD`

### [`mqtt`](../mqtt)
+ `MQTT_PERIOD`
+ `MQTT_PORT`
+ `MQTT_USERNAME`
+ `MQTT_PASSWORD`

### [`cpu`](../cpu)
+ `CPU_PERIOD`

### [`hal`](../hal)
+ `HAL_PERIOD`

## Description
This service detects [motion](http://motion-project.io), detects and identifies entities using [YOLO](http://darknet).  All image processing and AI classification is executed on the device; no GPU is currently utilized. Timing varies by device type; for example a 320x240 8-bit pixel image:

+ RaspberryPi3B+ - approximately 50 seconds
+ nVidia Jetson Nano - approximately 5 seconds
+ AMD64/Intel - approximately 2 seconds

### Output
This service publishes JSON *events*, JPEG *images*, and GIF *animations* of motion.  The event information includes details on the event:

**EVENT**

```
{
  "hal": {
    "date": 1556060398,
    "lshw": {
      "id": "7a5f6088604b",
      "class": "system",
      "claimed": true,
      "description": "Computer",
      "product": "Raspberry Pi 3 Model B Rev 1.2",
      "serial": "00000000c4a26fd9",
      "width": 32,
      "children": [ { "id": "core", "class": "bus", "claimed": true, "description": "Motherboard", "physid": "0", "capabilities": { "raspberrypi_3-model-b": true, "brcm_bcm2837": true }, "children": [ { "id": "cpu:0", "class": "processor", "claimed": true, "description": "CPU", "product": "cpu", "physid": "0", "businfo": "cpu@0", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:1", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "1", "businfo": "cpu@1", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:2", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "2", "businfo": "cpu@2", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:3", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "3", "businfo": "cpu@3", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "memory", "class": "memory", "claimed": true, "description": "System memory", "physid": "4", "units": "bytes", "size": 972234752 } ] }, { "id": "network", "class": "network", "claimed": true, "description": "Ethernet interface", "physid": "1", "logicalname": "eth0", "serial": "02:42:ac:1d:00:02", "units": "bit/s", "size": 10000000000, "configuration": { "autonegotiation": "off", "broadcast": "yes", "driver": "veth", "driverversion": "1.0", "duplex": "full", "ip": "172.29.0.2", "link": "yes", "multicast": "yes", "port": "twisted pair", "speed": "10Gbit/s" }, "capabilities": { "ethernet": true, "physical": "Physical interface" } } ]
    },
    "lsusb": [
      { "bus_number": "001", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "Bus 001 Device 001: ID 1d6b:0002", "manufacture_device_name": "Bus 001 Device 001: ID 1d6b:0002" },
      { "bus_number": "001", "device_id": "003", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 003: ID 0424:ec00", "manufacture_device_name": "Bus 001 Device 003: ID 0424:ec00" },
      { "bus_number": "001", "device_id": "002", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 002: ID 0424:9514", "manufacture_device_name": "Bus 001 Device 002: ID 0424:9514" },
      { "bus_number": "001", "device_id": "004", "device_bus_number": "1415", "manufacture_id": "Bus 001 Device 004: ID 1415:2000", "manufacture_device_name": "Bus 001 Device 004: ID 1415:2000" }
    ],
    "lscpu": {
      "Architecture": "armv7l",
      "Byte_Order": "Little Endian",
      "CPUs": "4",
      "On_line_CPUs_list": "0-3",
      "Threads_per_core": "1",
      "Cores_per_socket": "4",
      "Sockets": "1",
      "Vendor_ID": "ARM",
      "Model": "4",
      "Model_name": "Cortex-A53",
      "Stepping": "r0p4",
      "CPU_max_MHz": "1200.0000",
      "CPU_min_MHz": "600.0000",
      "BogoMIPS": "76.80",
      "Flags": "half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32"
    },
    "lspci": null,
    "lsblk": [
      { "name": "mmcblk0", "maj:min": "179:0", "rm": "0", "size": "29.7G", "ro": "0", "type": "disk", "mountpoint": null, "children": [ { "name": "mmcblk0p1", "maj:min": "179:1", "rm": "0", "size": "43.9M", "ro": "0", "type": "part", "mountpoint": null }, { "name": "mmcblk0p2", "maj:min": "179:2", "rm": "0", "size": "29.7G", "ro": "0", "type": "part", "mountpoint": "/etc/hosts" } ] }
    ],
    "lsdf": [
      {
        "mount": "/dev/root",
        "spacetotal": "30G",
        "spaceavail": "26G"
      }
    ]
  },
  "mqtt": {
    "date": 1556060385,
    "pid": 31,
    "version": "mosquitto version 1.4.15",
    "broker": {
      "bytes": { "received": 77697, "sent": 48054 },
      "clients": { "connected": 1 },
      "load": { "messages": { "sent": { "one": 123.13, "five": 122.57, "fifteen": 97.47 }, "received": { "one": 123.08, "five": 122.46, "fifteen": 97.82 } } },
      "publish": { "messages": { "received": 0, "sent": 959, "dropped": 0 } },
      "subscriptions": { "count": 1 }
    }
  },
  "cpu": {
    "date": 1556060385,
    "percent": 65.84
  },
  "motion2mqtt": {
    "date": "1556059235",
    "motion": {
      "event": {
        "device": "",
        "camera": "default",
        "event": "03",
        "start": 1556034572,
        "image": { "device": "", "camera": "default", "type": "jpeg", "date": 1556034625, "seqno": "01", "event": "03", "id": "20190423155025-03-01", "center": { "x": 484, "y": 206 }, "width": 330, "height": 364, "size": 64749, "noise": 30 },
        "elapsed": 79,
        "end": 1556034651,
        "date": 1556060157, "images": [ "20190423154932-03-00", "20190423154932-03-01", "20190423154933-03-00", "20190423154933-03-01", "20190423154934-03-00", "20190423154934-03-01", "20190423154935-03-00", "20190423154935-03-01", "20190423154936-03-00", "20190423154936-03-01", "20190423154937-03-00", "20190423154937-03-01", "20190423154938-03-00", "20190423154938-03-01", "20190423154939-03-00", "20190423154939-03-01", "20190423155001-03-00", "20190423155001-03-01", "20190423155002-03-00", "20190423155002-03-01", "20190423155003-03-00", "20190423155003-03-01", "20190423155004-03-00", "20190423155004-03-01", "20190423155005-03-00", "20190423155005-03-01", "20190423155006-03-00", "20190423155006-03-01", "20190423155007-03-00", "20190423155007-03-01", "20190423155008-03-00", "20190423155008-03-01", "20190423155009-03-00", "20190423155009-03-01", "20190423155010-03-00", "20190423155011-03-00", "20190423155018-03-01", "20190423155019-03-00", "20190423155019-03-01", "20190423155020-03-00", "20190423155020-03-01", "20190423155021-03-00", "20190423155022-03-00", "20190423155022-03-01", "20190423155023-03-00", "20190423155023-03-01", "20190423155024-03-00", "20190423155024-03-01", "20190423155025-03-00", "20190423155025-03-01", "20190423155026-03-00", "20190423155026-03-01", "20190423155027-03-00", "20190423155027-03-01", "20190423155028-03-00", "20190423155028-03-01", "20190423155029-03-00", "20190423155029-03-01", "20190423155030-03-00", "20190423155030-03-01", "20190423155031-03-00", "20190423155031-03-01", "20190423155032-03-00", "20190423155032-03-01", "20190423155033-03-00", "20190423155034-03-00", "20190423155034-03-01", "20190423155035-03-00", "20190423155035-03-01", "20190423155036-03-00", "20190423155036-03-01", "20190423155037-03-00", "20190423155037-03-01", "20190423155038-03-00", "20190423155038-03-01", "20190423155039-03-00", "20190423155039-03-01", "20190423155040-03-00", "20190423155040-03-01", "20190423155041-03-00", "20190423155041-03-01", "20190423155042-03-00", "20190423155042-03-01", "20190423155043-03-00", "20190423155043-03-01", "20190423155044-03-00", "20190423155044-03-01", "20190423155045-03-00", "20190423155045-03-01", "20190423155046-03-00", "20190423155046-03-01", "20190423155047-03-00", "20190423155047-03-01", "20190423155048-03-00", "20190423155048-03-01", "20190423155049-03-00", "20190423155049-03-01", "20190423155050-03-00", "20190423155050-03-01", "20190423155051-03-00", "20190423155051-03-01" ],
        "base64": "<redacted>"
      },
      "image": {
        "device": "",
        "camera": "default",
        "type": "jpeg",
        "date": 1556034625,
        "seqno": "01",
        "event": "03",
        "id": "20190423155025-03-01",
        "center": { "x": 484, "y": 206 },
        "width": 330,
        "height": 364,
        "size": 64749,
        "noise": 30,
        "base64": "<redacted>"
      }
    }
  },
  "date": 1556059231,
  "hzn": {
    "agreementid": "fc60f3947c15aa311097479bed3fbaf05237e289597940ce366d98b43e0067ef",
    "arch": "arm",
    "cpus": 1,
    "device_id": "test-sdr-4",
    "exchange_url": "https://alpha.edge-fabric.com/v1/",
    "host_ips": [ "127.0.0.1", "192.168.1.71", "192.168.1.70", "172.17.0.1" ],
    "organization": "github@dcmartin.com",
    "ram": 0,
    "pattern": {
      "key": "github@dcmartin.com/motion2mqtt",
      "value": {
        "owner": "github@dcmartin.com/github@dcmartin.com",
        "label": "motion2mqtt",
        "description": "motion2mqtt as a pattern",
        "public": true,
        "services": [
          { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "github@dcmartin.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.13", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
          { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.13", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
          { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.13", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
          { "serviceUrl": "com.github.dcmartin.open-horizon.mqtt2kafka", "serviceOrgid": "github@dcmartin.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
          { "serviceUrl": "com.github.dcmartin.open-horizon.mqtt2kafka", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
          { "serviceUrl": "com.github.dcmartin.open-horizon.mqtt2kafka", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } }
        ],
        "agreementProtocols": [
          {
            "name": "Basic"
          }
        ],
        "lastUpdated": "2019-03-27T18:06:58.164Z[UTC]"
      }
    }
  },
  "config": {
    "log_level": "info",
    "debug": true,
    "group": "motion",
    "device": "test-sdr-4",
    "timezone": "/usr/share/zoneinfo/America/Los_Angeles",
    "services": [
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "mqtt",
        "url": "http://mqtt"
      },
      {
        "name": "hal",
        "url": "http://hal"
      }
    ],
    "mqtt": {
      "host": "mqtt",
      "port": 1883,
      "username": "",
      "password": ""
    },
    "motion": {
      "post_pictures": "center",
      "locate_mode": "off",
      "event_gap": 30,
      "framerate": 2,
      "threshold": 5000,
      "threshold_tune": false,
      "noise_level": 32,
      "noise_tune": true,
      "log_level": 6,
      "log_type": "all"
    }
  },
  "service": {
    "label": "motion2mqtt",
    "version": "0.0.13.13"
  }
}
```

**IMAGE**

<img src="samples/annotated-image.png">


**ANIMATION**

<img src="samples/animated-image.gif">


## How To Use
Copy this [repository][repository], change to the `motion2mqtt` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/motion2mqtt
% make
...
{
  "hal": null,
  "mqtt": null,
  "cpu": null,
  "motion2mqtt": {
    "date": "1555611614",
    "cpu": false,
    "motion": {
      "event": {
        "base64": false
      },
      "image": {
        "base64": false
      }
    }
  },
  "date": 1555611614,
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
    "debug": true,
    "group": "newman",
    "device": "",
    "timezone": "/usr/share/zoneinfo/America/Los_Angeles",
    "services": [
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "mqtt",
        "url": "http://mqtt"
      },
      {
        "name": "hal",
        "url": "http://hal"
      }
    ],
    "mqtt": {
      "host": "192.168.1.40",
      "port": 1883,
      "username": "",
      "password": ""
    },
    "motion": {
      "post_pictures": "center",
      "locate_mode": "off",
      "event_gap": 30,
      "framerate": 2,
      "threshold": 5000,
      "threshold_tune": false,
      "noise_level": 32,
      "noise_tune": true,
      "log_level": 6,
      "log_type": "all"
    }
  },
  "service": {
    "label": "motion2mqtt",
    "version": "0.0.13.14"
  }
}
```

The `motion2mqtt` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

```
{
  "hal": {
    "date": 1555611264,
    "lshw": { "id": "8ecb617fb0f2", "class": "system", "claimed": true, "description": "Computer", "product": "Raspberry Pi 3 Model B Rev 1.2", "serial": "00000000c4a26fd9", "width": 32, "children": [ { "id": "core", "class": "bus", "claimed": true, "description": "Motherboard", "physid": "0", "capabilities": { "raspberrypi_3-model-b": true, "brcm_bcm2837": true }, "children": [ { "id": "cpu:0", "class": "processor", "claimed": true, "description": "CPU", "product": "cpu", "physid": "0", "businfo": "cpu@0", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:1", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "1", "businfo": "cpu@1", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:2", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "2", "businfo": "cpu@2", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "cpu:3", "class": "processor", "disabled": true, "claimed": true, "description": "CPU", "product": "cpu", "physid": "3", "businfo": "cpu@3", "units": "Hz", "size": 1200000000, "capacity": 1200000000, "capabilities": { "cpufreq": "CPU Frequency scaling" } }, { "id": "memory", "class": "memory", "claimed": true, "description": "System memory", "physid": "4", "units": "bytes", "size": 972234752 } ] }, { "id": "network", "class": "network", "claimed": true, "description": "Ethernet interface", "physid": "1", "logicalname": "eth0", "serial": "02:42:ac:13:00:02", "units": "bit/s", "size": 10000000000, "configuration": { "autonegotiation": "off", "broadcast": "yes", "driver": "veth", "driverversion": "1.0", "duplex": "full", "ip": "172.19.0.2", "link": "yes", "multicast": "yes", "port": "twisted pair", "speed": "10Gbit/s" }, "capabilities": { "ethernet": true, "physical": "Physical interface" } } ] },
    "lsusb": [ { "bus_number": "001", "device_id": "001", "device_bus_number": "1d6b", "manufacture_id": "Bus 001 Device 001: ID 1d6b:0002", "manufacture_device_name": "Bus 001 Device 001: ID 1d6b:0002" }, { "bus_number": "001", "device_id": "003", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 003: ID 0424:ec00", "manufacture_device_name": "Bus 001 Device 003: ID 0424:ec00" }, { "bus_number": "001", "device_id": "002", "device_bus_number": "0424", "manufacture_id": "Bus 001 Device 002: ID 0424:9514", "manufacture_device_name": "Bus 001 Device 002: ID 0424:9514" }, { "bus_number": "001", "device_id": "004", "device_bus_number": "1415", "manufacture_id": "Bus 001 Device 004: ID 1415:2000", "manufacture_device_name": "Bus 001 Device 004: ID 1415:2000" } ],
    "lscpu": { "Architecture": "armv7l", "Byte_Order": "Little Endian", "CPUs": "4", "On_line_CPUs_list": "0-3", "Threads_per_core": "1", "Cores_per_socket": "4", "Sockets": "1", "Vendor_ID": "ARM", "Model": "4", "Model_name": "Cortex-A53", "Stepping": "r0p4", "CPU_max_MHz": "1200.0000", "CPU_min_MHz": "600.0000", "BogoMIPS": "76.80", "Flags": "half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32" },
    "lspci": null,
    "lsblk": [ { "name": "mmcblk0", "maj:min": "179:0", "rm": "0", "size": "29.7G", "ro": "0", "type": "disk", "mountpoint": null, "children": [ { "name": "mmcblk0p1", "maj:min": "179:1", "rm": "0", "size": "43.9M", "ro": "0", "type": "part", "mountpoint": null }, { "name": "mmcblk0p2", "maj:min": "179:2", "rm": "0", "size": "29.7G", "ro": "0", "type": "part", "mountpoint": "/etc/hosts" } ] } ],
    "lsdf": [ { "mount": "/dev/root", "spacetotal": "30G", "spaceavail": "24G" } ]
  },
  "mqtt": {
    "date": 1555611271,
    "pid": 29,
    "version": "mosquitto version 1.4.15",
    "broker": { "bytes": { "received": 3238860, "sent": 2029471 }, "clients": { "connected": 2 }, "load": { "messages": { "sent": { "one": 119.53, "five": 124.37, "fifteen": 126.82 }, "received": { "one": 117.78, "five": 123.82, "fifteen": 126.59 } } }, "publish": { "messages": { "received": 0, "sent": 39625, "dropped": 0 } }, "subscriptions": { "count": 2 } }
  },
  "cpu": {
    "date": 1555611265,
    "percent": 54.95
  },
  "motion2mqtt": {
    "date": "1555554900",
    "motion": 
       { "event": { "device": "", "camera": "default", "event": "94", "start": 1555585716, "image": { "device": "", "camera": "default", "type": "jpeg", "date": 1555585731, "seqno": "00", "event": "94", "id": "20190418110851-94-00", "center": { "x": 347, "y": 159 }, "width": 62, "height": 154, "size": 8805, "noise": 33 }, "elapsed": 48, "end": 1555585764, "date": 1555611162, "images": [ "20190418110836-94-00", "20190418110836-94-01", "20190418110837-94-00", "20190418110837-94-01", "20190418110838-94-00", "20190418110838-94-01", "20190418110839-94-00", "20190418110839-94-01", "20190418110840-94-00", "20190418110840-94-01", "20190418110841-94-00", "20190418110841-94-01", "20190418110842-94-00", "20190418110842-94-01", "20190418110843-94-00", "20190418110843-94-01", "20190418110844-94-00", "20190418110844-94-01", "20190418110845-94-00", "20190418110845-94-01", "20190418110846-94-00", "20190418110846-94-01", "20190418110847-94-00", "20190418110847-94-01", "20190418110848-94-00", "20190418110848-94-01", "20190418110849-94-00", "20190418110849-94-01", "20190418110850-94-00", "20190418110850-94-01", "20190418110851-94-00", "20190418110851-94-01", "20190418110852-94-00", "20190418110852-94-01", "20190418110853-94-00", "20190418110853-94-01", "20190418110854-94-00", "20190418110854-94-01", "20190418110912-94-01", "20190418110913-94-00", "20190418110913-94-01", "20190418110914-94-00", "20190418110914-94-01", "20190418110915-94-00", "20190418110915-94-01", "20190418110916-94-00", "20190418110916-94-01", "20190418110917-94-00", "20190418110917-94-01", "20190418110918-94-00", "20190418110918-94-01", "20190418110919-94-00", "20190418110919-94-01", "20190418110920-94-00", "20190418110920-94-01", "20190418110921-94-00", "20190418110921-94-01", "20190418110922-94-00", "20190418110922-94-01", "20190418110923-94-00", "20190418110923-94-01", "20190418110924-94-00" ], "base64": "<redacted>" },
      "image": { "device": "", "camera": "default", "type": "jpeg", "date": 1555585731, "seqno": "00", "event": "94", "id": "20190418110851-94-00", "center": { "x": 347, "y": 159 }, "width": 62, "height": 154, "size": 8805, "noise": 33, "base64": "<redacted>" } } },
  "date": 1555554894,
  "hzn": {
    "agreementid": "3bc1379429803027b5060865bc5d1f3cc7d58bc25b093efad5c34898d065b4fe",
    "arch": "arm",
    "cpus": 1,
    "device_id": "test-sdr-4",
    "exchange_url": "https://alpha.edge-fabric.com/v1/",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.71",
      "192.168.1.70",
      "172.17.0.1"
    ],
    "organization": "github@dcmartin.com",
    "ram": 0,
    "pattern": { "key": "github@dcmartin.com/motion2mqtt", "value": { "owner": "github@dcmartin.com/github@dcmartin.com", "label": "motion2mqtt", "description": "motion2mqtt as a pattern", "public": true, "services": [ { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "github@dcmartin.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.13", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } }, { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.13", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } }, { "serviceUrl": "com.github.dcmartin.open-horizon.motion2mqtt", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.13", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } }, { "serviceUrl": "com.github.dcmartin.open-horizon.mqtt2kafka", "serviceOrgid": "github@dcmartin.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } }, { "serviceUrl": "com.github.dcmartin.open-horizon.mqtt2kafka", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } }, { "serviceUrl": "com.github.dcmartin.open-horizon.mqtt2kafka", "serviceOrgid": "github@dcmartin.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } } ], "agreementProtocols": [ { "name": "Basic" } ], "lastUpdated": "2019-03-27T18:06:58.164Z[UTC]" } } },
  "config": {
    "log_level": "info",
    "debug": true,
    "group": "newman",
    "device": "test-sdr-4",
    "timezone": "/usr/share/zoneinfo/America/Los_Angeles",
    "services": [
      {
        "name": "cpu",
        "url": "http://cpu"
      },
      {
        "name": "mqtt",
        "url": "http://mqtt"
      },
      {
        "name": "hal",
        "url": "http://hal"
      }
    ],
    "mqtt": {
      "host": "192.168.1.40",
      "port": 1883,
      "username": "",
      "password": ""
    },
    "motion": {
      "post_pictures": "center",
      "locate_mode": "off",
      "event_gap": 30,
      "framerate": 2,
      "threshold": 5000,
      "threshold_tune": false,
      "noise_level": 32,
      "noise_tune": true,
      "log_level": 6,
      "log_type": "all"
    }
  },
  "service": {
    "label": "motion2mqtt",
    "version": "0.0.13.13"
  }
}
```

## Video for LINUX

V4l2 Option|	FOURCC|	v4l2_palette option
:-------|-------:|-------:|-------:
`V4L2_PIX_FMT_SN9C10X`|`S910`|`0`
`V4L2_PIX_FMT_SBGGR16`|`BYR2`|`1`
`V4L2_PIX_FMT_SBGGR8`|`BA81`|`2`
`V4L2_PIX_FMT_SPCA561`|`S561`|`3`
`V4L2_PIX_FMT_SGBRG8`|`GBRG`|`4`
`V4L2_PIX_FMT_SGRBG8`|`GRBG`|`5`
`V4L2_PIX_FMT_PAC207`|`P207`|`6`
`V4L2_PIX_FMT_PJPG`|`PJPG`|`7`
`V4L2_PIX_FMT_MJPEG`|`MJPG`|`8`
`V4L2_PIX_FMT_JPEG`|`JPEG`|`9`
`V4L2_PIX_FMT_RGB24`|`RGB3`|`10`
`V4L2_PIX_FMT_SPCA501`|`S501`|`11`
`V4L2_PIX_FMT_SPCA505`|`S505`|`12`
`V4L2_PIX_FMT_SPCA508`|`S508`|`13`
`V4L2_PIX_FMT_UYVY`|`UYVY`|`14`
`V4L2_PIX_FMT_YUYV`|`YUYV`|`15`
`V4L2_PIX_FMT_YUV422P`|`422P`|`16`
`V4L2_PIX_FMT_YUV420`|`YU12`|`17`
`V4L2_PIX_FMT_Y10`|`Y10`|`18`
`V4L2_PIX_FMT_Y12`|`Y12`|`19`
`V4L2_PIX_FMT_GREY`|`GREY`|`20`
`V4L2_PIX_FMT_H264`|`H264`|`21`

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../motion2mqtt/userinput.json
[service-json]: ../motion2mqtt/service.json
[build-json]: ../motion2mqtt/build.json
[dockerfile]: ../motion2mqtt/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
