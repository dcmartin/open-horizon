#!/bin/bash

##
## functions
##

source /usr/bin/hzn-tools.sh
source /usr/bin/hznsetup-tools.sh

###
### hznsetup-node.sh
### 

## read request
while read; do
  if [ -z "${REPLY:-}" ]; then continue; fi
  case "${REPLY}" in
    POST*)
	POST=true
        hzn::log.debug "received: ${REPLY}"
	continue
	;;
    Content-Length*)
	if [ "${POST:-false}" = true ]; then
	  # size being sent
	  BYTES=$(echo "${REPLY}" | sed 's/.*: \([0-9]*\).*/\1/')
	  # margin
	  BYTES=$((BYTES+2))
          hzn::log.debug "content length: ${BYTES}"
	  break;
        fi
	continue
	;;
    GET*)
        hzn::log.debug "received: ${REPLY}"
	POST=false
	break
	;;
    *)
	continue
	;;
  esac
done

## check if handling a post
if [ "${POST:-false}" = true ]; then
  hzn::log.debug "reading ${BYTES} bytes"
  # read request
  INPUT=$(dd count=${BYTES} bs=1 2> /dev/null | tr '\n' ' ' | tr '\r' ' ')
  hzn::log.debug "processing: ${INPUT}"
  # validate JSON
  INPUT=$(echo "${INPUT:-null}" | jq -c '.')
  if [ ! -z "${INPUT}" ]; then
    hzn::log.debug "valid: ${INPUT}"
    # generate response
    RESPONSE='{"exchange":"'${HZN_SETUP_EXCHANGE:-}'","org":"'${HZN_SETUP_ORG:-}'","pattern":"'${HZN_SETUP_PATTERN:-}'"}'
    # process input
    NODE=$(hzn_setup_process "${INPUT}")
    # update response
    if [ -z "${NODE:-}" ] || [ "${NODE:-}" = 'null' ]; then
      RESPONSE=$(echo "${RESPONSE}" | jq '.exchange=null|.error="not found"')
    else
      hzn::log.debug "approved node:" $(echo "${NODE}" | jq -c '.')
      RESPONSE=$(echo "${RESPONSE}" | jq '.node='$(echo "${NODE:-null}" | jq -c '.'))
      # create userinput
      if [ ! -z "${HZN_SETUP_PATTERN:-}" ]; then
        userinput=$(hzn_setup_userinput "${HZN_SETUP_PATTERN:-}")
        hzn::log.debug "userinput:" $(echo "${userinput:-null}" | jq -c '.')
	if [ ! -z "${userinput:-}" ]; then
          RESPONSE=$(echo "${RESPONSE}" | jq '.input='$(echo "${userinput:-null}" | jq -c '.'))
        fi
      fi
    fi
  fi
fi

if [ "${POST:-false}" = false ] || [ -z "${INPUT}" ]; then
  hzn::log.error "error: ${INPUT}"
  # generate error
  RESPONSE='{"error":"POST only valid JSON"}'
fi

## add device back to response
RESPONSE=$(echo "${RESPONSE:-null}" | jq '.|.device='"${INPUT:-null}")

## add date
RESPONSE=$(echo "${RESPONSE}" | jq '.|.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s))

## calculate size
SIZ=$(echo "${RESPONSE}" | wc -c | awk '{ print $1 }')
hzn::log.debug "output size: ${SIZ}"

## send response
echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo ""
echo "${RESPONSE:-error}"
