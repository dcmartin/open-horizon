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

CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","logto":"'${LOGTO}'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"period":'${HERALD_PERIOD:-60}',"port":'${HERALD_PORT:-5960}',"services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## start discovery
python /usr/bin/herald.py &
# get pid
PID=$!

## initialize
OUTPUT_FILE=$(mktemp -t "${0##*/}-XXXXXX")
URL='http://127.0.0.1:'${HERALD_PORT}'/v1/announced'

while true; do
  DATE=$(date +%s)
  ANNOUNCED=$(curl -fsSL "${URL}" | jq -c '.' 2> /dev/null)
  if [ -z "${ANNOUNCED}" ]; then ANNOUNCED='null'; fi
  echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"pid":'${PID}',"announced":'"${ANNOUNCED}"'}' > ${OUTPUT_FILE}
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((HERALD_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
