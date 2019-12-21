# &#128260; `esstest` - simple test of edge-sync-service

## Introduction
This service exercises the [`edge-sync-service`](http://github.com/open-horizon/edge-sync-service) (ESS).  The edge sync service communicates with the cloud sync service (CSS) to send and receive data.  For this example only the local ESS and CSS are utilized.

The `esstest` service emits a JavaScript Object Notation (JSON) response when it receives a request for its status on its port (n.b. default `8080`).  That status includes the count of models available from the ESS.

## Requirements
The following software is required:

+ `hzn` - Open Horizon command-line-interface (CLI) and (optional) local agent
+ `docker` - Docker command-line-interface and service
+ `jq` - JSON query processor
+ `curl` - retrieve resources identified by universal resource locators (URL)

## How it works
The [`run.sh`](rootfs/usr/bin/run.sh) script is called when the container is launched (n.b. `CMD` instruction in [`Dockerfile`](Dockerfile)); it periodically calls the [`ess-objects-get.sh`](rootfs/usr/bin/ess-objects-get.sh) script which performs three primary actions:

1. Retrieve array of objects matching  the _objectType_ specified; e.g. `model`
2. For each object retrieve the data associated and store it in a file and send a `received` message indicating receipt
3. Generate a JSON payload array of objects received

# How to use

## Step 1
Create a new directory, `esstest`, and clone this [repository](https://github.com/open-horizon/esstest):

```
mkdir -p ~/gitdir/esstest
cd ~/gitdir/esstest
git clone https://github.com/open-horizon/esstest .
```

## Step 2
Copy the IBM Cloud Platform API key file downloaded from [IAM](https://cloud.ibm.com/iam), and set environment variables for Open Horizon organization:

```
cp ~/Downloads/apiKey.json .
export HZN_EXCHANGE_APIKEY=$(jq -r '.apiKey' apiKey.json)
export HZN_ORG_ID=<organization>
```

## Step 3
Build the docker image locally using the native (i.e. `amd64`) architecture.

```
DOCKER_NAMESPACE=<dockerhubid>
DOCKER_TAG="${DOCKER_NAMESPACE}/esstest_amd64:0.0.1"
docker build -t ${DOCKER_TAG} .
```

## Step 4
Configure as a new _service_ using the `hzn` command-line-interface (CLI) program:

```
hzn dev service new -o ${HZN_ORG_ID} -s "esstest" -V "0.0.1" -i ${DOCKER_NAMESPACE}/esstest --noImageGen
```

## Step 5
Start service (and ESS and CSS running locally); for example:

```
hzn dev service start
```

## Step 6
Check Docker logs; for example using a background process:

```
docker logs -f $(docker ps --format '{{.Names}}' | egrep esstest) &
```

The logs should indicate a `FAILED; HTTP_CODE: 404` message repeatedly, indicating no new objects are available to the node.

## Step 7
Create an object using the [`css-object-create-local.sh`](css-object-create-local.sh) script:

```
% css-object-create-local.sh
```

## Step 8
Put data into the object using the [`css-object-put-local.sh`](css-object-put-local.sh) script; for example, put the string `"Hello World"`:

```
% echo "Hello World" | css-object-put-local.sh
```

## Step 9
Check Docker logs; one _object_ of type `model` received, containing twelve (12) bytes of data (i.e. `"Hello World"`).

The logs should indicate: `SUCCESS; MODELS: [{"ID":"test","file":"/tmp/test.dat","size":12}]`

## Step 10
Change the `css-object-put-local.sh` script data to the string `"Goodbye World"`:

```
% echo "Goodbye World" | css-object-put-local.sh
```

## Step 11
Check Docker logs; one _object_ of type `model` received, containing fourteen (14) bytes of data (i.e. `"Goodbye World"`).

The logs should indicate: `SUCCESS; MODELS: [{"ID":"test","file":"/tmp/test.dat","size":14}]`

## Step 12
Repeat steps 7,8,9,10, and 11, but specify a new _objectID_ (e.g. `my_model_id`); for example:

```
% css-object-create-local.sh myModelID
% echo "This is my model data" | css-object-put-local.sh myModelID
% echo "Now I have changed my model data" | css-object-put-local.sh myModelID
```

And monitor the Docker logs for indications of `FAILED` and `SUCCESS`

## Step 13
Shutdown service

```
hzn dev service stop
```
