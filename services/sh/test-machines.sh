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

## FUNCTIONS

# in the array?
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
  MACHINES=$(jq -r '.machine' ${out})
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
TOTAL=$(doittoit ${force:-} ${0%/*}/test-machine.sh ${out} ${timeout} ${MACHINES})
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

# collect responding
RESPONDING_NODE_NAMES=$(jq -j '.|select(.responding!=false)|select(.alive==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${RESPONDING_NODE_NAMES}" = '""' ]; then RESPONDING_NODE_NAMES=null; else RESPONDING_NODE_NAMES='['"${RESPONDING_NODE_NAMES}"']'; fi
RESPONDING_NODE_COUNT=$(echo "${RESPONDING_NODE_NAMES}" | jq '.|length')

# collect non-responding
NORESPONSE_NODE_NAMES=$(jq -j '.|select(.responding==false)|select(.alive==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${NORESPONSE_NODE_NAMES}" = '""' ]; then NORESPONSE_NODE_NAMES=null; else NORESPONSE_NODE_NAMES='['"${NORESPONSE_NODE_NAMES}"']'; fi
NORESPONSE_NODE_COUNT=$(echo "${NORESPONSE_NODE_NAMES}" | jq '.|length')

# collect bad-response
BADRESPONSE_NODE_NAMES=$(jq -j '.|select(.responding==null)|select(.alive==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${BADRESPONSE_NODE_NAMES}" = '""' ]; then BADRESPONSE_NODE_NAMES=null; else BADRESPONSE_NODE_NAMES='['"${BADRESPONSE_NODE_NAMES}"']'; fi
BADRESPONSE_NODE_COUNT=$(echo "${BADRESPONSE_NODE_NAMES}" | jq '.|length')

# collect missing
MISSING_NODE_NAMES=$(jq -j '.|select(.bad[].error=="missing").name," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${MISSING_NODE_NAMES}" = '""' ]; then MISSING_NODE_NAMES=null; else MISSING_NODE_NAMES='['"${MISSING_NODE_NAMES}"']'; fi
MISSING_NODE_COUNT=$(echo "${MISSING_NODE_NAMES}" | jq '.|length')

# generate JSON
OUTPUT=$(echo '{"output":"'${out}'","timeout":'${timeout}',"total":'${TOTAL}',"alive":'${#AA[@]}',"responding":'${RESPONDING_NODE_COUNT}',"noresponse":'${NORESPONSE_NODE_NAMES}',"badresponse":'"${BADRESPONSE_NODE_NAMES}"',"missing":'"${MISSING_NODE_NAMES}"',"offline":'${OFFLINE_NODE_NAMES}'}' | jq -c '.')

## OUTPUT
echo "${OUTPUT}" | jq -c '.start="'${start:-}'"|.finish="'$(date -u +%FT%TZ)'"|.elapsed='$(($(date +%s)-when))
# all done
exit
