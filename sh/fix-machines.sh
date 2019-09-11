#!/bin/bash

# source
source ${0%/*}/log-tools.sh
source ${0%/*}/doittoit.sh

contains()
{
  local result=1
  local arg="${1}"
  shift
  local arr="${*}"

  for a in ${arr}; do
    if [ "${a}" == "${arg}" ]; then
      result=0
      break
    fi
  done
  echo ${result}
}

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

# force?
if [ ! -z "${*}" ]; then
  if [ "${1:-}" = '-f' ]; then
    force="-f"
    shift
  else
    echo "Usage: ${0##*/} [-f]" &> /dev/stderr
    exit 1
  fi
fi

# test for devices as CSV file
if [ ! -s ./NODES ]; then
  hzn.log.error "no ./NODES file; create it or download CSV from cloud and save as ./devices.csv"
  exit 1
else
  MACHINES=$(egrep -v '^#' NODES | sort -n)
fi

# count machines
MACHINE_ARRAY=(${MACHINES})
MACHINE_COUNT=${#MACHINE_ARRAY[@]}

hzn.log.debug "found ${MACHINE_COUNT} machines"

# seconds
out=${1:-}

if [ -z "${out}" ]; then
  hzn.log.error "Usage: ${0##*/} <json>"
fi

#
for machine in ${MACHINES}; do
  hzn.log.debug "fixing machine ${machine}; saving to ${out}"
  ${0%/*}/fix-machine.sh ${force:-} ${machine} ${out} 2> /dev/stderr &
done

count=0
echo -n "waiting for ${MACHINE_COUNT} nodes:" &> /dev/stderr
while [ ${count} -lt ${MACHINE_COUNT} ]; do
  sleep 5
  count=$(wc -l ${out} | awk '{ print $1 }')
  pct=$(echo "${count} / ${MACHINE_COUNT} * 100" | bc -l)
  pct=${pct%.*}
  if [ "${pct}" = "${old:-}" ]; then
    echo -n '.' &> /dev/stderr
  else
    echo -n " ${pct}%" &> /dev/stderr
    old=${pct}
  fi
done
echo " completed" &> /dev/stderr

TOTAL=$(jq -c '.' "${out}" | wc | awk '{ print $1 }')
hzn.log.debug "received ${TOTAL} responses"

# investigate results
ALIVE=$(jq -r '.|select(.alive==true).machine' ${out}) && AA=(${ALIVE})

# collect bad
BAD_NODE_NAMES=$(jq -j '.|select(.bad|length>0).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${BAD_NODE_NAMES}" = '""' ]; then BAD_NODE_NAMES=null; else BAD_NODE_NAMES='['"${BAD_NODE_NAMES}"']'; fi
BAD_NODE_COUNT=$(echo "${BAD_NODE_NAMES}" | jq '.|length')

# collect offline
OFFLINE_NODE_NAMES=$(jq -j '.|select(.bad[].error=="offline").machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${OFFLINE_NODE_NAMES}" = '""' ]; then OFFLINE_NODE_NAMES=null; else OFFLINE_NODE_NAMES='['"${OFFLINE_NODE_NAMES}"']'; fi
OFFLINE_NODE_COUNT=$(echo "${OFFLINE_NODE_NAMES}" | jq '.|length')

# collect rebooting
REBOOTING_NODE_NAMES=$(jq -j '.|select(.rebooting==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${REBOOTING_NODE_NAMES}" = '""' ]; then REBOOTING_NODE_NAMES=null; else REBOOTING_NODE_NAMES='['"${REBOOTING_NODE_NAMES}"']'; fi
REBOOTING_NODE_COUNT=$(echo "${REBOOTING_NODE_NAMES}" | jq '.|length')

# collect registering
REGISTERING_NODE_NAMES=$(jq -j '.|select(.registering==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${REGISTERING_NODE_NAMES}" = '""' ]; then REGISTERING_NODE_NAMES=null; else REGISTERING_NODE_NAMES='['"${REGISTERING_NODE_NAMES}"']'; fi
REGISTERING_NODE_COUNT=$(echo "${REGISTERING_NODE_NAMES}" | jq '.|length')

# collect configured
CONFIGURED_NODE_NAMES=$(jq -j '.|select(.configured==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${CONFIGURED_NODE_NAMES}" = '""' ]; then CONFIGURED_NODE_NAMES=null; else CONFIGURED_NODE_NAMES='['"${CONFIGURED_NODE_NAMES}"']'; fi
CONFIGURED_NODE_COUNT=$(echo "${CONFIGURED_NODE_NAMES}" | jq '.|length')

# generate JSON
OUTPUT=$(echo '{"output":"'${out}'","total":'${TOTAL}',"alive":'${#AA[@]}',"rebooting":'${REBOOTING_NODE_COUNT}',"registering":'${REGISTERING_NODE_COUNT}',"configured":'${CONFIGURED_NODE_COUNT}',"offline":'"${OFFLINE_NODE_NAMES}"'}' | jq -c '.')

# output
echo "${OUTPUT}" | jq -c '.'

# all done
exit

