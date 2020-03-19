#!/bin/bash

source ${0%/*}/node-tools.sh

node_get_status()
{
  local machine="${1}"
  local json="${2}"
  local code=$(curl -sL -w '%{http_code}' --connect-timeout ${timeout} --retry-connrefused --retry 10 --retry-max-time ${maxtime} --max-time ${maxtime} "${machine}:3093" -o "${json}" 2> /dev/null)
  if [ ${code} == 200 ]; then
    if [ $(jq -c '.' ${json} &> /dev/null && echo "true" || echo "false") = false ]; then
      code=206
    fi
  fi
  echo "${code}"
}

node_test()
{
  local machine=${1}
  local json=$(mktemp)
  local code=$(node_get_status ${machine} ${json})
  local retry=0

  while [ ${retry} -lt ${maxretry:-3} ] && [ ${code} != 200 ]; do
    case ${code} in
      206)
        hzn.log.debug "machine: ${machine} status: ${code}"
        # try again
        code=$(node_get_status ${machine} ${json})
      ;;
      *)
        hzn.log.debug "machine: ${machine} status: ${code}"
        rm -f ${json}
	json=${code}
        break
      ;;
    esac
    retry=$((retry+1))
  done
  echo ${json:-${code}}
}

## ENVIRONMENT
export HZNSETUP_ORG_ID="${HZN_ORG_ID:-}"
export HZNSETUP_EXCHANGE_APIKEY="${HZN_EXCHANGE_APIKEY:-}"
export HZNSETUP_EXCHANGE_URL="${HZN_EXCHANGE_URL:-https://alpha.edge-fabric.com/v1/}"
if [ -z "${HZNSETUP_ORG_ID}" ] || [ -z "${HZNSETUP_EXCHANGE_URL}" ] || [ -z "${HZNSETUP_EXCHANGE_APIKEY}" ]; then
  hzn.log.error "environment invalid; exiting"
  exit 1
fi

## monitor host
if [ -z "${HZNMONITOR_HOST:-}" ]; then
  HZNMONITOR_HOST=$(hostname -f)
  hzn.log.warn "HZNMONITOR_HOST unspecified; using default: ${HZNMONITOR_HOST}"
fi

## arguments
if [ -z "${1:-}" ]; then
  hzn.log.error "Usage: ${0##*/} <device> [ <output-file> [ <timeout> ]]"
  exit 1
fi
# machine and outputfile
machine=${1}
out=${2:-/dev/stdout}
# seconds (integer only)
timeout=${3:-1.0}
maxtime=${4:-$(echo "${timeout} * 10" | bc)} && maxtime=${maxtime%.*}

## booleans
alive=false
responding=false
missing=null
  
## array of bad nodes
BAD='['

# test this node
if [ $(node_alive ${machine}) = true ]; then
  # machine is ALIVE
  alive=true
  # test status of machine
  JSON=$(node_test ${machine})
  # response is either status payload or HTTP error code
  if [ ! -s ${JSON} ]; then
    case ${JSON} in
      206)
        # partial result after retries
        hzn.log.debug "machine: ${machine}; code: ${JSON}"
        BAD="${BAD}"'{"machine":"'${machine}'","error":"partialresult","code":"'${JSON}'"}'
      ;;
      *)
	hzn.log.debug "machine: ${machine} code: ${JSON}"
	BAD="${BAD}"'{"machine":"'${machine}'","error":"badhttp","code":"'${JSON}'"}'
      ;;
    esac
  else
    # responding correctly
    responding=true
    # get name of device from status payload
    name=$(jq -r '.hzn.device_id' ${JSON})
    # request summary information about device from `hznmonitor` service
    summary=$(curl -sSL "http://${HZNMONITOR_HOST}:3094/cgi-bin/summary?node=${name}" 2> /dev/null)
    # test if node found
    if [ ! -z "${summary:-}" ] && [ $(echo "${summary:-}" | jq '.error!=null') != true ]; then
	timestamp=$(echo "${summary}" | jq -r '.timestamp')
	missing=false
	hzn.log.debug "${machine} GOOD: ${CODE}; found: ${timestamp}"
    else
	missing=true
	hzn.log.debug "${machine} missing: ${name}"
	BAD="${BAD}"'{"machine":"'${machine}'","name":"'${name}'","error":"missing"}'
    fi
  fi
  rm -f "${JSON}"
else
  hzn.log.debug "${machine} is offline"
  BAD="${BAD}"'{"machine":"'${machine}'","error":"offline"}'
fi

# finish BAD array
BAD="${BAD}"']'

echo '{"machine":"'${machine}'","alive":'${alive}',"responding":'${responding}',"missing":'${missing}',"name":"'${name:-notfound}'","bad":'"${BAD:-null}"'}' | jq -c '.' >> ${out}
