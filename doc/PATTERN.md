# `PATTERN.md` - publishing patterns

# 1. Introduction

Patterns are composed of services and depend on a successful service build.  All services for all architectures specified in the _pattern_ configuration file must be available in the designated exchange.

## Example `pattern.json` template

The `pattern.json` template file for `yolo2msghub` (see below) contains human-readable attributes and a listing of services that are included.  In this example, there are three `services` in the array; one for each supported architecture.  Each service is identified by a the URL, organization, architecture, and acceptable versions.

```
{
  "label": "yolo2msghub",
  "description": "yolo and friends as a pattern",
  "public": true,
  "services": [
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "github@dcmartin.com",
      "serviceArch": "amd64",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "github@dcmartin.com",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "0.0.11"
        }
      ]
    },
    {
      "serviceUrl": "com.github.dcmartin.open-horizon.yolo2msghub",
      "serviceOrgid": "github@dcmartin.com",
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

# 2. Publish and validate
Patterns are published to an exchange using a completed configuration template.  When all services in a pattern have been published to the exchange, the pattern itself can be published.

## 2.1 `pattern-publish`

Patterns are published using the `make` command in the corresponding subdirectory of the repository; for example:

```
cd $GD/open-horizon/yolo2msghub
make pattern-publish
```

Example output:

```
>>> MAKE -- 19:19:58 -- publishing: yolo2msghub; organization: github@dcmartin.com; exchange: https://alpha.edge-fabric.com/v1
Updating yolo2msghub in the exchange...
Storing github@dcmartin.com.pem with the pattern in the exchange...
```

## 2.2 `pattern-validate`
Validates the pattern registration in the exchange using the `hzn` command-line-interface tool.

```
cd $GD/open-horizon/yolo2msghub
make pattern-validate
```

Example output:

```
>>> MAKE -- 09:37:27 -- validating: yolo2msghub-beta; organization: github@dcmartin.com; exchange: https://alpha.edge-fabric.com/v1
All signatures verified
Found pattern github@dcmartin.com/yolo2msghub-beta
```

# 3. Deployment Testing

Client devices and virtual machines may be targeted for use as development nodes; refer to [`setup/README.md`][setup-readme-md] for additional information.  Devices are controlled using the `ssh` command via both the `Makefile` as well as through the `nodereg.sh` script; this script processes devices through stages until registered:

[setup-readme-md]: ../setup/README.md

+ `null` - installs Open Horizon on the device
+ `unconfigured` - registers the node for the current pattern
+ `unconfiguring` - purges the device of Open Horizon
+ `configuring` - dumps `hzn eventlog list` and unregisters the node
+ `configured` - unregisters node iff pattern `url` does not match current

See `make nodes` below for additional information.

## 3.1 Create nodes

Once devices have been configured for use a development nodes (e.g. see [`setup/RPI.md`][setup-rpi-md]), a file of device identifiers should be created: `TEST_TMP_MACHINES`; for example:

[setup-rpi-md]: ../setup/RPI.md

```
test-amd64-1.local
test-arm-1.local
nano-1.local
```

## 3.2 Inspect nodes
Devices can be inspected through the `make nodes-list` command:

```
% cd $GD/open-horizon/yolo2msghub
% make nodes-list
```

Example output when the nodes have no registered pattern

```
>>> MAKE -- 09:16:59 -- listing nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:16:59 -- listing test-arm-1.local
{"node":"test-arm-1"}
{"agreements":[]}
>>> MAKE -- 09:17:01 -- listing test-amd64-1.local
{"node":"556a2d66d0f0321bb169ca1598ce66223e21e613"}
{"agreements":[]}
>>> MAKE -- 09:17:03 -- listing nano-1.local
{"node":"73b37a7bdc25f9785fbd423412c7955cd383ef95"}
{"agreements":[]}
```

Example output when nodes have registered successfully for a pattern:

```
>>> MAKE -- 09:27:42 -- listing nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:27:42 -- listing test-arm-1.local
{"node":"test-arm-1"}
{"agreements":[{"url":"com.github.dcmartin.open-horizon.yolo2msghub-beta","org":"github@dcmartin.com","version":"0.0.11","arch":"arm"}]}
{"services":["com.github.dcmartin.open-horizon.yolo2msghub-beta","com.github.dcmartin.open-horizon.yolo-beta","com.github.dcmartin.open-horizon.cpu-beta","com.github.dcmartin.open-horizon.wan-beta","com.github.dcmartin.open-horizon.hal-beta"]}
{"container":"1da0c92c6c7ef1e137b174b741ed1ab49032343ef25008990399adb41d4f69ca-yolo2msghub"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_fd5d572f-88a6-479c-aa90-4f78cfbb9f31-cpu"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.hal-beta_0.0.3_1c898880-3c23-4d4d-826b-6009d8327e8d-hal"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.wan-beta_0.0.3_131f2992-8a46-4d12-86c8-55158643eb3c-wan"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo-beta_0.0.8_2dedfd5c-316b-4f55-ba9a-71e4f0acae39-yolo"}
>>> MAKE -- 09:27:44 -- listing test-amd64-1.local
{"node":"test-amd64-1"}
{"agreements":[{"url":"com.github.dcmartin.open-horizon.yolo2msghub-beta","org":"github@dcmartin.com","version":"0.0.11","arch":"amd64"}]}
{"services":["com.github.dcmartin.open-horizon.cpu-beta","com.github.dcmartin.open-horizon.wan-beta","com.github.dcmartin.open-horizon.hal-beta","com.github.dcmartin.open-horizon.yolo2msghub-beta","com.github.dcmartin.open-horizon.yolo-beta"]}
{"container":"deeb4976f5bcf517a3d2ad430d722f017b461b71a5690a936e16faed2295386d-yolo2msghub"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_3d22f2a4-e761-4f0a-a6a1-71980243f225-cpu"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.hal-beta_0.0.3_157f5aef-0ee0-48cc-9957-be18adb10d0d-hal"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.wan-beta_0.0.3_2219e957-6a29-4f18-a080-fc4e548f9fb7-wan"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo-beta_0.0.8_451ea44f-483d-4a33-a676-023e22944226-yolo"}
>>> MAKE -- 09:27:46 -- listing nano-1.local
{"node":"nano-1"}
{"agreements":[{"url":"com.github.dcmartin.open-horizon.yolo2msghub-beta","org":"github@dcmartin.com","version":"0.0.11","arch":"arm64"}]}
{"services":["com.github.dcmartin.open-horizon.cpu-beta","com.github.dcmartin.open-horizon.wan-beta","com.github.dcmartin.open-horizon.hal-beta","com.github.dcmartin.open-horizon.yolo2msghub-beta","com.github.dcmartin.open-horizon.yolo-beta"]}
{"container":"0b73a5727ece8c73d74013e08891825697cc37ed7a0fb90d83dff2770f72c42d-yolo2msghub"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-beta_0.0.3_7b66a0f6-bdaf-4e4f-9bd7-b6c60b79ab34-cpu"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.hal-beta_0.0.3_0fa6224c-be4d-4553-a50d-c9b8938cedbb-hal"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.wan-beta_0.0.3_7cfda214-961b-44bc-82cd-8b784fd94286-wan"}
{"container":"dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.yolo-beta_0.0.8_c1fa9aa4-509d-46f1-8555-e23c5f8bb813-yolo"}
```

## 3.3 Register nodes
Devices can be registered for a pattern using the `make nodes` command:

```
% cd $GD/open-horizon/yolo2msghub
% make nodes
```

Example output when nodes are unregistered:

```
Created horizon metadata files in /Volumes/dcmartin/GIT/beta/open-horizon/yolo2msghub/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 09:18:02 -- registering nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:18:02 -- registering test-arm-1.local 
+++ WARN -- ./nodereg.sh 20540 -- missing service organization; using github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20540 -- test-arm-1.local at IP: 192.168.1.220
--- INFO -- ./nodereg.sh 20540 -- registering test-arm-1.local with pattern: github@dcmartin.com/yolo2msghub-beta; input: horizon/userinput.json
>>> MAKE -- 09:18:26 -- registering test-amd64-1.local 
+++ WARN -- ./nodereg.sh 20587 -- missing service organization; using github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20587 -- test-amd64-1.local at IP: 192.168.1.187
--- INFO -- ./nodereg.sh 20587 -- registering test-amd64-1.local with pattern: github@dcmartin.com/yolo2msghub-beta; input: horizon/userinput.json
>>> MAKE -- 09:18:46 -- registering nano-1.local 
+++ WARN -- ./nodereg.sh 20630 -- missing service organization; using github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20630 -- nano-1.local at IP: 192.168.1.206
--- INFO -- ./nodereg.sh 20630 -- registering nano-1.local with pattern: github@dcmartin.com/yolo2msghub-beta; input: horizon/userinput.json
```

Repeated invocations of the `make nodes` command will yield confirmation of registration:

```
Created horizon metadata files in /Volumes/dcmartin/GIT/beta/open-horizon/yolo2msghub/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 09:25:56 -- registering nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:25:57 -- registering test-arm-1.local 
+++ WARN -- ./nodereg.sh 20927 -- missing service organization; using github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20927 -- test-arm-1.local at IP: 192.168.1.220
--- INFO -- ./nodereg.sh 20927 -- test-arm-1.local -- configured with github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20927 -- test-arm-1.local -- version: 0.0.11; url: com.github.dcmartin.open-horizon.yolo2msghub-beta
>>> MAKE -- 09:26:02 -- registering test-amd64-1.local 
+++ WARN -- ./nodereg.sh 20980 -- missing service organization; using github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20980 -- test-amd64-1.local at IP: 192.168.1.187
--- INFO -- ./nodereg.sh 20980 -- test-amd64-1.local -- configured with github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 20980 -- test-amd64-1.local -- version: 0.0.11; url: com.github.dcmartin.open-horizon.yolo2msghub-beta
>>> MAKE -- 09:26:06 -- registering nano-1.local 
+++ WARN -- ./nodereg.sh 21034 -- missing service organization; using github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 21034 -- nano-1.local at IP: 192.168.1.206
--- INFO -- ./nodereg.sh 21034 -- nano-1.local -- configured with github@dcmartin.com/yolo2msghub-beta
--- INFO -- ./nodereg.sh 21034 -- nano-1.local -- version: 0.0.11; url: com.github.dcmartin.open-horizon.yolo2msghub-beta
```

## 3.4 Test nodes
Nodes registered with a pattern may be tested with the `make nodes-test` command; the test output is dependent on `TEST_NODE_FILTER` file contents; the first non-commented line in that file is used as a `jq` expression to process the status output.

```
% cd $GD/open-horizon/yolo2msghub
% make nodes-test
```

Example output when nodes are registered and operating properly:

```
>>> MAKE -- 09:31:30 -- testing: yolo2msghub-beta; node: test-arm-1.local; port: 8587:8587; date: Tue Apr  2 09:31:30 PDT 2019
ELAPSED: 6
{"hzn":{"agreementid":"1da0c92c6c7ef1e137b174b741ed1ab49032343ef25008990399adb41d4f69ca","arch":"arm","cpus":1,"device_id":"test-arm-1","exchange_url":"https://alpha.edge-fabric.com/v1/","host_ips":["127.0.0.1","192.168.1.220","172.17.0.1"],"organization":"github@dcmartin.com","ram":0,"pattern":"github@dcmartin.com/yolo2msghub-beta"}}
{"date":1554221969}
{"pattern":"github@dcmartin.com/yolo2msghub-beta"}
{"cpu":true}
{"cpu":25.99}
{"hal":true}
{"wan":true}
{"config":{"date":1554221969,"log_level":"info","debug":false,"services":[{"name":"hal","url":"http://hal"},{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}],"period":30}}
{"yolo":{"image":true}}
{"yolo":{"mock":null}}
{"yolo":{"detected":[{"entity":"person","count":1}]}}
>>> MAKE -- 09:31:36 -- testing: yolo2msghub-beta; node: test-amd64-1.local; port: 8587:8587; date: Tue Apr  2 09:31:36 PDT 2019
ELAPSED: 1
{"hzn":{"agreementid":"deeb4976f5bcf517a3d2ad430d722f017b461b71a5690a936e16faed2295386d","arch":"amd64","cpus":1,"device_id":"test-amd64-1","exchange_url":"https://alpha.edge-fabric.com/v1/","host_ips":["127.0.0.1","192.168.1.187","172.17.0.1"],"organization":"github@dcmartin.com","ram":0,"pattern":"github@dcmartin.com/yolo2msghub-beta"}}
{"date":1554221970}
{"pattern":"github@dcmartin.com/yolo2msghub-beta"}
{"cpu":true}
{"cpu":0}
{"hal":true}
{"wan":true}
{"config":{"date":1554221970,"log_level":"info","debug":false,"services":[{"name":"hal","url":"http://hal"},{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}],"period":30}}
{"yolo":{"image":false}}
{"yolo":{"mock":null}}
{"yolo":{"detected":null}}
>>> MAKE -- 09:31:37 -- testing: yolo2msghub-beta; node: nano-1.local; port: 8587:8587; date: Tue Apr  2 09:31:37 PDT 2019
ELAPSED: 3
{"hzn":{"agreementid":"0b73a5727ece8c73d74013e08891825697cc37ed7a0fb90d83dff2770f72c42d","arch":"arm64","cpus":1,"device_id":"nano-1","exchange_url":"https://alpha.edge-fabric.com/v1/","host_ips":["127.0.0.1","192.168.1.206","192.168.55.1","172.17.0.1"],"organization":"github@dcmartin.com","ram":0,"pattern":"github@dcmartin.com/yolo2msghub-beta"}}
{"date":1554221992}
{"pattern":"github@dcmartin.com/yolo2msghub-beta"}
{"cpu":true}
{"cpu":11.19}
{"hal":true}
{"wan":true}
{"config":{"date":1554221993,"log_level":"info","debug":false,"services":[{"name":"hal","url":"http://hal"},{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}],"period":30}}
{"yolo":{"image":true}}
{"yolo":{"mock":null}}
{"yolo":{"detected":[{"entity":"person","count":1}]}}
>>> MAKE -- 09:31:40 -- tested: yolo2msghub-beta; nodes: test-arm-1.local test-amd64-1.local nano-1.local; date: Tue Apr  2 09:31:40 PDT 2019
```

# 4. `make` nodes targets

+ `nodes`
+ `nodes-list`
+ `nodes-test`
+ `nodes-undo`
+ `nodes-clean`
+ `nodes-purge`

## 4.1 `make nodes`
This target registers the development nodes listed in the `TEST_TMP_MACHINES` file with the current working directory pattern (e.g. `motion2mqtt/` directory with `pattern.json` file).  This target can be run repeatedly to assess registration status.  For example, in the following output only `test-cpu-6` was registered with the pattern; all other nodes were already registered.

## 4.2 `make nodes-list`
Prior to registration with any pattern (or after successful `nodes-undo` or `nodes-clean`):

## 4.3 `make nodes-test`
This output is created using the following filter for the `jq` command (see `TEST_NODE_FILTER` file); this file may contain multiple lines with comments denoted by a `#` as the first character.  Only the first non-commented line is utilized; others may be alternatives.

```
# service versions agreement pattern
.test.hzn=.hzn,.test.date=.date,.test.pattern=.hzn.pattern,.test.cpu=.cpu?!=null,.test.cpu=.cpu.percent,.test.hal=.hal?!=null,.test.wan=.wan?!=null,.test.config=.config,.test.yolo.image=(.yolo2msghub.yolo.image?!=null),.test.yolo.mock=(.yolo2msghub.yolo.mock),.test.yolo.detected=(.yolo2msghub.yolo.detected)
```

## 4.4 `make nodes-undo`

```
>>> MAKE -- 09:36:36 -- unregistering nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:36:36 -- unregistering test-arm-1.local 
>>> MAKE -- 09:36:36 -- unregistering test-amd64-1.local 
>>> MAKE -- 09:36:37 -- unregistering nano-1.local 
```

## 4.5 `make nodes-clean`

Performs both a `nodes-undo` as well as removes all running docker images and prunes all containers from the nodes.

```
>>> MAKE -- 09:16:01 -- unregistering nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:16:01 -- unregistering test-arm-1.local 
>>> MAKE -- 09:16:02 -- unregistering test-amd64-1.local 
>>> MAKE -- 09:16:03 -- unregistering nano-1.local 
>>> MAKE -- 09:16:03 -- cleaning nodes: test-arm-1.local test-amd64-1.local nano-1.local
>>> MAKE -- 09:16:03 -- cleaning test-arm-1.local 
>>> MAKE -- 09:16:04 -- cleaning test-amd64-1.local 
>>> MAKE -- 09:16:04 -- cleaning nano-1.local 
```

## 4.6 `make nodes-purge`

Performs `nodes-clean` and then purges `bluehorizon`, `horizon`, and `horizon-cli` packages from node.
