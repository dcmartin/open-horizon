#!/bin/bash

##
## TURN UBUNTU VM INTO DEVELOPMENT / TEST HOST
##
# Provide IP address or hostname on command line; script will:
# 1) install Docker
# 2) install Open Horizon
# 3) register for the current directory pattern (requires horizon/ directory)
#

source ${0%/*}/node-tools.sh

## ENVIRONMENT
export HZNSETUP_ORG_ID=${HZNSETUP_ORG_ID:-${HZN_ORG_ID:-}}
export HZNSETUP_EXCHANGE_APIKEY=${HZNSETUP_EXCHANGE_APIKEY:-${HZN_EXCHANGE_APIKEY:-}}
export HZNSETUP_EXCHANGE_URL=${HZNSETUP_EXCHANGE_URL:-${HZN_EXCHANGE_URL:-https://alpha.edge-fabric.com/v1/}}
export HZNSETUP_FSS_CSSURL=${HZNSETUP_FSS_CSSURL:-${HZN_FSS_CSSURL:-https://alpha.edge-fabric.com/css/}}

if [ -z "${HZNSETUP_ORG_ID}" ] || [ -z "${HZNSETUP_EXCHANGE_URL}" ] || [ -z "${HZNSETUP_EXCHANGE_APIKEY}" ]; then
  hzn.log.error "environment invalid; exiting"
  exit 1
fi

## PATTERN
HZNSETUP_PATTERN_DIR=${HZNSETUP_PATTERN_DIR:-horizon}
HZNSETUP_PATTERN_FILE=${HZNSETUP_PATTERN_FILE:-${HZNSETUP_PATTERN_DIR}/pattern.json}
HZNSETUP_USERINPUT_FILE=${HZNSETUP_USERINPUT_FILE:-${HZNSETUP_PATTERN_DIR}/userinput.json}
# test if pattern and userinput JSON files exist
if [ -s ${HZNSETUP_PATTERN_FILE} ]; then
  HZNSETUP_PATTERN_NAME=$(jq -r '.label' ${HZNSETUP_PATTERN_FILE})
  if [ ! -s ${HZNSETUP_USERINPUT_FILE} ]; then
    hzn.log.error "cannot locate userinput JSON file: ${HZNSETUP_USERINPUT_FILE}; run make ${HZNSETUP_PATTERN_DIR}; exiting"
    exit 1
  fi
else
  hzn.log.error "cannot locate pattern JSON file: ${HZNSETUP_PATTERN_FILE}; run make ${HZNSETUP_PATTERN_DIR}; exiting"
  exit 1
fi

## ARGUMENTS

# set force
if [ "${1}" = '-f' ]; then 
  hzn.log.debug "setting force"
  force=true
  shift
fi

# get wait
if [ "${1}" = '-w' ]; then
  shift
  if [ -z "${1:-}" ]; then hzn.log.fatal "-w requires a numeric argument"; exit 1; fi
  wait=${1:-0}
  shift
  hzn.log.debug "setting wait: ${wait}"
fi

# get machine
machine="${1:-}"
# get output
out="${2:-/dev/stdout}"
if [ -z "${machine:-}" ]; then
  hzn.log.error "Usage: ${0##*/} [-f] <machine> [ <output_json> ]"
  exit 1
fi

# wait for starting to stagger bulk
sleep ${wait:-0}

###
### MAIN
###

## REMOTE ACCOUNT, USER & KEY
HZN_HOST_USER="${HZN_HOST_USER:-root}"
HZN_HOST_PUBKEY=${HZN_HOST_PUBKEY:-$(cat ~/.ssh/id_rsa.pub)}
STARTUP_HOST_USER=${STARTUP_HOST_USER:-${USER:-$(whoami)}}

# booleans
alive=false
rebooting=null
configured=null

# start BAD array of bad nodes
BAD='['

# test this node
if [ $(node_alive ${machine}) != true ]; then
  hzn.log.debug "machine: ${machine}; offline"
  alive=false
  BAD="${BAD}"'{"machine":"'${machine}'","error":"offline"}'
else
  hzn.log.debug "machine: ${machine}; online"
  # alive
  alive=true
  # determine account for access
  account=$(node_access ${machine} ${STARTUP_HOST_USER})
  # test account
  if [ "${account:-}" = 'null' ]; then
    hzn.log.debug "machine: ${machine}; no access"
    BAD="${BAD}"'{"machine":"'${machine}'","error":"ssh"}'
  elif [ ${account} = 'root' ] || [ ${force:-false} = true ] && [ $(node_adduser "${machine}" ${STARTUP_HOST_USER} "${HZN_HOST_PUBKEY}" ${force:-}) != true ]; then
    hzn.log.debug "machine: ${machine}; account: ${HZN_HOST_USER}; user: ${STARTUP_HOST_USER}; failed to add user"
    BAD="${BAD}"'{"machine":"'${machine}'","error":"adduser"}'
  elif [ $(node_reboot ${machine}) = true ]; then
    hzn.log.debug "machine: ${machine}; rebooting"
    rebooting=true
    BAD="${BAD}"'{"machine":"'${machine}'","error":"rebooting"}'
  elif [ $(node_docker_install ${machine}) != true ]; then
    hzn.log.debug "machine: ${machine}; no docker installation"
    BAD="${BAD}"'{"machine":"'${machine}'","error":"docker"}'
  elif [ $(node_install ${machine} ${HZNSETUP_EXCHANGE_URL} ${HZNSETUP_FSS_CSSURL}) != true ]; then
    hzn.log.debug "machine: ${machine}; no bluehorizon installation"
    BAD="${BAD}"'{"machine":"'${machine}'","error":"bluehorizon"}'
  else
    # report on upgrades
    upgrades=$(node_upgrades ${machine})
    # get current node state
    state=$(node_state ${machine})
    hzn.log.debug "machine: ${machine}; state: ${state}"
    # test state
    if [ "${force:-false}" = true ] || [ "${state:-}" != "configured" ]; then
      # loop until good (or 'failed')
      while [ "${state:-}" != 'configured' ] && [ "${state:-}" != 'false' ]; do
	# keep trying
	state=$(node_update ${machine} ${HZNSETUP_EXCHANGE_URL} ${HZNSETUP_ORG_ID} ${HZNSETUP_EXCHANGE_APIKEY} ${HZNSETUP_ORG_ID}/${HZNSETUP_PATTERN_NAME} ${HZNSETUP_USERINPUT_FILE})
	hzn.log.debug "machine: ${machine}; state: ${state}"
      done
      if [ -z "${state:-}" ]; then
	hzn.log.warn "machine: ${machine}; FAILURE: no state"
	BAD="${BAD}"'{"machine":"'${machine}'","error":"unknown", "result":null}'
	state='unknown'
      elif [ ${state} = 'configured' ]; then
	hzn.log.debug "machine: ${machine}; SUCCESS: ${state}"
	configured=true
      else
	hzn.log.debug "machine: ${machine}; FAILURE: ${result}"
	BAD="${BAD}"'{"machine":"'${machine}'","error":"node_update", "result":"'"${state:-null}"'"}'
      fi
    else
      # it's configured
      configured=true
    fi
  fi
fi

# finish BAD
BAD="${BAD}"']'

echo '{"machine":"'${machine}'","alive":'${alive}',"configured":'${configured}',"rebooting":'${rebooting}',"result":'"${result:-null}"',"bad":'"${BAD:-null}"'}' | jq -c '.' >> ${out}
