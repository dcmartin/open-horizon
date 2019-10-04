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

CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-info}'","debug":'${DEBUG:-false}',"period":"'${HAL_PERIOD:-1800}'","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

while true; do
  DATE=$(date +%s)
  OUTPUT=$(jq -c '.' "${OUTPUT_FILE}")

  for ls in lshw lsusb lscpu lspci lsblk lsdf; do
    OUT="$(${ls}.sh | jq '.'${ls}'?')"
    if [ ${DEBUG:-} == 'true' ]; then echo "${ls} == ${OUT}" &> /dev/stderr; fi
    if [ -z "${OUT:-}" ]; then OUT=null; fi
    OUTPUT=$(echo "$OUTPUT" | jq '.'${ls}'='"${OUT}")
    if [ ${DEBUG:-} == 'true' ]; then echo "OUTPUT == ${OUTPUT}" &> /dev/stderr; fi
  done

  echo "${OUTPUT}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) > "${OUTPUT_FILE}"
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((HAL_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
