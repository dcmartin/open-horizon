#!/bin/bash

DEBUG=true

objectID=${1}
objectType=${2:-test}
url=${3:-local}
destID="${HZN_DEVICE:-}"
destType="${HZN_PATTERN:-}"
objectVersion='0.0.1'

if [ "${url}" = 'local' ]; then
  url="http://localhost:8580/api/v1"
  auth="${HZN_ORG_ID}/${HZN_ORG_ID}admin:${HZN_ORG_ID}adminpw"
elif [ "${url}" = 'alpha' ]; then
  url="https://alpha.edge-fabric.com/css/api/v1"
  auth=${4:-${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}}
elif [ "${url}" = 'stg' ]; then
  url="https://stg.edge-fabric.com/css/api/v1"
  auth=${4:-${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}}
else
  echo "*** ERROR: invalid service location: ${url}; options: 'local', 'remote'" &> /dev/stderr
  exit 1
fi

# outside container; use organization
url="${url}/objects/${HZN_ORG_ID}"

if [ -z "${5:-}" ]; then
  file=$(mktemp -t "${0##*/}-XXXXXX")
  temp=true
  cat > ${file}
fi

if [ ! -z "${file}" ] && [ -s "${file}" ]; then
  meta=$(mktemp -t "${0##*/}-XXXXXX")
  echo '{"data":[],"meta":{"objectID":"'${objectID}'","objectType": "'${objectType}'","destinationID":"'${destID}'","destinationType":"'${destType}'","version": "'${objectVersion}'", "description":"created at '$(date -u +%FT%TZ)'"}}' > ${meta}
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- meta: " $(jq -c '.' ${meta}) &> /dev/stderr; fi

  TEMP=$(mktemp -t "${0##*/}-XXXXXX")
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- creating object: " curl \
    -sSL \
    -X PUT \
    -w '%{http_code}' \
    -o ${TEMP} \
    -u "${auth}" \
    --header 'Content-Type:application/octet-stream' \
    --data-binary @${meta} \
    "${url}/${objectType}/${objectID}" &> /dev/stderr; fi

  HTTP_CODE=$(curl \
    -sSL \
    -X PUT \
    -w '%{http_code}' \
    -o ${TEMP} \
    -u "${auth}" \
    --header 'Content-Type:application/octet-stream' \
    --data-binary @${meta} \
    "${url}/${objectType}/${objectID}")

  case ${HTTP_CODE} in
    204)
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- success; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      RESULT=true
      ;;
    500)
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- failed; http_code: ${HTTP_CODE}; error: " $(cat "${TEMP}") &> /dev/stderr; fi
      ;;
    *)
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- UNKNOWN; http_code: ${HTTP_CODE}; error: " $(cat "${TEMP}") &> /dev/stderr; fi
      ;;
  esac
  rm -f ${TEMP}
  rm -f ${meta}

  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- file found: " $(wc -c ${file}) &> /dev/stderr; fi

  TEMP=$(mktemp -t "${0##*/}-XXXXXX")
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- putting data:" curl \
    -sSL \
    -X PUT \
    -o ${TEMP} \
    -w '%{http_code}' \
    -u "${auth}" \
    --header 'Content-Type:application/octet-stream' \
    --data-binary @${file} \
    "${url}/${objectType}/${objectID}/data" &> /dev/stderr; fi

  HTTP_CODE=$(curl \
    -sSL \
    -X PUT \
    -o ${TEMP} \
    -w '%{http_code}' \
    -u "${auth}" \
    --header 'Content-Type:application/octet-stream' \
    --data-binary @${file} \
    "${url}/${objectType}/${objectID}/data")

  case ${HTTP_CODE} in
    204)
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- success; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      RESULT=true
      ;;
    500)
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- failed; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      ;;
    *)
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- UNKNOWN; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      ;;
  esac
  rm -f ${TEMP}
else
  echo "Usage: $0 <file> <objectID?:-$(hostname)> <objectType?:-test> <url?:-${HZN_EXCHANGE_URL}/css/api/v1>" &> /dev/stderr
  RESULT=false
fi

# cleanup
if [ "${temp:-}" = true ]; then rm -f "${file}"; fi

echo "${RESULT:-false}"
