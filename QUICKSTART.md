# `QUICKSTART.md`


## Installation on `macOS`
To install using Apple Mac computers the Xcode command-line tools will need to be installed; it is highly recommended to utilize [brew](http://brew.sh) to install both those tools as well as the following: `git`, `jq`, `...`.

The `apt` command is not applicable; utilize the `brew` commmand as appropriate.

## Installation on LINUX `ubuntu18.04`
This set of instructions works on the following configuration of [VirtualBox](http://virtualbox.org) running under `macOS`:

+ Ubuntu 18.04
+ 4 vCPU (`amd64` _only_)
+ 4 GB RAM
+ 32 GB storage

Watch a time-compressed [video](https://youtu.be/_BdAa7jT5VY).

## Step 1 - Setup & clone
Setup the account for automated `sudo` privileges, install the `git` program, and clone the repository.

```
echo "${USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_${USER}-nopasswd
```
```
sudo apt install -qq -y git 
git clone http://github.com/dcmartin/open-horizon
```

## Step 2 - Update & install
Run the update and upgrade processes for the system and then install the required tools; when complete, add the account to the `docker` group and reboot the machine.

```
sudo apt update -qq -y
sudo apt upgrade -qq -y
sudo apt install -qq -y build-essential net-tools jq curl apache2-utils gnupg2 pass docker-compose
```
```
sudo addgroup ${USER} docker
sudo reboot
```

## Step 3 - Create exchange
Initialize the random number generator, change to the directory and use `make` to build the _exchange_.

```
touch ~/.rnd
```
```
cd open-horizon
make exchange
curl localhost:3090/v1/admin/version
```

## Step 4 - Install `hzn` CLI
Run the provided shell script to download `horizon`, `bluehorizon`, and `horizon-cli` packages and install.

```
sudo ./sh/get.horizon.sh
export HZN_EXCHANGE_URL=$(hzn node list | jq -r '.configuration.exchange_api')
```

## Step 5 - Test exchange 
Run provided script to list users in the exchange; please change the `HZN_EXCHANGE_APIKEY` as appropriate:

```
export HZN_USER_ID=${USER} HZN_ORG_ID=${USER} HZN_EXCHANGE_APIKEY=whocares
./sh/lsusers.sh
```

Example output:

```
{
  "exchange": "http://localhost:3090/v1/",
  "org": "dcmartin",
  "users": [
    {
      "password": "********",
      "admin": true,
      "email": "dcmartin@dcmartin",
      "lastUpdated": "2020-05-07T17:22:36.807Z[UTC]",
      "updatedBy": "root/root",
      "id": "dcmartin/dcmartin"
    }
  ]
}
```

## Step 6 - `docker login`
Login to Docker (aka `hub.docker.com`); the `DOCKER_NAMESPACE` defaults to `USER` environment variable; 
override by setting the environment variable or creating a persistent file of the same name.

```
docker login
```

## Step 7 - Build, push, publish `hznmonitor`
As an example and to provide a means to browse the _exchange_, build  the `hznmonitor` _service_ and start it.  The `hznmonitor` _service_ is built **from** the `apache-ubuntu` _container_, which is built from the `base-ubuntu` _container; all three containers will be built, pushed to Docker hub, and published in the _exchange_.

The _service_ requires the following files to be created (n.b. all _string_ values  must be enclosed in quotation marks \[\"\]):

+ `KAFKA_APIKEY` - API key for an IBM _event streams_ Kafka server (_n.b. this will be removed in future versions_)
+ `MQTT_HOST` - TCP/IPv4 address or FQDN for a **MQTT** broker (see [`mqtt`](services/mqtt/README.md))
+ `MQTT_USERNAME` - broker credentials
+ `MQTT_PASSWORD` - broker credentials


```
make hznmonitor
```
Browse the exchange and the services published using a Web browser on port 3094, e.g. `http://127.0.0.1:3094/`


## Step 7 - Build, push, publish _all_ services
Build, push, and publish all the services; there are also sample _patterns_ which may be published from within the `services/` subdirectory.  For more information see [`SERVICE.md`](docs/SERVICE.md)

```
make services
```
