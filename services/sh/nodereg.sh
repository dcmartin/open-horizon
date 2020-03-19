#!/bin/bash

## source
source ${0%/*}/node-tools.sh

###
### MAIN
###

## check environment
if [ -z "${HZN_ORG_ID}" ]; then hzn.log.error "set environment variable HZN_ORG_ID"; exit 1; fi
if [ -z "${HZN_EXCHANGE_APIKEY}" ]; then hzn.log.error "set environment variable HZN_EXCHANGE_APIKEY"; exit 1; fi
if [ -z "${HZN_EXCHANGE_URL}" ]; then hzn.log.error "set environment variable HZN_EXCHANGE_URL"; exit 1; fi

## show environment
hzn.log.trace "environment HZN_ORG_ID: ${HZN_ORG_ID}"
hzn.log.trace "environment HZN_EXCHANGE_APIKEY: ${HZN_EXCHANGE_APIKEY}"
hzn.log.trace "environment HZN_EXCHANGE_URL: ${HZN_EXCHANGE_URL}"

## process arguments
machine=${1:-}
if [ -z "${SERVICE_NAME}" ]; then 
  if [ ! -z "${2}" ]; then SERVICE_NAME="${2}"; else hzn.log.error "usage: ${0##*/} <machine> <pattern> <userinput>"; exit 1; fi
fi
if [ "${SERVICE_NAME##*/}" == "${SERVICE_NAME}" ]; then
  SERVICE_NAME="${HZN_ORG_ID}/${SERVICE_NAME}"
  hzn.log.warn "missing service organization; using ${SERVICE_NAME}"
fi
if [ -z "${INPUT}" ]; then 
  if [ ! -z "${3}" ]; then INPUT="${3}"; else hzn.log.error "${0##*/} - set environment variable INPUT or provide as third argument"; exit 1; fi
fi

## record start
start=$(date -u +%FT%TZ)
when=$(date +%s)

## initial state
state='offline'
upgrades=0

# test
if [ ! -z "${machine}" ]; then
  if  [ $(node_alive ${machine}) = true ]; then
    if [ $(node_reboot ${machine}) != true ]; then
      # get upgrades; don't do it
      upgrades=$(node_upgrades ${machine})
      # get initial state
      state=$(node_update ${machine})
      # loop until good (or 'failed')
      while [ "${state:-}" != 'configured' ]; do
	hzn.log.debug "${0##*/} - machine: ${machine}; state: ${state}"
        # check for failure
	if [ "${state:-}" = 'failed' ]; then
	  hzn.log.warn "${0##*/} - machine: ${machine}; failed"
	  state='failed'
	  break
	fi
        # keep trying
	state=$(node_update ${machine})
      done
      hzn.log.debug "${0##*/} - machine: ${machine}; loop complete; state: ${state}"
    else
      hzn.log.debug "${0##*/} - machine: ${machine}; rebooting"
      state='rebooting'
    fi
  else
    hzn.log.debug "${0##*/} - machine: ${machine}; offline"
    state='offline'
  fi
else
  hzn.log.debug "${0##*/} - no machine specified"
  state='error'
fi

echo '{"machine":"'${machine:-}'","state":"'${state:-}'","start":"'${start:-}'","finish":"'$(date -u +%FT%TZ)'","elapsed":'$(($(date +%s)-when))'}'
