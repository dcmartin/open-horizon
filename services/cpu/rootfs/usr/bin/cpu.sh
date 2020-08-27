#!/usr/bin/with-contenv bashio

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

## source service tools
source /usr/bin/service-tools.sh

###
### MAIN
###

## initialize horizon
hzn::init

## configure service w/ defaults
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-info}'","period":"'${CPU_PERIOD:-30}'","interval":"'${CPU_INTERVAL:-1}'","services":'"${SERVICES:-null}"'}'

## initialize servive
hzn::service.init ${CONFIG}

## create initial output
OUTPUT_FILE=$(mktemp)
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
hzn::service.update "${OUTPUT_FILE}"

# iterate forever
while true; do
  DATE=$(date +%s)
  OUTPUT='{}'

  # https://github.com/Leo-G/DevopsWiki/wiki/How-Linux-CPU-Usage-Time-and-Percentage-is-calculated
  RAW=$(grep -iE '^cpu ' /proc/stat)
  CT1=$(echo "${RAW}" | awk '{ printf("%d",$2+$3+$4+$5+$6+$7+$8+$9) }')
  CI1=$(echo "${RAW}" | awk '{ printf("%d",$5+$6) }')
  sleep ${CPU_INTERVAL}
  RAW=$(grep -iE '^cpu ' /proc/stat)
  CT2=$(echo "${RAW}" | awk '{ printf("%d",$2+$3+$4+$5+$6+$7+$8+$9) }')
  CI2=$(echo "${RAW}" | awk '{ printf("%d",$5+$6) }')

  PERCENT=$(echo "scale=2; 100 * (($CT2 - $CT1) - ($CI2 - $CI1)) / ($CT2 - $CT1)" | bc -l)
  if [ -z "${PERCENT}" ]; then PERCENT=null; fi

  # output
  echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"percent":'${PERCENT:-null}'}' > "${OUTPUT_FILE}"
  # update service
  hzn::service.update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((CPU_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
