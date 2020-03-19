#!/bin/bash

DEBUG=true

objectID="${1}"
objectType="${2:-test}"
url="${3:-local}"
file="${4:-}"
if [ -z "${file}" ]; then
  file=$(mktemp -t "${0##*/}-XXXXXX")
  temp=true
else
  file=${4}
fi

if [ "${url}" = 'local' ]; then
  url="localhost:8580/api/v1"
  auth="${HZN_ORG_ID}/${HZN_ORG_ID}admin:${HZN_ORG_ID}adminpw"
elif [ "${url}" = 'alpha' ]; then
  url="https://alpha.edge-fabric.com/css/api/v1"
  auth=${5:-${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}}
elif [ "${url}" = 'stg' ]; then
  url="https://stg.edge-fabric.com/css/api/v1"
  auth=${5:-${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}}
else
  echo "*** ERROR: invalid service location: ${url}; options: 'local', 'alpha', 'stg'" &> /dev/stderr
  exit 1
fi

# outside container; use organization
url="${url}/objects/${HZN_ORG_ID}"

if [ ! -z "${objectID}" ]; then
  echo "--- INFO -- $0 $$ -- requesting:" curl \
    -sSL \
    -X GET \
    -w '%{http_code}' \
    -o ${file} \
    -u "${auth}" \
    "${url}/${objectType}/${objectID}/data"
  HTTP_CODE=$(curl \
    -sSL \
    -X GET \
    -w '%{http_code}' \
    -o ${file} \
    -u "${auth}" \
    "${url}/${objectType}/${objectID}/data")
  case ${HTTP_CODE} in
    200)
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- success; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      jq -c '.' ${file}
      if [ "${temp:-}" = true ]; then rm -f ${file}; fi
      ;;
    500)
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- failed; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      exit 1
      ;;
    *)
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- unknown; http_code: ${HTTP_CODE}" &> /dev/stderr; fi
      exit 1
      ;;
  esac
else
  echo "Usage: $0 <objectID:-$(hostname)> <objectType:-test> <url?>" &> /dev/stderr
  exit 1
fi

exit 0
