#!/bin/bash

source ${0%/*}/node-tools.sh

# functions
proceed()
{
  echo -n "${*} [y/n](y): "
  read proceed
  if [ "${proceed:-}" != 'n' ]; then
    echo 'true'
  else
    echo 'false'
  fi
}

## ENVIRONMENT
export HZNSETUP_ORG_ID="${HZN_ORG_ID:-}"
export HZNSETUP_EXCHANGE_APIKEY="${HZN_EXCHANGE_APIKEY:-}"
export HZNSETUP_EXCHANGE_URL="${HZN_EXCHANGE_URL:-https://alpha.edge-fabric.com/v1/}"

if [ -z "${HZNSETUP_ORG_ID}" ] || [ -z "${HZNSETUP_EXCHANGE_URL}" ] || [ -z "${HZNSETUP_EXCHANGE_APIKEY}" ]; then
  hzn.log.error "environment invalid; exiting"
  exit 1
fi

## ARGUMENTS
if [ ! -z "${1:-}" ]; then
  if [ "${1}" = '-f' ]; then 
    force=true
    if [ ! -z "${2}" ]; then machine="${2}"; fi
    out="${3:-}"
  else
    if [ ! -z "${1}" ]; then machine="${1}"; fi
    out="${2:-}"
  fi
fi
if [ -z "${machine:-}" ] || [ -z "${out}" ]; then
  hzn.log.error "Usage: ${0##*/} [-f] <machine> <out>"
  exit 1
fi

###
### MAIN
###

# collect bad
BAD_NODE_NAMES=$(jq -j '.|select(.bad|length>0).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${BAD_NODE_NAMES}" = '""' ]; then BAD_NODE_NAMES=null; else BAD_NODE_NAMES='['"${BAD_NODE_NAMES}"']'; fi
BAD_NODE_COUNT=$(echo "${BAD_NODE_NAMES}" | jq '.|length')

# collect offline
OFFLINE_NODE_NAMES=$(jq -j '.|select(.bad[].error=="offline").machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${OFFLINE_NODE_NAMES}" = '""' ]; then OFFLINE_NODE_NAMES=null; else OFFLINE_NODE_NAMES='['"${OFFLINE_NODE_NAMES}"']'; fi
OFFLINE_NODE_COUNT=$(echo "${OFFLINE_NODE_NAMES}" | jq '.|length')

# collect non-responding
NORESPONSE_NODE_NAMES=$(jq -j '.|select(.responding!=true and .alive==true).machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${NORESPONSE_NODE_NAMES}" = '""' ]; then NORESPONSE_NODE_NAMES=null; else NORESPONSE_NODE_NAMES='['"${NORESPONSE_NODE_NAMES}"']'; fi
NORESPONSE_NODE_COUNT=$(echo "${NORESPONSE_NODE_NAMES}" | jq '.|length')

# collect missing
MISSING_NODE_NAMES=$(jq -j '.|select(.bad[].error=="missing").machine," "' ${out} | sed 's/^[ ]*//' | sed 's/ \([^ ]\)/","\1/g' | sed 's/ //g' | sed 's/\(.*\)/"\1"/')
if [ "${MISSING_NODE_NAMES}" = '""' ]; then MISSING_NODE_NAMES=null; else MISSING_NODE_NAMES='['"${MISSING_NODE_NAMES}"']'; fi
MISSING_NODE_COUNT=$(echo "${MISSING_NODE_NAMES}" | jq '.|length')

##
## INSPECT BAD
##

if [ ${BAD_NODE_COUNT:-0} -gt 0 ] && [ $(proceed "Complete; ${BAD_NODE_COUNT} bad; proceed?") = true ]; then 
  i=0; for B in $(echo "${BAD_NODE_NAMES}" | jq -r '.[]'); do

    # check if alive
    if [ $(node_alive ${B}) != true ]; then
      hzn.log.debug "node dead: ${B}"
      i=$((i+1))
      continue
    fi

    # get node status
    hzn.log.debug "executing ${0%/*}/list-machine.sh ${B}"
    NODELIST=$(${0%/*}/list-machine.sh ${B})

    # get state
    NODE_STATE=$(echo "${NODELIST}" | jq -r '.state')
    hzn.log.debug "node state for ${B}: ${NODE_STATE}"

    # count pertinent details
    AGREEMENT_COUNT=$(echo "${NODELIST}" | jq '.agreements|length')
    hzn.log.debug "agreements: ${AGREEMENT_COUNT}"
    SERVICE_COUNT=$(echo "${NODELIST}" | jq '.agreements|length')
    hzn.log.debug "services: ${SERVICE_COUNT}"
    CONTAINER_COUNT=$(echo "${NODELIST}" | jq '.containers|length')
    hzn.log.debug "containers: ${CONTAINER_COUNT}"

    purge=false
    case ${NODE_STATE} in
      null|unconfigured)
	if [ $(proceed "${i}/${BAD_NODE_COUNT} - ${B} is unconfigured; register?") = true ]; then
          hzn.log.debug "registering ${B}"
	  ./sh/mkmachine.sh ${B} &> /dev/null &
	  registering=true
	fi
	;;
      configured)
	if [ ${AGREEMENT_COUNT} -eq 0 ]; then
	  if [ $(proceed "${i}/${BAD_NODE_COUNT} - ${B} is ${NODE_STATE} w/ no agreement; services: ${SERVICE_COUNT}; containers: ${CONTAINER_COUNT}; purge?") = true ]; then
            purge=true
          fi
        else
          SERVICE_COUNT_SPEC=$(${0%/*}/lspatterns.sh | jq '.patterns[]|select(.id=="'${HZN_ORG_ID}/${pattern}'").services|length')
          if [ ${SERVICE_COUNT:-0} -lt ${SERVICE_COUNT_SPEC:-0} ]; then
	    if [ $(proceed "${i}/${BAD_NODE_COUNT} - ${B} is ${NODE_STATE} w/ services: ${SERVICE_COUNT} LESS THAN ${SERVICE_COUNT_SPEC}; purge?") = true ]; then
              purge=true
	    fi
          elif [ ${CONTAINER_COUNT:-0} -lt ${SERVICE_COUNT_SPEC:-0}  ]; then
	    if [ $(proceed "${i}/${BAD_NODE_COUNT} - ${B} is ${NODE_STATE} w/ containers: ${CONTAINER_COUNT} LESS THAN ${SERVICE_COUNT_SPEC}; purge?") = true ]; then
              purge=true
	    fi
	  fi
        fi
	;;
      configuring|unconfiguring)
	if [ $(proceed "${i}/${BAD_NODE_COUNT} - ${B} is ${NODE_STATE}; purge?") = true ]; then
	  purge=true
	fi
	;;
      *)
        hzn.log.debug "${i}/${BAD_NODE_COUNT} - unknown state: ${NODE_STATE}"
	;;
    esac
    if [ "${purge:-false}" = true ]; then
      hzn.log.debug "purging ${B}"
      node_purge ${B}
    fi
    i=$((i+1))
  done
fi

