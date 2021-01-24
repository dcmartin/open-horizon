#!/bin/bash

###
### THIS SCRIPT LISTS NODES FOR THE ORGANIZATION
###
### CONSUMES THE FOLLOWING ENVIRONMENT VARIABLES:
###
### + HZN_EXCHANGE_URL
### + HZN_ORG_ID
### + HZN_EXCHANGE_APIKEY
###

if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

if [ -z "${HZN_EXCHANGE_URL:-}" ]; then
  HZN_EXCHANGE_URL="http://exchange:3090/v1"
  if [ -s HZN_EXCHANGE_URL ]; then
    HZN_EXCHANGE_URL=$(cat HZN_EXCHANGE_URL)
  fi
fi

if [ -z "${HZN_EXCHANGE_APIKEY:-}" ]; then
  HZN_EXCHANGE_APIKEY="whocares"
  if [ -s HZN_EXCHANGE_APIKEY ]; then
    HZN_EXCHANGE_APIKEY=$(cat HZN_EXCHANGE_APIKEY)
  fi
fi

if [ -z "${HZN_ORG_ID:-}" ]; then
  HZN_ORG_ID="${USER}"
  if [ -s HZN_ORG_ID ]; then
    HZN_ORG_ID=$(cat HZN_ORG_ID)
  fi
fi

node=${1:-$(hostname)}
TEMP=$(mktemp)
CODE=$(curl -w '%{http_code}' -o ${TEMP} -sL -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/nodes/${node}/policy")
if [ ${CODE} != 200 ]; then
  output='{"node":"'${node}'","exchange":"'${HZN_EXCHANGE_URL}'","error":"'${CODE}'","org":"'${HZN_ORG_ID}'","policy":[]}'
else
  output=$(jq '{"node":"'${node}'","exchange":"'${HZN_EXCHANGE_URL}'","org":"'${HZN_ORG_ID}'","policy":.}' ${TEMP})
fi
rm -f ${TEMP}
echo "${output}"
