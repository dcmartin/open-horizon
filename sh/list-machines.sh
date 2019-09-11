#!/bin/bash

source ${0%/*}/node-tools.sh
source ${0%/*}/doittoit.sh

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
if [ "${1:-}" = '-f' ]; then
  force="-f"
  shift
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
  MACHINES=$(jq -r '.machine.ipaddr' ${out})
elif [ -s ./NODES ]; then
  MACHINES=$(egrep -v '^#' NODES)
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
TOTAL=$(doittoit ${force:-} ${0%/*}/list-machine.sh ${out} ${timeout} ${MACHINES})
hzn.log.debug "received ${TOTAL} responses"

# collect alive
ALIVE=$(jq -c '.|select(.machine.alive?==true)' ${out} | jq -j '.machine.name," "' | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${ALIVE}" = '""' ]; then ALIVE=null; else ALIVE='['"${OFFLINE}"']'; fi
ALIVE_COUNT=$(echo "${ALIVE}" | jq '.|length')

# collect offline
OFFLINE=$(jq -c '.|select(.machine.alive?==false)' ${out} | jq -j '.machine.name," "' | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${OFFLINE}" = '""' ]; then OFFLINE=null; else OFFLINE='['"${OFFLINE}"']'; fi
OFFLINE_COUNT=$(echo "${OFFLINE}" | jq '.|length')

# collect nohorizon
NOHZN=$(jq -c '.|select(.machine.alive?==true)|select(.horizon.cli?=="notfound")' ${out} | jq -j '.machine.name," "' | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${NOHZN}" = '""' ]; then NOHZN=null; else NOHZN='['"${NOHZN}"']'; fi
NOHZN_COUNT=$(echo "${NOHZN}" | jq '.|length')

# collect configured
CONFIGURED=$(jq -j '.|select(.node.state?=="configured").machine.name," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${CONFIGURED}" = '""' ]; then CONFIGURED=null; else CONFIGURED='['"${CONFIGURED}"']'; fi
CONFIGURED_COUNT=$(echo "${CONFIGURED}" | jq '.|length')

# collect configuring
CONFIGURING=$(jq -j '.|select(.node.state?=="configuring").machine.name," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${CONFIGURING}" = '""' ]; then CONFIGURING=null; else CONFIGURING='['"${CONFIGURING}"']'; fi
CONFIGURING_COUNT=$(echo "${CONFIGURING}" | jq '.|length')

# collect unconfiguring
UNCONFIGURING=$(jq -j '.|select(.node.state?=="unconfiguring").machine.name," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${UNCONFIGURING}" = '""' ]; then UNCONFIGURING=null; else UNCONFIGURING='['"${UNCONFIGURING}"']'; fi
UNCONFIGURING_COUNT=$(echo "${UNCONFIGURING}" | jq '.|length')

# collect unconfigured
UNCONFIGURED=$(jq -j '.|select(.node.state?=="unconfigured").machine.name," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${UNCONFIGURED}" = '""' ]; then UNCONFIGURED=null; else UNCONFIGURED='['"${UNCONFIGURED}"']'; fi
UNCONFIGURED_COUNT=$(echo "${UNCONFIGURED}" | jq '.|length')

# collect zero containers
NOCONTAINERS=$(jq -c '.|select(.node.state?=="configured")' ${out} | jq -j '.|select(.containers|length==0).machine.name," "' | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${NOCONTAINERS}" = '""' ]; then NOCONTAINERS=null; else NOCONTAINERS='['"${NOCONTAINERS}"']'; fi
NOCONTAINERS_COUNT=$(echo "${NOCONTAINERS}" | jq '.|length')

# generate JSON
OUTPUT=$(echo '{"output":"'${out}'","total":'${TOTAL}',"offline":'"${OFFLINE}"',"nohzn":'"${NOHZN}"',"configured":'${CONFIGURED_COUNT}',"configuring":'${CONFIGURING}',"unconfiguring":'${UNCONFIGURING}',"unconfigured":'${UNCONFIGURED}',"zero_containers":'${NOCONTAINERS}'}' | jq -c '.')

## OUTPUT
echo "${OUTPUT}" | jq -c '.start="'${start:-}'"|.finish="'$(date -u +%FT%TZ)'"|.elapsed='$(($(date +%s)-when))
# all done
exit
