# `SETUP.md` - Setting up Open Horizon

These instructions are for Debian LINUX, notably Ubuntu and Raspbian.  Instructions for _macOS_ are TBD.


## Step 1 - Setup _exchange_

Change directory to the top-level of this cloned repository and setup the Open Horizion _exchange_; for example:

```
cd ~/GIT/open-horizon
echo ${USER} > HZN_ORG_ID && export HZN_ORG_ID=$(cat HZN_ORG_ID)
echo ${USER} > HZN_USER_ID && export HZN_USER_ID=$(cat HZN_USER_ID)
echo http://exchange:3090/v1/ > HZN_EXCHANGE_URL && export HZN_EXCHANGE_URL=$(cat HZN_EXCHANGE_URL)
echo whocares > HZN_EXCHANGE_APIKEY && export HZN_EXCHANGE_APIKEY=$(cat HZN_EXCHANGE_APIKEY)
cd exchange/ && ln -s ../HZN* .
# edit config.json ..
make up
make prime
```

## Step 2 - Setup _agent_
Change directory to top-level of this cloned repository and run the provided script to download the Debian packages for your LINUX _flavor_ and _distribution_, e.g. `ubuntu:bionic` or `raspbian:buster`. This script will also work under _macOS_; for example:

```
cd ~/GIT/open-horizon && sudo ./sh/get.horizon.sh
```

## Step 2 - Configure _exchange_

```
export HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL:-http://exchange:3090/v1/}
export HZN_FSS_CSSURL=${HZN_FSS_CSSURL:-http://exchange:9443/css/}
sudo sed -i -e "s/^HZN_EXCHANGE_URL=.*/HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL}" /etc/default/horizon
sudo sed -i -e "s/^HZN_FSS_CSSURL=.*/HZN_FSS_CSSURL=${HZN_FSS_CSSURL}" /etc/default/horizon
sudo systemctl restart horizon
```

## Step 3 - Test

```
export HZN_ORG_ID=${HZN_ORG_ID:-${USER}}
export HZN_USER_ID=${HZN_USER_ID:-${USER}}
export HZN_EXCHANGE_APIKEY=${HZN_EXCHANGE_APIKEY:-whocares}
export HZN_EXCHANGE_USER_AUTH=${HZN_ORG_ID}/${HZN_USER_ID}:${HZN_EXCHANGE_APIKEY}
hzn exchange service list
```

## Step 4 - Build

```
cd ~/GIT/open-horizon/services
ln -s ../HZN* .
make build
```

## Step 5 - Push

```
cd ~/GIT/open-horizon/services
make push
```

## Step 6 - Publish

```
cd ~/GIT/open-horizon/services
make publish
```

## Step 7 - Test

```
hzn exchange service list
```

```
cd ~/GIT/open-horizon/services
./sh/lsservices.sh
```

## Step 8 - All architectures _(only macOS)_

```
cd ~/GIT/open-horizon/services
make service-build service-push service-publish
```
