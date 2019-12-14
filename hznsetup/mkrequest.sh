#!/bin/bash

## test for arguments
if [ ! -z "${1}" ]; then HZNSETUP_ENDPOINT="${1}"; fi
if [ ! -z "${2}" ]; then DEBUG="${2}"; fi

###
### FUNCTIONS
###

## unregister node
node_unregister()
{
  result=
  if [ ! -z "${1}" ]; then 
    HEU=${1}
  else
    HEU=$(hzn node list 2> /dev/null | jq -r '.configuration.exchange_api')
  fi
  if [ ! -z "${HEU:-}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- unregistering from ${HEU}" &> /dev/stderr; fi
    result=$(export HZN_EXCHANGE_URL=${HEU} && hzn unregister -f -r)
  else
    if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- no exchange URL" &> /dev/stderr; fi
  fi
  echo "${result:-}"
}

## register node
node_register()
{
  result=
  quit=false
  if [ ! -z "${1}" ]; then HEU=${1}; else quit=true; fi
  if [ ! -z "${2}" ]; then HOI=${2}; else quit=true; fi
  if [ ! -z "${3}" ]; then PAT=${3}; else quit=true; fi
  if [ ! -z "${4}" ]; then DEV=${4}; else quit=true; fi
  if [ ! -z "${5}" ]; then TOK=${5}; else quit=true; fi
  if [ ! -z "${6}" ]; then UIJ="${6}"; else quit=true; fi
  if [ "${quit:-}" != true ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- registering node with pattern: ${PAT}" &> /dev/stderr; fi
    input=$(mktemp -t "${0##*/}-XXXXXX")
    echo "${UIJ}" > ${input}
    result=$(export HZN_EXCHANGE_URL=${HEU} && hzn register ${HOI} ${PAT} -f ${input} -n ${DEV}:${TOK})
    rm -f ${input}
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- registered node; result: ${RESULT}" &> /dev/stderr; fi
  fi
  echo "${result:-}"
}

## return node state
# utilizes globals: DEVICE, EXCHANGE, ORGANIZATION, PATTERN
node_state()
{
  result=
  # get node information (if any)
  HNL=$(hzn node list 2> /dev/null)
  if [ ! -z "${HNL:-}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- hzn installed and operational" &> /dev/stderr; fi
    state=$(echo "${HNL}" | jq -r '.configstate.state')
    case "${state}" in
      "configured")
	pattern=$(echo "${HNL}" | jq -r '.pattern')
	organization=$(echo "${HNL}" | jq -r '.organization')
	name=$(echo "${HNL}" | jq -r '.name')
	exchange=$(echo "${HNL}" | jq -r '.configuration.exchange_api')
	if [ "${name:-none}" != "${DEVICE:-unknown}" ]; then
	  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- non-matching name; old: ${name}; new: ${DEVICE}" &> /dev/stderr; fi
	  result="${state}"':name'
	fi
	if [ "${exchange%/}" != "${EXCHANGE%/}" ]; then
	  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- non-matching exchange; old: ${exchange%/:-none}; new: ${EXCHANGE%/:-unknown}" &> /dev/stderr; fi
	  result="${state}"':exchange'
	else
	  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- matching exchange: ${exchange}" &> /dev/stderr; fi
	  if [ "${organization:-none}" != "${ORGANIZATION:-unknown}" ]; then
	    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- non-matching organization; old: ${organization}; new: ${ORGANIZATION}" &> /dev/stderr; fi
	    result="${state}"':org'
	  else
	    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- matching organization: ${organization}" &> /dev/stderr; fi
	  fi
	fi
	if [ "${pattern:-none}" != "${PATTERN:-unknown}" ]; then
	  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- non-matching pattern; old: ${pattern}; new: ${PATTERN}" &> /dev/stderr; fi
	  result="${state}"':pattern'
	else
	  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- matching pattern: ${pattern}" &> /dev/stderr; fi
          result="${state}"
	fi
      ;;
      "unconfigured")
	if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- ${state}: " $(echo "${HNL}" | jq -c '.') &> /dev/stderr; fi
        result="${state}"
      ;;
      "configuring")
	if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- ${state}: " $(echo "${HNL}" | jq -c '.') &> /dev/stderr; fi
        result="${state}"
      ;;
      "unconfiguring")
	if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- ${state}: " $(echo "${HNL}" | jq -c '.') &> /dev/stderr; fi
        result="${state}"
      ;;
      *)
	if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- unhandled state: ${state}" &> /dev/stderr; fi
	result='unknown-state'
      ;;
    esac
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- hzn not installed or improperly configured; exiting" &> /dev/stderr; fi
  fi
  echo "${result:-}"
}

###
### MAIN
###

# test if root
if [ $(whoami) != 'root' ]; then echo "*** ERROR $0 $$ -- run as root" &> /dev/stderr; exit 1; fi
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- am root" &> /dev/stderr; fi

# if no `ip` command; stop
if [ -z "$(command -v ip)" ]; then echo "*** ERROR $0 $$ -- no ip command installed" &> /dev/stderr; exit 1; fi
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- have ip" &> /dev/stderr; fi

# test for hardware inspection
if [ -z "$(command -v lshw)" ]; then 
  APTGET=$(command -v apt-get)
  # test if we can install
  if [ -z "${APTGET}" ]; then 
    echo "*** ERROR $0 $$ -- no lshw command installed" &> /dev/stderr
    exit 1
  else 
    echo "+++ WARN $0 $$ -- installing lshw" &> /dev/stderr
    ${APTGET} install -qq -y lshw &> /dev/null
  fi
fi
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- know lshw" &> /dev/stderr; fi

## ensure endpoint
if [ -z "${HZNSETUP_ENDPOINT:-}" ]; then 
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- no endpoint" &> /dev/stderr; fi
  exit 1
else
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- endpoint: ${HZNSETUP_ENDPOINT}" &> /dev/stderr; fi
fi

## get hardware
LSHW=$(sudo lshw 2> /dev/null | egrep 'product|serial' | head -2 | sed 's/^[ ]*//' | awk -F': ' 'BEGIN { printf(""); x=0; } { if (x++ > 0) { printf(","); } printf("\"%s\":\"%s\"", $1, $2); } END { printf(""); }')

## get networking
IPADDR=$(ip addr | egrep  -B 1 $(hostname -I | awk '{ print $1 }') | awk 'BEGIN { printf(""); x=0 } { if (x++ > 0) { printf(",") }; printf("\"%s\":\"%s\"", $1, $2); } END { printf("\n"); }' | sed 's|link/ether|mac|')

## build request
REQUEST='{'${LSHW:-null}','${IPADDR:-null}'}'
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- made request: ${REQUEST}" &> /dev/stderr; fi

## send request
PAYLOAD=$(mktemp -t "${0##*/}-XXXXXX")
echo "${REQUEST}" > ${PAYLOAD}
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- sending request to: ${HZNSETUP_ENDPOINT}" &> /dev/stderr; fi
RESPONSE=$(curl "${HZNSETUP_ENDPOINT}" -X POST -H "Content-Type: application/json" --data-binary @"${PAYLOAD}")

## process response
if [ ! -z "${RESPONSE:-}" ]; then
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- received response:" $(echo "${RESPONSE}" | jq -c '.') &> /dev/stderr; fi
  # get basics
  ORGANIZATION=$(echo "${RESPONSE}" | jq -r '.org')
  EXCHANGE=$(echo "${RESPONSE}" | jq -r '.exchange')
  DEVICE=$(echo "${RESPONSE}" | jq -r '.node.device')
  TOKEN=$(echo "${RESPONSE}" | jq -r '.node.token')
  # get pattern and input (if any)
  PATTERN=$(echo "${RESPONSE}" | jq -r '.pattern')
  if [ -z "${PATTERN:=}" ] || [ "${PATTERN:-}" = 'none' ]; then
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no pattern" &> /dev/stderr; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- pattern: ${PATTERN}" &> /dev/stderr; fi
    INPUT=$(echo "${RESPONSE}" | jq '.input')
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- pattern input:" $(echo "${INPUT}" | jq -c '.') &> /dev/stderr; fi
  fi
else
  if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- received no response" &> /dev/stderr; fi
  exit 1
fi

## process state changes until good
STATE=$(node_state)
while [ "${STATE:-}" != 'configured' ]; do
  case "${STATE}" in
    configured:pattern)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- non-matching pattern; unregistering" &> /dev/stderr; fi
	RESULT=$(node_unregister ${EXCHANGE})
	;;
    configured:org)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- non-matching pattern; unregistering" &> /dev/stderr; fi
	RESULT=$(node_unregister ${EXCHANGE})
	;;
    configured:exchange)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- non-matching pattern; unregistering" &> /dev/stderr; fi
	RESULT=$(node_unregister)
	;;
    configured:*)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${STATE}" &> /dev/stderr; fi
	;;
    configured)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- configured" &> /dev/stderr; fi
	;;
    unconfigured)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- unconfigured: ${STATE}" &> /dev/stderr; fi
	RESULT=$(node_register ${EXCHANGE} ${ORGANIZATION} ${PATTERN} ${DEVICE} ${TOKEN} "${INPUT}")
	;;
    unconfiguring)
        if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- unconfiguring; breaking" &> /dev/stderr; fi
	break
	;;
    configuring)
        if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- configuring; breaking" &> /dev/stderr; fi
	break
	;;
    *)
        if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- main: unhandled state: ${STATE}" &> /dev/stderr; fi
        break;
	;;
  esac
  STATE=$(node_state)
done
