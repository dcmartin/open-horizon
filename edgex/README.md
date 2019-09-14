# &#128679;`edgex` - EdgeX Foundry & Open Horizon

# Introduction
This directory contains information and tools to utilize the [EdgeX Foundry](https://docs.edgexfoundry.org/index.html) software in conjunction with Open Horizon.

## Registry
EdgeX Foundry uses the open source Consul project as its registry service. All EdgeX Foundry microservices are expected to register with the Consul registry as they come up. Going to Consul’s dashboard UI enables you to see which services are up. Find the Consul UI at [http://[host]:8500/ui](http://localhost:8500/ui).

## Services
Below is a list of the EdgeX Foundry microservices, their ports, and “ping” URLs.

Microservice|Container|Name|Port|URL
:-------|-------:|-------:|-------:|-------:
Core Command |command |edgex-core-command |48082 |[http://[host]:48082/api/v1/ping](http://localhost:48082/api/v1/ping)
Core Data |data |edgex-core-data |48080 |[http://[host]:48080/api/v1/ping](http://localhost:48080/api/v1/ping)
Core Metadata |metadata |edgex-core-metadata |48081 |[http://[host]:48081/api/v1/ping](http://localhost:48081/api/v1/ping)
Export Client |export-client |edgex-export-client |48071 |[http://[host]:48071/api/v1/ping](http://localhost:48071/api/v1/ping)
Export Distribution |export-distro |edgex-export-distro |48070 |[http://[host]:48070/api/v1/ping](http://localhost:48070/api/v1/ping)
Rules Engine |rulesengine |edgex-support-rulesengine |48075 |[http://[host]:48075/api/v1/ping](http://localhost:48075/api/v1/ping)
Support Logging |logging |edgex-support-logging |48061 |[http://[host]:48061/api/v1/ping](http://localhost:48061/api/v1/ping)
Support Notifications |notifications |edgex-support-notifications |48060 |[http://[host]:48060/api/v1/ping](http://localhost:48060/api/v1/ping)
Support Scheduler |scheduler |edgex-support-scheduler |48085 |[http://[host]:48085/api/v1/ping](http://localhost:48085/api/v1/ping)
Virtual Device Service |device-virtual |edgex-device-virtual |49990 |[http://[host]:49990/api/v1/ping](http://localhost:49990/api/v1/ping)


<hr>

# Part &#10122;  -  Installing EdgeX
The following steps install the components using Docker containers composed via a YAML specification.  For more information please refer to the [Getting Started](https://docs.edgexfoundry.org/Ch-GettingStartedUsers.html) documentation.

The following software is required:

+ Docker - the community-edition version 18, or better
+ UNIX - either the LINUX operating system or another supported platform, e.g. macOS


## Step 0
Use the "standard" Docker installation script (see below) or appropriate mechanism for your platform; see [docker.com](https://www.docker.com/get-started) for more information.

```
wget get.docker.com | sudo bash -s
```

Install `docker-compose`:

```
sudo apt install -qq -y docker-compose
```

Add your userid to the `docker` group, for example:

```
sudo addgroup $(whoami) docker
```

Login again to have the additional group privileges applied, for example:

```
login $(whoami)
```

## Step 1
Create a new directory, for example `~/edgex`, and download an appropriate `docker-compose.yml` file from the [Github repository](https://github.com/edgexfoundry/developer-scripts/tree/master/compose-files).  Save the appropriate YAML file and link to `docker-compose.yml`, for example:

```
mkdir ~/edgex
cd ~/edgex
wget https://raw.githubusercontent.com/edgexfoundry/developer-scripts/master/compose-files/docker-compose-redis-edinburgh-no-secty-1.0.0.yml
ln -s docker-compose-redis-edinburgh-no-secty-1.0.0.yml docker-compose.yml
```

## Step 2
Pull all EdgeX containers, for example:

```
docker-compose pull
```

Example output:

```
Pulling volume         ... done
Pulling redis          ... done
Pulling portainer      ... done
Pulling consul         ... done
Pulling config-seed    ... done
Pulling logging        ... done
Pulling notifications  ... done
Pulling system         ... done
Pulling data           ... done
Pulling export-client  ... done
Pulling rulesengine    ... done
Pulling export-distro  ... done
Pulling metadata       ... done
Pulling scheduler      ... done
Pulling command        ... done
Pulling device-virtual ... done
Pulling ui             ... done
```

Check the downloaded images, for example:

```
docker images
```

Example output:

```
REPOSITORY                                     TAG                 IMAGE ID            CREATED             SIZE
redis                                          5.0.5-alpine        d975eaec5f68        6 days ago          51.1MB
edgexfoundry/docker-export-client-go           1.0.0               829bc19eb4ae        3 weeks ago         18.3MB
edgexfoundry/docker-core-config-seed-go        1.0.0               12be31a66648        3 weeks ago         14.6MB
edgexfoundry/docker-device-virtual-go          1.0.0               5c055f49199e        3 weeks ago         19.9MB
edgexfoundry/docker-edgex-ui-go                1.0.0               56476a1927b5        3 weeks ago         20MB
edgexfoundry/docker-support-scheduler-go       1.0.0               629dd05a4be6        3 weeks ago         18.5MB
edgexfoundry/docker-support-notifications-go   1.0.0               115250dae6c7        3 weeks ago         19.2MB
edgexfoundry/docker-support-logging-go         1.0.0               98d128489e9b        3 weeks ago         17.3MB
edgexfoundry/docker-core-command-go            1.0.0               1c47da10247c        3 weeks ago         15.4MB
edgexfoundry/docker-core-metadata-go           1.0.0               6daa5257ac30        3 weeks ago         19.1MB
edgexfoundry/docker-core-data-go               1.0.0               5eef06ea7aae        3 weeks ago         26.3MB
edgexfoundry/docker-export-distro-go           1.0.0               2492a06952e8        3 weeks ago         24.3MB
portainer/portainer                            latest              da2759008147        6 weeks ago         75.4MB
edgexfoundry/docker-edgex-volume               1.0.0               30e02a657c86        6 weeks ago         69.9MB
consul                                         1.3.1               6c4586f655e0        2 months ago        107MB
edgexfoundry/docker-support-rulesengine        1.0.0               c73a0a2241cc        4 months ago        149MB
edgexfoundry/docker-sys-mgmt-agent-go          1.0.0               2be211af547f        8 months ago        9.88MB
```

## Step 3
Start all EdgeX containers (in _detached_ mode), for example:

```
docker-compose up -d
```

Example output:

```
Creating network "edgex_default" with the default driver
Creating network "edgex_edgex-network" with driver "bridge"
Creating volume "edgex_db-data" with default driver
Creating volume "edgex_consul-data" with default driver
Creating volume "edgex_portainer_data" with default driver
Creating volume "edgex_consul-config" with default driver
Creating volume "edgex_log-data" with default driver
Creating edgex-files ... done
Creating edgex_portainer_1 ... done
Creating edgex-redis       ... done
Creating edgex-core-consul ... done
Creating edgex-config-seed ... done
Creating edgex-support-logging ... done
Creating edgex-core-data             ... done
Creating edgex-support-notifications ... done
Creating edgex-sys-mgmt-agent        ... done
Creating edgex-core-metadata         ... done
Creating edgex-export-client         ... done
Creating edgex-support-scheduler     ... done
Creating edgex-core-command          ... done
Creating edgex-export-distro         ... done
Creating edgex-support-rulesengine   ... done
Creating edgex-device-virtual        ... done
Creating edgex-ui-go                 ... done
```

## Step 4
List all composed Docker containers to confirm that all the containers have been downloaded and started. (Note: initialization or seed containers, like config-seed, will have exited as there job is just to initialize the associated service and then exit.)

```
docker-compose ps
```

Example output:

```
           Name                          Command               State                                                   Ports                                                
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
edgex-config-seed             /edgex/cmd/config-seed/con ...   Exit 0                                                                                                       
edgex-core-command            /core-command --registry - ...   Up       0.0.0.0:48082->48082/tcp                                                                            
edgex-core-consul             docker-entrypoint.sh agent ...   Up       8300/tcp, 8301/tcp, 8301/udp, 8302/tcp, 8302/udp, 0.0.0.0:8400->8400/tcp, 0.0.0.0:8500->8500/tcp,   
                                                                        0.0.0.0:8600->8600/tcp, 8600/udp                                                                    
edgex-core-data               /core-data --registry --pr ...   Up       0.0.0.0:48080->48080/tcp, 0.0.0.0:5563->5563/tcp                                                    
edgex-core-metadata           /core-metadata --registry  ...   Up       0.0.0.0:48081->48081/tcp, 48082/tcp                                                                 
edgex-device-virtual          /device-virtual --profile= ...   Up       0.0.0.0:49990->49990/tcp                                                                            
edgex-export-client           /export-client --registry  ...   Up       0.0.0.0:48071->48071/tcp                                                                            
edgex-export-distro           /export-distro --registry  ...   Up       0.0.0.0:48070->48070/tcp, 0.0.0.0:5566->5566/tcp                                                    
edgex-files                   /bin/sh -c /usr/bin/tail - ...   Up                                                                                                           
edgex-redis                   docker-entrypoint.sh redis ...   Up       0.0.0.0:6379->6379/tcp                                                                              
edgex-support-logging         /support-logging --registr ...   Up       0.0.0.0:48061->48061/tcp                                                                            
edgex-support-notifications   /support-notifications --r ...   Up       0.0.0.0:48060->48060/tcp                                                                            
edgex-support-rulesengine     /bin/sh -c java -jar -Djav ...   Up       0.0.0.0:48075->48075/tcp                                                                            
edgex-support-scheduler       /support-scheduler --regis ...   Up       0.0.0.0:48085->48085/tcp                                                                            
edgex-sys-mgmt-agent          /sys-mgmt-agent --profile= ...   Up       0.0.0.0:48090->48090/tcp                                                                            
edgex-ui-go                   ./edgex-ui-server                Up       0.0.0.0:4000->4000/tcp                                                                              
edgex_portainer_1             /portainer -H unix:///var/ ...   Exit 1                      
```

## Step 5
To get a list of the Docker Compose names of the containers (as they are in the docker-compose.yml file):

```
docker-compose config --services
```

Example output:

```
volume
redis
portainer
consul
config-seed
logging
notifications
system
data
export-client
rulesengine
export-distro
metadata
scheduler
command
device-virtual
ui
```

## Step 6
Check for "ping" from each service port, for example:

```
machine="localhost"
ports="48060 48061 48070 48071 48075 48080 48081 48082 48085 49990"
for port in ${ports}; do pong=$(curl -sSL http://${machine}:${port}/api/v1/ping) && echo "port: $port; reply: ${pong}"; done
```

Example output:

```
port: 48060; reply: pong
port: 48061; reply: pong
port: 48070; reply: pong
port: 48071; reply: pong
port: 48075; reply: pong
port: 48080; reply: pong
port: 48081; reply: pong
port: 48082; reply: pong
port: 48085; reply: pong
port: 49990; reply: 1.0.0
```


## Step 7
To stop all EdgeX containers:

```
docker-compose stop
```

## Step 8
To start all EdgeX containers:

```
docker-compose start
```

## Step 9
To stop and deconstruct (remove) all the EdgeX Foundry containers, call on “docker-compose down”. Docker shows the containers being stopped and then removed. Note, you may wish to stop (versus stop and remove) all the EdgeX Containers. See more details in the Advanced EdgeX Foundry User Command below.

```
docker-compose down
```

## &#9989; DONE
You have now setup the EdgeX Foundry components as Docker containers and verified success.

<hr>

# Part &#10123; - `edgex` for Open Horizon
The EdgeX Foundry components can be defined as an Open Horizon service the includes all the requisite Docker container images.  

## Introduction
There are attributes defined in the Docker composition (e.g. [docker-compose.yml](docker-compose.ytml)) that have no direct equivalents, notably:

+ `name` - components are named in three ways: a _label_,  `hostname`, and  `container_name`
+ `depends_on` - dependents  specified using _label_
+ `networks` - networks specified using _label_ as well as aliases
+ `volumes` - volumes, by _label_, to attach to the file-system

### Names
Fortunately, the names for each EdgeX component is the same for `hostname` and `container_name`; the Open Horizon equivalent are the deployment _key_ values from the `service.json`. The _key_ value in **example one** is `edgex-files`

### Volumes
The volumes from the host file-system to be connected to the the container's file-system; the Open Horizon equivalent is the `bind` directive; environment variables, processed by the `hzn` command-line program, are utilized as proxies:

+ `EDGEX_DB_DATA` - full pathname to the directory; default: `"/var/run/edgex/data"`
+ `EDGEX_LOG_DATA` - full pathname to the directory; default: `=/var/run/edgex/logs"`
+ `EDGEX_CONSUL_DATA` - full pathname to the directory; default: `=/var/run/edgex/consul/data"`
+ `EDGEX_CONSUL_CONFIG` - full pathname to the directory; default: `=/var/run/edgex/consul/config"`

These directories must be created and have permissions set to `777` on the device prior to the registering for the `edgex` _pattern_.

**EXAMPLE 1**

```
  "deployment": {
    "services": {
      "edgex-files": {
        "binds": [
          "${EDGEX_DB_DATA}:/data",
          "${EDGEX_LOG_DATA}:/logs",
          "${EDGEX_CONSUL_CONFIG}:/consul/config",
          "${EDGEX_CONSUL_DATA}:/consul/data"
        ],
        "image": "edgexfoundry/docker-edgex-volume:1.0.0",
        "privileged": true
      },
```

### Dependencies
The `depends_on` attribute has no direct equivalent. The `requiredServices` dependency may be appropriate, presuming the `singleton` issue is rectified, but it is not apparent how the dependencies are meant to effect service instantiation.

### Networks
The `networks` attribute has no direct equivalent. The `requiredServices` point-to-point VPN's may be appropriate; fortunately, EdgeX components share a single network with no overlapping ports. The host network has to be configured appropriately; this may require host networking for the Docker containers *which is currently not supported*.

View the [service.json](service.json) file for details.

# Installation
The following software is required:

+ Open Horizon - the `hzn` command-line program
+ `envsubst` - from the GNU `gettext` package (or edit files manually)

These steps create:

+ the `edgex`  _service_ that includes all the EdgeX Foundry component containers
+ the `edgex`  _pattern_ that deploys the _service_ in conjunction with environmental variables


## Step 1
Pull all images for the Docker containers in the composition, for example:

```
docker-compose pull
```

## Step 2
Specify the environment variables for the location of the directories to be mounted/bound into the containers:

```
export EDGEX_DB_DATA=/var/run/edgex/data
export EDGEX_LOG_DATA=/var/run/edgex/logs
export EDGEX_CONSUL_DATA=/var/run/edgex/consul/data
export EDGEX_CONSUL_CONFIG=/var/run/edgex/consul/config
```

## Step 3
Specify the environment variables for the Open Horizon organization, exchange and API key.
```
export HZN_ORG_ID="$(whoami)"
export HZN_EXCHANGE_APIKEY="<token>"
export HZN_EXCHANGE_URL="http://exchange.dcmartin.com:3090/v1/"
```

## Step 4
Create code signing public and private keys, for example:

```
hzn key create $(whoami) $(hostname) -d .
mv -f *.pem ${HZN_ORG_ID}.pem
mv -f *.key ${HZN_ORG_ID}.key
export PRIVATE_KEY_FILE=${HZN_ORG_ID}.key
export PUBLIC_KEY_FILE=${HZN_ORG_ID}.pem
```

## Step 5
Publish the Open Horizon service to the exchange using the `-I` flag to make use of the existing container identifiers and images, for example:

```
hzn exchange service publish -I -O -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f service.json -o ${HZN_ORG_ID} -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}
```

Sample output:

```
Signing service...
Creating com.github.dcmartin.open-horizon.edgex_0.0.1_amd64 in the exchange...
Storing dcmartin.pem with the service in the exchange...
If you haven't already, push your docker images to the registry:
  docker push edgexfoundry/docker-export-client-go:1.0.0
  docker push edgexfoundry/docker-support-notifications-go:1.0.0
  docker push edgexfoundry/docker-support-rulesengine:1.0.0
  docker push edgexfoundry/docker-core-config-seed-go:1.0.
  docker push redis:5.0.5-alpine
  docker push edgexfoundry/docker-support-scheduler-go:1.0.0
  docker push edgexfoundry/docker-sys-mgmt-agent-go:1.0.0
  docker push consul:1.3.1
  docker push edgexfoundry/docker-core-data-go:1.0.0
  docker push edgexfoundry/docker-core-metadata-go:1.0.0
  docker push edgexfoundry/docker-export-client-go:1.0.0
  docker push edgexfoundry/docker-edgex-volume:1.0.0
  docker push edgexfoundry/docker-support-logging-go:1.0.0
  docker push edgexfoundry/docker-core-command-go:1.0.0
```

## Step 6
Create a `userinput.json` file that contains the necessary environment variables, for example:

```
{
  "global": [],
  "services": [
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.edgex",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": {
        "EXPORT_DISTRO_CLIENT_HOST": "export-client",
        "EXPORT_DISTRO_DATA_HOST": "edgex-core-data",
        "EXPORT_DISTRO_CONSUL_HOST": "edgex-config-seed",
        "EXPORT_DISTRO_MQTTS_CERT_FILE": "none",
        "EXPORT_DISTRO_MQTTS_KEY_FILE": "none",
        "LOGTO": "",
        "LOG_LEVEL": "info"
      }
    }
  ]
}
```

## Step 7
Create a `pattern.json` file that contains the `edgex` service as published, for example:

```
{
  "label": "edgex",
  "description": "edgex foundry as a pattern",
  "services": [
    { "serviceUrl": "com.github.dcmartin.open-horizon.edgex", "serviceOrgid": "${HZN_ORG_ID}", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1" } ] }
  ]
}

```

## Step 8
Publish the _pattern_, for example:

```
hzn exchange pattern publish -o "${HZN_ORG_ID}" -u "${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -f pattern.json -p "edgex" -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}
```

Sample output:

```
Creating edgex in the exchange...
Storing dcmartin.pem with the pattern in the exchange...
```

## Step 9
Create the directories required by the EdgeX components, using the environment variables specified for `EDGEX`:

```
EDGEX_LOG_DATA
EDGEX_DB_DATA
EDGEX_CONSUL_DATA
EDGEX_CONSUL_CONFIG
```

For example:

```
DIRS=$(env | egrep EDGEX | awk -F= '{ print $1 }')
for DIR in ${DIRS}; do eval dir=\$${DIR}; echo "${dir}"; sudo mkdir -p ${dir}; sudo chmod 777 ${dir}; done
```

## Step 10
Start the Open Horizon container on the localhost, for example:

```
horizon-container start
```

## Step 11
Create a `input.json` file from the `userinput.json` file substituting the environment variables, for example:

```
envsubst < userinput.json > input.json
```

## Step 12
Create a password for the device, for example:

```
export PASSWORD="whocares"
```

## Step 13
Register the device for the `edgex` pattern, for example:

```
hzn register "${HZN_ORG_ID}" "edgex" -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -f input.json -n "edgex-$(hostname):${PASSWORD:-whocares}"
```

## Step 14
Wait for device to reach agreement and beginning running containers; inspect the current status by using the `hzn` and `docker` commands, for example:

```
hzn node list
```

```
docker ps
```

## Step 15
Check for "ping" from each service port, for example:

```
machine="localhost"
ports="48060 48061 48070 48071 48075 48080 48081 48082 48085 49990"
for port in ${ports}; do pong=$(curl -sSL http://${machine}:${port}/api/v1/ping) && echo "port: $port; reply: ${pong}"; done
```

## &#9989; DONE
When the device becomes a `"configured"` node, running all containers, enquire through the Consul UI, for example:

```
open http://localhost:8500/ui
```
 
# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

# Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: ../startup/userinput.json
[service-json]: ../startup/service.json
[build-json]: ../startup/build.json
[dockerfile]: ../startup/Dockerfile


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
