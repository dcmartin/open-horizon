#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# type
if [ -z "${1}" ]; then objectType='model'; else objectType="${1}"; fi

# get ESS credentials
USER=$(jq -r ".id" ${HZN_ESS_AUTH:-NONE})
PSWD=$(jq -r ".token" ${HZN_ESS_AUTH:-NONE})

# request all objects of objectType that have not been received
OBJECT_ARRAY=$(mktemp -t "${0##*/}-XXXXXX")
HTTP_CODE=$(curl \
      -sSL \
      -w '%{http_code}' \
      -o ${OBJECT_ARRAY} \
      -u "${USER}:${PSWD}" \
      --cacert ${HZN_ESS_CERT} \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      "https://localhost/api/v1/objects/${objectType}")

if [ ${HTTP_CODE:-0} -eq 200 ]; then
  # count number
  COUNT=$(jq '.|length' ${OBJECT_ARRAY})
  # loop through all objects retrieving data
  for ID in $(jq -r '.[].objectID' ${OBJECT_ARRAY}); do
    # retrieve data
    curl -sSL \
      -o ${TMPDIR}/${ID}.dat \
      -u "${USER}:${PSWD}" \
      --cacert ${HZN_ESS_CERT} \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      "https://localhost/api/v1/objects/${objectType}/${ID}/data"
    # check for data
    if [ ! -z "${OBJECTS:-}" ]; then OBJECTS="${OBJECTS},"; else OBJECTS='['; fi
    OBJECTS="${OBJECTS}"'{"ID":"'${ID}'","file":"'${TMPDIR}/${ID}.dat'","size":"'$(wc -c ${TMPDIR}/${ID}.dat | awk '{ print $1 }')'"}'
    # send receipt
    curl -sSL \
      -X PUT \
      -u "${USER}:${PSWD}" \
      --cacert ${HZN_ESS_CERT} \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      "https://localhost/api/v1/objects/${objectType}/${ID}/received"
  done
  if [ ! -z "${OBJECTS:-}" ]; then OBJECTS="${OBJECTS}]"; fi
  echo "SUCCESS; OBJECTS: ${OBJECTS}" &> /dev/stderr
else
  echo "FAILED; HTTP_CODE: ${HTTP_CODE}" &> /dev/stderr
fi
rm -f ${OBJECT_ARRAY}

echo "${OBJECTS:-null}"
