#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## configure service

CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"period":"'${HZNCLI_PERIOD:-30}'","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

while true; do
  DATE=$(date +%s)
  echo '{"nodes":' > ${OUTPUT_FILE}
  DATA_FILE=$(mktemp -t "${0##*/}-XXXXXX")
  hzn exchange node list -l > ${DATA_FILE} 2> /dev/stderr
  if [ -s "${DATA_FILE}" ]; then
    echo '[' >> ${OUTPUT_FILE}
    cat "${DATA_FILE}" >> ${OUTPUT_FILE}
    echo ']' >> ${OUTPUT_FILE}
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- no data from hzn exchange node list" &> /dev/stderr; fi
    echo 'null' >> ${OUTPUT_FILE}
  fi
  echo '}' >> ${OUTPUT_FILE}
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((HZNCLI_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
