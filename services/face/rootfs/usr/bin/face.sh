#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/face-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## initialize servive
CONFIG=$(echo $(face_init) | jq '.resolution="'${WEBCAM_RESOLUTION}'"|.device="'${WEBCAM_DEVICE}'"')

service_init "${CONFIG}"

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

## configure FACE
face_config ${FACE_CONFIG:-}

# start in face
cd ${OPENFACE}

hzn::log.notice "processing images from /dev/video0 every ${FACE_PERIOD} seconds"

if [ -z "${WEBCAM_DEVICE}" ]; then WEBCAM_DEVICE="/dev/video0"; fi
if [ -z "${WEBCAM_RESOLUTION}" ]; then WEBCAM_RESOLUTION="320x240"; fi

while true; do
  # when we start
  DATE=$(date +%s)

  # path to image payload
  JPEG_FILE=$(mktemp -t "${0##*/}-XXXXXX")
  # capture image payload from /dev/video0
  # fswebcam --resolution "${WEBCAM_RESOLUTION}" --device "${WEBCAM_DEVICE}" --no-banner "${JPEG_FILE}" &> /dev/null

  hzn::log.debug "Attempting to capture image"
  fswebcam --device "${WEBCAM_DEVICE}" --no-banner "${JPEG_FILE}" &> /dev/null

  # process image payload into JSON
  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  FACE_OUTPUT_FILE=$(face_process "${JPEG_FILE}" "${ITERATION}")

  # remove
  rm -f ${JPEG_FILE}

  if [ -s "${FACE_OUTPUT_FILE}" ]; then
    # add two files
    jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) "${FACE_OUTPUT_FILE}" > "${OUTPUT_FILE}"
    # update
  else
    hzn::log.error "No output"
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
  fi
  # update
  service_update "${OUTPUT_FILE}"

  # wait for ..
  SECONDS=$((FACE_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    hzn::log.debug "sleep ${SECONDS}"
    sleep ${SECONDS}
  fi
done
