#!/bin/bash

###
### THIS SCRIPT FIXES SERVICES AND USERINPUT WHEN TAG IS SPECIFIED
###
### IT SHOULD __NOT__ BE CALLED INTERACTIVELY
###

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR -- $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
SERVICE="${DIR}/service.definition"
USERINPUT="${DIR}/userinput"

# mandatory
for json in ${SERVICE} ${USERINPUT}; do
  if [ ! -s "${json}.json" ]; then echo "*** ERROR -- $0 $$ -- no ${json}.json" 2> /dev/stderr; exit 1; fi
done

# architecture
ARCH=$(jq -r '.arch' "${SERVICE}.json")

userinput_services=$(jq '.services|length' ${USERINPUT}.json)
required_services=$(jq '.requiredServices|length' ${SERVICE}.json)

# tagging
if [ ! -z "${TAG:-}" ]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- modifying service URL with ${TAG} in ${USERINPUT}.json and ${SERVICE}.json" &> /dev/stderr; fi
  if [ ${userinput_services} -gt 0 ]; then
    jq -c '.services=[.services[]|.url as $url|.url=$url+"-'${TAG}'"]' ${USERINPUT}.json > /tmp/$$ && mv -f /tmp/$$ ${USERINPUT}.json
  fi
  if [ ${required_services} -gt 0 ]; then
    jq -c '.requiredServices=[.requiredServices?[]|.url as $url|.url=$url+"-'${TAG}'"]' ${SERVICE}.json > /tmp/$$ && mv -f /tmp/$$ ${SERVICE}.json
  fi
fi

# architecture
if [ ${required_services} -gt 0 ]; then
  jq -c '.requiredServices=[.requiredServices?[]|.arch="'${ARCH}'"]' ${SERVICE}.json > /tmp/$$
  mv -f /tmp/$$ ${SERVICE}.json
  jq -r '.requiredServices?|to_entries[]|.value.url' "${SERVICE}.json" | while read -r; do
    URL="${REPLY}"
    if [ -z "${URL}" ]; then echo "Error: empty required service URL: ${URL}" &> /dev/stderr; exit 1; fi
    VER=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.version' "${SERVICE}.json")
    if [ -z "${VER}" ]; then echo "Error: empty version for required service ${URL}" &> /dev/stderr; exit 1; fi
    ORG=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.org' "${SERVICE}.json")
    if [ -z "${ORG}" ]; then echo "Error: empty org for required service ${URL}" &> /dev/stderr; exit 1; fi
  done
fi
