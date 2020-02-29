#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/alpr-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## initialize servive
CONFIG=$(echo $(alpr_init) | jq '.resolution="'${WEBCAM_RESOLUTION}'"|.device="'${WEBCAM_DEVICE}'"')

service_init "${CONFIG}"

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

## configure ALPR
alpr_config ${ALPR_CONFIG}

# start in alpr
cd ${OPENALPR}

if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- processing images from /dev/video0 every ${ALPR_PERIOD} seconds" &> /dev/stderr; fi

if [ -z "${WEBCAM_DEVICE}" ]; then WEBCAM_DEVICE="/dev/video0"; fi
if [ -z "${WEBCAM_RESOLUTION}" ]; then WEBCAM_RESOLUTION="384x288"; fi

while true; do
  # when we start
  DATE=$(date +%s)

  # path to image payload
  JPEG_FILE=$(mktemp -t "${0##*/}-XXXXXX")
  # capture image payload from /dev/video0
  # fswebcam --resolution "${WEBCAM_RESOLUTION}" --device "${WEBCAM_DEVICE}" --no-banner "${JPEG_FILE}" &> /dev/null
  fswebcam --device "${WEBCAM_DEVICE}" --no-banner "${JPEG_FILE}" &> /dev/null

  # process image payload into JSON
  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  ALPR_OUTPUT_FILE=$(alpr_process "${JPEG_FILE}" "${ITERATION}")

  # remove
  rm -f ${JPEG_FILE}

  if [ -s "${ALPR_OUTPUT_FILE}" ]; then
    # add two files
    jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) "${ALPR_OUTPUT_FILE}" > "${OUTPUT_FILE}"
    # update
  else
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- nothing seen" &> /dev/stderr; fi
  fi
  # update
  service_update "${OUTPUT_FILE}"

  # wait for ..
  SECONDS=$((ALPR_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- sleep ${SECONDS}" &> /dev/stderr; fi
    sleep ${SECONDS}
  fi
done
