#!/bin/bash

if [ -z "${1:-}" ]; then
  echo "no first argument: service directory" &> /dev/stderr
  exit 1
fi

if [ -z "${HZN_EXCHANGE_URL:-}" ]; then
  echo "no exchange url" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_EXCHANGE_APIKEY:-}" ]; then
  echo "no exchange apikey" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_ORG_ID:-}" ]; then
  echo "no org id" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_USER_ID:-}" ]; then
  echo "no user id; using iamapikey" &> /dev/stderr
  HZN_USER_ID="iamapikey"
fi

PRIVATE_KEY=${2:-key.pem}
PUBLIC_KEY=${3:-key.pub}
if [ ! -s "${PRIVATE_KEY}" ] || [ ! -s "${PUBLIC_KEY}" ]; then
  echo "no key files" &> /dev/stderr
  exit 1
fi

ARCH_SUPPORT=$(jq -r '.build_from|to_entries[]|select(.value!=null).key' ${1}/build.json)

for ARCH in ${ARCH_SUPPORT}; do
  export BUILD_ARCH=${ARCH}
  export BUILD_FROM=$(jq -r '.build_from.'${ARCH} ${1}/build.json)
  cat ${1}/service.json.tmpl | envsubst > ${1}/service.json
  hzn exchange service publish \
    -I \
    -O \
    -o ${HZN_ORG_ID} \
    -u ${HZN_ORG_ID}/${HZN_USER_ID}:${HZN_EXCHANGE_APIKEY} \
    -k ${PRIVATE_KEY} \
    -K ${PUBLIC_KEY} \
    -f ${1}/service.json
done
