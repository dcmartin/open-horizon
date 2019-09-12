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

if [ -z "${HZN_EXCHANGE_URL:-}" ]; then HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"; fi

if [ -z "${HZN_EXCHANGE_APIKEY:-}" ] || [ "${HZN_EXCHANGE_APIKEY:-}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_EXCHANGE_APIKEY" &> /dev/stderr
  exit 1
fi
  
if [ -z "${HZN_ORG_ID:-}" ] || [ "${HZN_ORG_ID:-}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_ORG_ID" &> /dev/stderr
  exit 1
fi

node=${1:-}
shift
name=${1:-}
shift
type=${1:-}
shift
value="${*}"

echo "node: ${node}; name: ${name}; type: ${type}; value=${value}"

TEMP=$(mktemp)
CODE=$(curl -w '%{http_code}' -o ${TEMP} -sL -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/nodes/${node}/policy")
if [ ${CODE} != 200 ]; then
  output='{"node":"'${node}'","exchange":"'${HZN_EXCHANGE_URL}'","org":"'${HZN_ORG_ID}'","policy":{"properties":[],"constraints":[],"jsonFormats":{}}}'
else
  output=$(jq '{"node":"'${node}'","exchange":"'${HZN_EXCHANGE_URL}'","org":"'${HZN_ORG_ID}'","policy":.}' ${TEMP})
fi

#output=$(echo "${output}" | jq '.policy.properties?+=[{"name":"'${name}'","type":"'${type}'","value":'"${value}"'}]')
output=$(echo "${output}" | jq '.policy.properties?+=[{"name":"'${name}'","value":'"${value}"'}]')

POLICY=$(mktemp)

echo "${output}" | jq -c '.policy' > ${POLICY}

jq '.' ${POLICY}

CODE=$(curl -w '%{http_code}' -o ${TEMP} -d @${POLICY} -X PUT -sL -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/nodes/${node}/policy")

if [ "${CODE}" != 200 ]; then
  output='{"node":"'${node}'","exchange":"'${HZN_EXCHANGE_URL}'","error":'$(cat ${TEMP})',"org":"'${HZN_ORG_ID}'","policy":null}'
else
  output=$(${0%/*}/lsnodePolicy.sh ${node})
fi

rm -f ${TEMP} ${POLICY}

echo "${output}" | jq
