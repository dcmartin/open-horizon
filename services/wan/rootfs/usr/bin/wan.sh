#!/usr/bin/with-contenv bashio

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

## initialize horizon
hzn::init

## configure service

CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-info}'","period":"'${WAN_PERIOD:-1800}'","services":'"${SERVICES:-null}"'}'

## initialize servive
hzn::service.init ${CONFIG}

###
### MAIN
###

## initialize
OUTPUT_FILE=$(mktemp)
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

## update service
hzn::service.update "${OUTPUT_FILE}"

## iterate forever
while true; do
  DATE=$(date +%s)
  SPEEDTEST=$(speedtest --json)
  # update output
  echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"speedtest":'${SPEEDTEST:-null}'}' > "${OUTPUT_FILE}"
  hzn::service.update ${OUTPUT_FILE}
  # wait for ..
  SECONDS=$((WAN_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done

