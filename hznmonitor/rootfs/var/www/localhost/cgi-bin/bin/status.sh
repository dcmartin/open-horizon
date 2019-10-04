#!/bin/bash

###
### THIS SCRIPT LISTS NODES FOR THE ORGANIZATION
###
### CONSUMES THE FOLLOWING ENVIRONMENT VARIABLES:
###
### + HZNMONITOR_EXCHANGE_URL
### + HZNMONITOR_EXCHANGE_ORG
### + HZNMONITOR_EXCHANGE_APIKEY
###

if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

if [ -z "${HZNMONITOR_EXCHANGE_URL:-}" ]; then HZNMONITOR_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"; fi

if [ -z "${HZNMONITOR_EXCHANGE_APIKEY:-}" ] || [ "${HZNMONITOR_EXCHANGE_APIKEY:-}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZNMONITOR_EXCHANGE_APIKEY" &> /dev/stderr
  exit 1
fi
  
if [ -z "${HZNMONITOR_EXCHANGE_ORG:-}" ] || [ "${HZNMONITOR_EXCHANGE_ORG:-}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZNMONITOR_EXCHANGE_ORG" &> /dev/stderr
  exit 1
fi

if [ ! -z "${1}" ]; then
  ID="${1}"
  curl -sL -u "${HZNMONITOR_EXCHANGE_ORG}/${HZNMONITOR_EXCHANGE_USER:-iamapikey}:${HZNMONITOR_EXCHANGE_APIKEY}" "${HZNMONITOR_EXCHANGE_URL%/}/orgs/${HZNMONITOR_EXCHANGE_ORG}/nodes/${ID}/status" \
    | jq '.={"status":.}' | jq '.name="'${ID}'"|.org="'${HZNMONITOR_EXCHANGE_ORG}'"|.user="'${HZNMONITOR_EXCHANGE_USER}'"|.url="'${HZNMONITOR_EXCHANGE_URL}'"'
fi
