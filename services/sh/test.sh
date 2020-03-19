#!/bin/bash

###
### THIS SCRIPT PROVIDES A TEST HARNESS FOR SERVICE TESTING
###
### IT SHOULD __NOT__ BE CALLED INTERACTIVELY
###

## Docker
if [ -z "${1}" ]; then
  echo "*** ERROR -- $0 $$ -- no Docker tag specified; exiting" &> /dev/stderr
  exit 1
fi
DOCKER_TAG="${1}"

TEST_OUT="test.$(echo ${DOCKER_TAG##*/} | sed 's/:/_/g').json"

CID=$(docker ps --format '{{.Names}} {{.Image}}' | egrep "${DOCKER_TAG}" | awk '{ print $1 }')
if [ -z "${CID}" ]; then
  echo "*** ERROR -- $0 $$ -- cannot find running container with tag: ${DOCKER_TAG}" &> /dev/stderr
  exit 1
else
  if [ "${DEBUG:-}" ]; then echo "--- INFO -- $0 $$ -- found container with tag ${DOCKER_TAG}: ${CID}" &> /dev/stderr; fi
fi

if [ ! -z "${2}" ]; then
  HOST="${2}"
else
  HOST="127.0.0.1"
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- No host specified; assuming ${HOST}" &> /dev/stderr; fi
fi

if [ "${HOST%:*}" == "${HOST}" ]; then
  if [ -z "${SERVICE_PORT}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO $0 $$ -- empty: SERVICE_PORT" &> /dev/stderr; fi
  else
    PORT=${SERVICE_PORT}
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO $0 $$ -- Using SERVICE_PORT: ${PORT}" &> /dev/stderr; fi
  fi
  if [ -z "${PORT}" ] || [ "${PORT}" == 'null' ]; then
    PORT=80
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- No port specified; assuming port ${PORT}" &> /dev/stderr; fi
  fi
  HOST="${HOST}:${PORT}"
fi

if [[ ${HOST} =~ http* ]]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- protocol specified" &> /dev/stderr; fi
else
  PROT="http"
  if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- No protocol specified; assuming ${PROT}" &> /dev/stderr; fi
  HOST="${PROT}://${HOST}"
fi

if [ -z "${SERVICE_LABEL:-}" ]; then SERVICE_LABEL=${PWD##*/}; fi
CMD="${PWD}/test-${SERVICE_LABEL}.sh"
if [ -z $(command -v "${CMD}") ]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- no test script: ${CMD}" &> /dev/stderr; fi
else
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- using test script: ${CMD}" &> /dev/stderr; fi
fi

if [ -z ${TIMEOUT:-} ]; then TIMEOUT=2; fi

if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- Testing ${SERVICE_LABEL} in container ${CID} tagged: ${DOCKER_TAG} at" $(date) &> /dev/stderr; fi

I=0

while true; do
  OUT=$(docker exec "${CID}" curl --connect-timeout ${TIMEOUT} --max-time $((TIMEOUT*10)) -sSL "${HOST}")
  if [ $? != 0 ]; then
    echo "*** ERROR -- $0 $$ -- curl failed to ${HOST}" &> /dev/stderr
    echo 'null'
    exit 1
  fi

  if [ ! -z "${OUT}" ] && [ "${OUT}" != 'null' ]; then
    echo "${OUT}" > "${TEST_OUT}"
    if [ ! -z "$(command -v ${CMD})" ]; then
      TEST=$(echo "${OUT}" | ${CMD} 2> /dev/stderr)
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- missing test command: ${CMD}" &> /dev/stderr; fi
      TEST=$(echo "${OUT}" | jq -c '.!=null' 2> /dev/stderr)
    fi
    if [ "${TEST:-}" == 'true' ]; then
        if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- test ${CMD} returned ${TEST}" &> /dev/stderr; fi
        echo "${TEST}"
        exit 0
    else
        echo "*** ERROR -- $0 $$ -- test ${CMD} returned ${TEST}" &> /dev/stderr
        echo "${OUT}"
        exit 1
    fi
  else
    echo "*** ERROR -- $0 $$ -- ${HOST} returns ${OUT}" &> /dev/stderr
    exit 1
  fi

  if [ $(date +%s) -gt ${TIMEOUT} ]; then
    echo "*** ERROR -- $0 $$ -- timeout" &> /dev/stderr
    exit 1
  fi
  I=$((I+1))
  if [ "${DEBUG:-}" == 'true' ]; then echo '--- INFO -- $0 $$ -- iteration ${I}; sleeping ...' &> /dev/stderr; fi
  sleep 1
done
