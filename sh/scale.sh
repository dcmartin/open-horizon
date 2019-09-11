#!/bin/bash

source ${0%/*}/log-tools.sh

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

# batch size && timeout
if [ ! -z "${1:-}" ]; then start=${1}; shift; else start=0; fi
if [ ! -z "${1:-}" ]; then batch=${1}; shift; else batch=25; fi
if [ ! -z "${1:-}" ]; then timeout=${1}; shift; else timeout=3.0; fi
hzn.log.debug "batch size: ${batch}; timeout: ${timeout}"

# MACHINES
if [ -s ./ALLNODES ]; then
  MACHINES=$(egrep -v '^#' ./ALLNODES)
elif [ -s "devices.csv" ]; then
  hzn.log.debug "creating ./ALLNODES from from devices.csv"
  MACHINES=$(tail +2 devices.csv | awk -F, '{ print $4 }' | sort -n | tee ./ALLNODES)
  hzn.log.debug "created ./ALLNODES; size: " $(wc -l ./ALLNODES)
else
  hzn.log.error "no ./ALLNODES file; create it or download CSV from cloud and save as ./devices.csv"
  exit 1
fi
MACHINES_ARRAY=(${MACHINES})
MACHINES_COUNT=${#MACHINES_ARRAY[@]}
hzn.log.debug "${MACHINES_COUNT} machines total"
if [ ${MACHINES_COUNT:-0} -le  0 ]; then
  hzn.log.error "No machines"
  exit 1
fi

i=1; qty=$((start+batch)); while true; do
    # make NODES
    rm -f NODES
    egrep -v '^#' ./ALLNODES | head -${qty} > ./NODES
    machines=$(wc -l ./NODES | awk '{ print $1 }')
    hzn.log.info "iteration: ${i}; machines: ${machines}"
    # do it
    ${0%/*}/nodestest.sh
    # iterate
    if [ ${machines} -lt ${qty} ]; then break; fi
    qty=$((qty+batch))
    i=$((i+1))
done
