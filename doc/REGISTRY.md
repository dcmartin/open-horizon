# `REGISTRY.md` - Setup IBM Cloud Container Registry

## A. Create container registry

Visit the IBM Cloud Catalog and select the [containers][ibm-catalog-containers] component.

![icr.io.png](icr.io.png?raw=true "icr.io")


[ibm-catalog]: https://cloud.ibm.com/catalog
[ibm-catalog-containers]: https://cloud.ibm.com/catalog?category=containers

Select the Container Registry and click on the `Create` button in the lower-right corner of the page.

## B. Install software

Install the IBM Cloud command-line-interface (CLI); the following command downloads a number of software packages; **administrator access is required and password may be requested**:

```
curl -sSL ibm.biz/idt-installer | bash
```

**Packages installed**:

+ Homebrew (Mac only)
+ Git
+ Docker
+ Helm
+ kubectl
+ curl
+ IBM Cloud Developer Tools plug-in
+ IBM Cloud Functions plug-in
+ IBM Cloud Container Registry plug-in
+ IBM Cloud Kubernetes Service plug-in
+ sdk-gen plug-in

## C. Configure registry

A global registry is available, which has no region that is included in its name (`registry.bluemix.net`). Only IBM-provided public images are hosted in this registry. To manage your own images such as by setting up namespaces or tagging and pushing images to a registry, use a local regional registry:

**NOTE**: To utilize the global registry, set the region: `ibmcloud cr region-set global`

### Step 0

Select from the following based on IBM Cloud location and copy-and-paste to set environment variables used in subsequent commands.

+ US-South

```
export REGION=us-south
export REGISTRY=registry.ng.bluemix.net
export CLOUD=api.ng.bluemix.net
```

+ UK-South

```
export REGION=uk-south
export REGISTRY=registry.eu-gb.bluemix.net 
export CLOUD=api.eu-gb.bluemix.net
```

+ EU-Central

```
export REGION=eu-central
export REGISTRY=registry.eu-de.bluemix.net
export CLOUD=api.eu-de.bluemix.net
```

+ AP-South

```
export REGION=ap-south 
export REGISTRY=registry.au-syd.bluemix.net 
export CLOUD=api.au-syd.bluemix.net
```

### Step 1
Log into the IBM Cloud for your region:

```
ibmcloud login -a https://${CLOUD}
```

### Step 2
Set the region for the registry:

```
ibmcloud cr region-set ${REGION}
```

### Step 3
Verify registry API endpoint:

```
ibmcloud cr api
```

Example output, which may vary depending on your region; for more information see [here][regions-local].

```
ibmcloud cr api
                           
Registry API endpoint   https://us.icr.io/api   

OK
```

[regions-local]: https://cloud.ibm.com/docs/services/Registry?topic=registry-registry_overview#registry_regions_local


### Step 4
Create a _namespace_ for the registry to store container images; default is the current `USER` environment variable:

```
export NAMESPACE="${USER}"
ibmcloud cr namespace-add "${NAMESPACE}"
```

Confirm creation of namespace; run the following command to list all:

```
ibmcloud cr namespace-list
```

Upgrade the container registry to _standard_ plan:

```
ibmcloud cr plan-upgrade
```

### Step 5
Create an API key with read/write access to the registry; create file and set environment variable:

```
export PRIVATE_TOKEN=$(ibmcloud cr token-add --quiet --description "${NAMESPACE} private read-write token" --non-expiring --readwrite)
```

### Step 6
Create token for anonymous, read-only, access; create file and set environment variable:

```
export PUBLIC_TOKEN=$(ibmcloud cr token-add --quiet --description "${NAMESPACE} public read-only token" --non-expiring)
```

### Step 7
Record the registry configuration in a JSON file for subsequent use in section (D).

```
echo \
  '{"namespace":"'${NAMESPACE}'"'\
  	',"region":"'${REGION}'"'\
  	',"registry":"'${REGISTRY}'"'\
  	',"cloud":"'${CLOUD}'"'\
  	',"private":"'${PRIVATE_TOKEN}'"'\
  	',"public":"'${PUBLIC_TOKEN}'"}' \
  > registry.json
```

## D. Configure CI/CD
Copy the registry configuration JSON generated in section (C) to the repository root directory and reset environment variables.  For example, presuming `registry.json` is in the user's home directory and `~/gitdir/open-horizon` is the repository top-level directory:

```
cd ~/gitdir/open-horizon
cp ~/registry.json .
export DOCKER_LOGIN=token
export DOCKER_PASSWORD=$(jq -r '.private' registry.json)
export DOCKER_REGISTRY=$(jq -r '.registry' registry.json)
export DOCKER_NAMESPACE=$(jq -r '.namespace' registry.json)
export DOCKER_TOKEN=(jq -r '.public' registry.json)
```

Verify credentials using `docker` command:

```
docker login -u ${DOCKER_LOGIN} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
```

Example output; may vary depending on region (**note**: do not utilize a _credentials store_):

```
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /Users/dcmartin/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

[credentials-store]: https://docs.docker.com/engine/reference/commandline/login/#credentials-store


## E. Build using IBM Cloud
This section is TBD.

```
ibmcloud cr login
```

```
ibmcloud cr build [--no-cache] [--pull] [--quiet | -q] [--build-arg KEY=VALUE ...] [--file FILE | -f FILE] --tag TAG DIRECTORY
```
