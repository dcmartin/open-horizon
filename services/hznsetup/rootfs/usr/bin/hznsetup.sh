#!/bin/bash

source /usr/bin/hzn-tools.sh
source /usr/bin/service-tools.sh
source /usr/bin/hznsetup-tools.sh

###
### hznsetup.sh
###
### Run forever sending requests to hznsetup-node.sh
###

if [ "${HZN_SETUP_VENDOR:-any}" = 'any' ]; then HZN_SETUP_VENDOR="*"; fi
if [ -z "${HZN_SETUP_EXCHANGE:-}" ]; then HZN_SETUP_EXCHANGE="http://exchange:3090/v1/"; fi
if [ -z "${HZN_SETUP_ORG:-}" ]; then HZN_SETUP_ORG="${HZN_ORG_ID:-none}"; fi
if [ -z "${HZN_SETUP_APIKEY:-}" ]; then HZN_SETUP_APIKEY="${HZN_EXCHANGE_APIKEY}"; fi
if [ -z "${HZN_SETUP_APPROVE:-}" ]; then HZN_SETUP_APPROVE="auto"; fi
if [ -z "${HZN_SETUP_DB:-}" ]; then HZN_SETUP_DB="https://515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix.cloudant.com"; fi
if [ -z "${HZN_SETUP_DB:-}" ]; then hzn.log.warn "no database"; fi
if [ -z "${HZN_SETUP_USERNAME:-}" ]; then hzn.log.warn "no database username"; fi
if [ -z "${HZN_SETUP_PASSWORD:-}" ]; then hzn.log.warn "no database password"; fi
if [ -z "${HZN_SETUP_BASENAME:-}" ]; then hzn.log.info "no client basename"; fi
if [ -z "${HZN_SETUP_PATTERN:-}" ]; then hzn.log.info "no initial pattern"; fi
if [ -z "${HZN_SETUP_PORT:-}" ]; then HZN_SETUP_PORT=3093; hzn.log.info "using default port: ${HZN_SETUP_PORT}"; fi
if [ -z "${HZN_SETUP_PERIOD:-}" ]; then HZN_SETUP_PERIOD=30; hzn.log.info "using default period: ${HZN_SETUP_PERIOD}"; fi

## setup response script
if [ -z "${HZN_SETUP_SCRIPT:-}" ]; then HZN_SETUP_SCRIPT="hznsetup-node.sh"; fi
HZN_SETUP_SCRIPT=$(command -v "${HZN_SETUP_SCRIPT}")

###
### MAIN
###

## initialize horizon
hzn_init

## configure service
#SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","tmpdir":"'${TMPDIR}'","logto":"'${LOGTO:-}'","log_level":"'${LOG_LEVEL:-}'","org":"'${HZN_SETUP_ORG:-none}'","exchange":"'${HZN_SETUP_EXCHANGE:-none}'","pattern":"'${HZN_SETUP_PATTERN:-}'","port":'${HZN_SETUP_PORT:-0}',"db":"'${HZN_SETUP_DB}'","username":"'${HZN_SETUP_DB_USERNAME:-none}'","pkg":{"url":"'${HZN_SETUP_PKG_URL:-none}'","key":"'${HZN_SETUP_PKG_KEY:-none}'"},"basename":"'${HZN_SETUP_BASENAME:-}'","approve":"auto","vendor":"any","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

## FOREVER
while true; do
  DATE=$(date +%s)
  # report in
  hzn.log.info "checking socat; port ${HZN_SETUP_PORT:-NONE}; script: ${HZN_SETUP_SCRIPT:-NONE}"
  PID=$(ps x | egrep 'socat' | egrep "${HZN_SETUP_SCRIPT}" | awk '{ print $1 }' | head -1)
  if [ -z "${PID:-}" ]; then
    hzn.log.info "starting socat; port ${HZN_SETUP_PORT:-NONE}; script: ${HZN_SETUP_SCRIPT:-NONE}"
    # start listening
    socat TCP4-LISTEN:${HZN_SETUP_PORT},fork EXEC:${HZN_SETUP_SCRIPT} &
    PID=$(ps x | egrep 'socat' | egrep "${HZN_SETUP_SCRIPT}" | awk '{ print $1 }' | head -1)
    hzn.log.info "started socat; PID: ${PID}; port ${HZN_SETUP_PORT}"
  else
    PS=$(ps x | egrep socat | egrep "${HZN_SETUP_SCRIPT}")
    hzn.log.info "found ${HZN_SETUP_SCRIPT:-NONE}: ${PS}"
  fi

  if [ ! -z "${PID:-}" ]; then
    hzn.log.debug "socat running; PID: ${PID}; port ${HZN_SETUP_PORT}"
  else
    hzn.log.warn "socat failed; PID: ${PID}"
  fi

  # update service
  hzn_setup_exchange_nodes | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s)'|.pid='${PID:-0} > "${OUTPUT_FILE}"
  service_update "${OUTPUT_FILE}"

  # wait for ..
  SECONDS=$((HZN_SETUP_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    hzn.log.debug "sleep ${SECONDS}"
    sleep ${SECONDS}
  fi

done
