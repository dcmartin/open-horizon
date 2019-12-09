#!/bin/bash

###
### THIS SCRIPT DELETES USER FOR THE ORGANIZATION
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

if [ -z "${HZN_EXCHANGE_URL:-}" ]; then HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"; fi

if [ -z "${HZN_EXCHANGE_APIKEY:-}" ] || [ "${HZN_EXCHANGE_APIKEY:-}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_EXCHANGE_APIKEY" &> /dev/stderr
  exit 1
fi
  
if [ -z "${HZN_ORG_ID:-}" ] || [ "${HZN_ORG_ID:-}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_ORG_ID" &> /dev/stderr
  exit 1
fi

curl -sL -Z DELETE -u "${HZN_ORG_ID}/iamapikey:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/users/${user}" \
  | jq '{"exchange":"'${HZN_EXCHANGE_URL}'","org":"'${HZN_ORG_ID}'","result":.}'
