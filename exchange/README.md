# &#128679; `exchange` - Open Horizon _exchange_ Setup

# Introduction
This directory contains information and tools to utilize the [Open Horizon](https://github.com/open-horizon) software using Docker.

## Services
Below is a list of the Open Horizon microservices, their ports, and “ping” URLs.

Microservice|Container|Name|Port|URL
:-------|-------:|-------:|-------:|-------:
Exchange API|exchange-api|oh-exchange|8080|[http://[host]:8080/v1](http://localhost:8080/v1)

# Part &#10122;  -  Installing Open Horizon

The following software is required:

+ Docker - the community-edition version 18, or better
+ UNIX - either the LINUX operating system or another supported platform, e.g. macOS


## Step 0
Use the "standard" Docker installation script (see below) or appropriate mechanism for your platform; see [docker.com](https://www.docker.com/get-started) for more information.

```
wget get.docker.com | sudo bash -s
```

Install `htpasswd` from the `apache2-utils` package

```
sudo apt install -qq -y apache2-utils
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
Create a new directory, for example `~/openhorizon`, and download an appropriate `docker-compose.yml` file, for example:

```
mkdir ~/openhorizon
cd ~/openhorizon
git clone http://github.com/dcmartin/open-horizon .
cd exchange
```

## Step 2
Make all the pre-requisites, for example:

```
make
```

## Step 3
Start all Open Horizon containers (in _detached_ mode), for example:

```
make up
```

## Step 4
List all composed Docker containers to confirm that all the containers have been downloaded and started. (Note: initialization or seed containers, like config-seed, will have exited as there job is just to initialize the associated service and then exit.)

```
docker-compose ps
```

Example output:

```
```

## Step 5
To get a list of the Docker Compose names of the containers (as they are in the docker-compose.yml file):

```
docker-compose config --services
```

Example output:

```
```

## Step 6
Check for "ping" from each service port, for example:

```
```

Example output:

```
```


## Step 7
To stop all Open Horizon containers:

```
make stop
```

## Step 8
To start all Open Horizon containers:

```
make start
```

## Step 9
To stop and deconstruct (remove) all the Open Horizon Foundry containers, call on “docker-compose down”. Docker shows the containers being stopped and then removed. Note, you may wish to stop (versus stop and remove) all the Open Horizon Containers. See more details in the Advanced Open Horizon Foundry User Command below.

```
make down
```

## &#9989; DONE
You have now setup the Open Horizon Foundry components as Docker containers and verified success.

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
