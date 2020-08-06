#!/bin/bash

###
### THIS SCRIPT LISTS SERVICES FOR THE ORGANIZATION 
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

for node in $(curl -sL -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/nodes" | jq -r '(.nodes|to_entries[]|.value.id=.key|.value).name'); do
  id=${node}
  if [ ! -z "${1:-}" ]; then
    if [[  ${id:-} =~ ${1} ]]; then 
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- matched: ${id}" &> /dev/stderr; fi
      match=true
    else
      match=false
    fi
  else
    match=true
  fi
  if [ "${match:-false}" = true ]; then
    echo "--- INFO $0 $$ -- deleting node: ${id}" &> /dev/stderr
    curl -sL -X DELETE -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/nodes/${id}"
  fi
done
