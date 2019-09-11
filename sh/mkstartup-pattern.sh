#!/bin/bash

if [ -z "${1:=}" ]; then
  echo "Usage: ${0##*/} <pattern>"
  exit 1
fi

pattern=${1}

IBM=$(hzn exchange pattern list \
  -l "IBM/" \
  -u ${HZN_ORG_ID:-MISSING_HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY:-MISSING_HZN_EXCHANGE_APIKEY} \
  | jq '{"patterns":[.|to_entries[]|.value.id=.key|.value]}')

ORG=$(hzn exchange pattern list \
  -l "${HZN_ORG_ID}/" \
  -u ${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY} \
  | jq '{"patterns":[.|to_entries[]|.value.id=.key|.value]}')

# optional alternative pattern
startup="${2:-startup}"
#if [ -s "../TAG" ]; then startup=${startup}-$(cat ../TAG); fi

# optional alternative organization
hzn_org_id="${3:-dcmartin}"

SERVICES=$(echo "${ORG}" \
  | jq '[.patterns[]|select(.id=="'${hzn_org_id}/${startup}'").services[]|{"serviceUrl":.serviceUrl,"serviceArch":.serviceArch,"serviceVersions":.serviceVersions,"serviceOrgid":.serviceOrgid}]')

echo "${IBM}" | jq '{"label":"'${pattern}'","description":"IBM/'${pattern}' for '${HZN_ORG_ID}'","services":[.patterns[]|select(.id=="IBM/'${pattern}'").services[]|{"serviceUrl":.serviceUrl,"serviceArch":.serviceArch,"serviceVersions":.serviceVersions,"serviceOrgid":.serviceOrgid}]}' | jq '.services+='"${SERVICES}"
