#!/bin/bash

###
### THIS SCRIPT PROVIDES AUTOMATED NODE LISTING
## ARGS: 
## 1. machine to inspect; default none; error
## 2. output file; default: /dev/stdout
## 3. timeout; default: 10
## 4. number of errors; default: 1
###
### REQUIRES: utilization of ssh and hzn CLI on test devices
###
### CONSUMES THE FOLLOWING ENVIRONMENT VARIABLES:
###
###

source ${0%/*}/node-tools.sh

## ENVIRONMENT
export HZNSETUP_ORG_ID="${HZN_ORG_ID:-}"
export HZNSETUP_EXCHANGE_APIKEY="${HZN_EXCHANGE_APIKEY:-}"
export HZNSETUP_EXCHANGE_URL="${HZN_EXCHANGE_URL:-https://alpha.edge-fabric.com/v1/}"

if [ -z "${HZNSETUP_ORG_ID}" ] || [ -z "${HZNSETUP_EXCHANGE_URL}" ] || [ -z "${HZNSETUP_EXCHANGE_APIKEY}" ]; then
  hzn.log.error "environment invalid; exiting"
  exit 1
fi

###
### MAIN
###

## arguments
machine=${1}
if [ -z "${machine:-}" ]; then 
  hzn.log.error "no machine specified; exiting"
  exit 1
fi
out=${2:-/dev/stdout}
timeout=${3:-10}
errors=${4:-1}

## alive?
nodeip=$(node_ip ${machine})
if [ ! -z "${nodeip:-}" ]; then
  hzn.log.debug "machine: ${machine}; alive"
  if [ $(node_alive ${nodeip} ${timeout}) = 'true' ]; then
    hzn.log.debug "machine: ${machine}; alive"
    MACHINE='{"machine":{"name":"'${machine}'","ipaddr":"'${nodeip}'","alive": true}}'
    if [ $(node_is_debian root@${nodeip}) != true ]; then
      hzn.log.debug "machine: ${machine}; nodeip; ${nodeip}; non-debian"
      MACHINE='{"machine":{"name":"'${machine}'","error":"non-debian"}}'
    else
      # get Docker version
      DOCKER=$(node_docker_status ${nodeip})
      # get Horizon version
      HZN=$(node_horizon_status ${nodeip})
      # get node status
      NODE=$(node_list ${nodeip})
      if [ -z "${NODE}" ]; then
	hzn.log.debug "machine: ${machine} [${nodeip}] is not a node"
	NODE='{"node":{"name":null,"exchange":null,"pattern":null,"state":null}}'
      else
	NODE=$(echo "${NODE}" | jq -c '{"node":{"name":.name,"exchange":.configuration.exchange_api,"pattern":.pattern,"state":.configstate.state}}')
      fi
      # get node workloads
      WORKLOADS=$(node_workloads ${machine})
      # get node services urls
      SERVICES_URLS=$(node_services_urls ${machine})
      # get node errors
      ERRORS=$(node_errors ${machine} ${errors})
      # get node Docker containers
      CONTAINERS=$(node_containers ${machine})
    fi
  else
    hzn.log.debug "machine: ${machine}; no response in ${timeout} seconds"
    MACHINE='{"machine":{"name":"'${machine}'","ipaddr":"'${nodeip}'","alive": false}}'
  fi
else
  hzn.log.error "not found ${machine}"
  MACHINE='{"machine":{"name":"'${machine}'","error":"not found","alive": false}}'
fi
## process into whole
output='['"${MACHINE:-[]}"','"${DOCKER:-[]}"','"${HZN:-[]}"','"${NODE:-[]}"','"${WORKLOADS:-[]}"','"${SERVICES_URLS:-[]}"','"${ERRORS:-[]}"','"${CONTAINERS:-[]}"']'
echo "${output}" | jq -c 'map({(.|to_entries[].key|tostring):.|to_entries[].value})|add' >> ${out}
hzn.log.debug "machine: ${machine}; finished"
