# `QUICKSTART.md`
This set of instructions works on the following:

+ Ubuntu 18.04
+ 4 vCPU (`amd64` _only_)
+ 4 GB RAM
+ 32 GB storage

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
Initialize the random number genertor, change to the directory and use `make` to build the _exchange_.

```
touch ~/.rnd
```
```
cd open-horizon
make exchange
```

## Step 4 - Install horizon
Run the provided shell script to download `horizon`, `bluehorizon`, and `horizon-cli` packages and install.

```
sudo ./sh/get.horizon.sh
```

## Step 5 - `docker login`
Login to Docker (aka `hub.docker.com`); the `DOCKER_NAMESPACE` defaults to `USER` environment variable; 
override by setting the environment variable or creating a persistent file of the same name.

```
docker login
```

## Step 6 - Build, push, publish (_minimum_)
Build the base and service containers for `hznmonitor` and start the service.  Browse the exchange and the services published using a Web browser on port 3094, e.g. `http://127.0.0.1:3094/`

```
make hznmonitor
```

## Step 7 - Build, push, publish (_everything_)
Build, push, and publish all the services

```
make services
```
