#!/bin/bash

# source
source ${0%/*}/log-tools.sh
source ${0%/*}/doittoit.sh

## ENVIRONMENT
export HZNSETUP_ORG_ID="${HZN_ORG_ID:-}"
export HZNSETUP_EXCHANGE_APIKEY="${HZN_EXCHANGE_APIKEY:-}"
export HZNSETUP_EXCHANGE_URL="${HZN_EXCHANGE_URL:-https://alpha.edge-fabric.com/v1/}"

if [ -z "${HZNSETUP_ORG_ID}" ] || [ -z "${HZNSETUP_EXCHANGE_URL}" ] || [ -z "${HZNSETUP_EXCHANGE_APIKEY}" ]; then
  hzn.log.error "environment invalid; exiting"
  exit 1
fi

## FUNCTIONS
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

###
### MAIN
###

# force?

if [ "${1:-}" = '-f' ]; then
  hzn.log.info "force mode on"
  force="-f"
  shift
fi

# get wait
if [ "${1}" = '-w' ]; then
  shift
  if [ -z "${1-}" ]; then hzn.log.fatal "-w requires numeric argument"; exit 1; fi
  wait="-w ${1}"
  shift
  hzn.log.debug "setting wait: ${wait}"
fi

if [ ! -z "${1:-}" ] && [ -s "${1}" ]; then
  out="${1}"
  shift
else
  out=${0##*/} && out=test.${out%.*}.$$.json
  touch ${out}
fi
timeout=${1:-10}

# test for existing output
if [ ! -z "${out:-}" ] && [ -s "${out}" ]; then
  MACHINES=$(jq -r '.machine' ${out})
elif [ -s ./NODES ]; then
  MACHINES=$(egrep -v '^#' NODES)
elif [ -s "devices.csv" ]; then
  hzn.log.debug "creating ./NODES from from devices.csv; creating ./NODES; size: " $(wc -l ./NODES)
  MACHINES=$(tail +2 devices.csv | awk -F, '{ print $4 }' | sort -n | tee ./NODES)
else
  hzn.log.error "$0 $$ -- no NODES file; create it or download CSV from cloud and save as ./devices.csv"
  exit 1
fi
MACHINE_ARRAY=(${MACHINES})
MACHINE_COUNT=${#MACHINE_ARRAY[@]}

hzn.log.debug "$0 $$ -- ${MACHINE_COUNT} machines specified"

## start
start=$(date -u +%FT%TZ)
when=$(date +%s)

# doittoit
TOTAL=$(doittoit ${force:-} ${0%/*}/make-machine.sh ${wait:-} ${out} ${timeout} ${MACHINES})
hzn.log.debug "received ${TOTAL} responses"

# investigate results
ALIVE=$(jq -r '.|select(.alive?==true)?|.machine' ${out}) && AA=(${ALIVE}) && ALIVE_COUNT=${#AA[@]}
hzn.log.debug "total: ${MACHINE_COUNT}; total: ${TOTAL}; alive: ${#AA[@]}"

# collect offline
OFFLINE_NODE_NAMES=$(jq -j '.|select(.bad[].error=="offline").machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${OFFLINE_NODE_NAMES}" = '""' ]; then OFFLINE_NODE_NAMES=null; else OFFLINE_NODE_NAMES='['"${OFFLINE_NODE_NAMES}"']'; fi
OFFLINE_NODE_COUNT=$(echo "${OFFLINE_NODE_NAMES}" | jq '.|length')

# collect failed
FAILED_NODE_NAMES=$(jq -j '.|select(.result.state=="failed").machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${FAILED_NODE_NAMES}" = '""' ]; then FAILED_NODE_NAMES=null; else FAILED_NODE_NAMES='['"${FAILED_NODE_NAMES}"']'; fi
FAILED_NODE_COUNT=$(echo "${FAILED_NODE_NAMES}" | jq '.|length')

# collect rebooting
REBOOTING_NODE_NAMES=$(jq -j '.|select(.rebooting==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${REBOOTING_NODE_NAMES}" = '""' ]; then REBOOTING_NODE_NAMES=null; else REBOOTING_NODE_NAMES='['"${REBOOTING_NODE_NAMES}"']'; fi
REBOOTING_NODE_COUNT=$(echo "${REBOOTING_NODE_NAMES}" | jq '.|length')

# collect configured
CONFIGURED_NODE_NAMES=$(jq -j '.|select(.configured==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${CONFIGURED_NODE_NAMES}" = '""' ]; then CONFIGURED_NODE_NAMES=null; else CONFIGURED_NODE_NAMES='['"${CONFIGURED_NODE_NAMES}"']'; fi
CONFIGURED_NODE_COUNT=$(echo "${CONFIGURED_NODE_NAMES}" | jq '.|length')

# collect unconfigured
UNCONFIGURED_NODE_NAMES=$(jq -j '.|select(.configured!=true)|select(.bad[].error==null)|.machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${UNCONFIGURED_NODE_NAMES}" = '""' ]; then UNCONFIGURED_NODE_NAMES=null; else UNCONFIGURED_NODE_NAMES='['"${UNCONFIGURED_NODE_NAMES}"']'; fi
UNCONFIGURED_NODE_COUNT=$(echo "${UNCONFIGURED_NODE_NAMES}" | jq '.|length')

# collect bad
BAD_NODE_NAMES=$(jq -j '.|select(.bad|length>0).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${BAD_NODE_NAMES}" = '""' ]; then BAD_NODE_NAMES=null; else BAD_NODE_NAMES='['"${BAD_NODE_NAMES}"']'; fi
BAD_NODE_COUNT=$(echo "${BAD_NODE_NAMES}" | jq '.|length')

# generate JSON
OUTPUT=$(echo '{"output":"'${out}'","total":'${TOTAL}',"offline":'${OFFLINE_NODE_COUNT}',"alive":'${ALIVE_COUNT}',"rebooting":'${REBOOTING_NODE_COUNT}',"configured":'${CONFIGURED_NODE_COUNT}',"unconfigured":'"${UNCONFIGURED_NODE_NAMES}"',"failed":'"${FAILED_NODE_NAMES}"',"bad":'"${BAD_NODE_NAMES}"'}' | jq -c '.')

## OUTPUT
echo "${OUTPUT}" | jq -c '.start="'${start}'"|.finish="'$(date -u +%FT%TZ)'"|.elapsed='$(($(date +%s)-when))
# all done
exit

