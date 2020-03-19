#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/yolo-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## initialize servive
service_init $(yolo_init)

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

## configure YOLO
yolo_config ${YOLO_CONFIG}

# start in darknet
cd ${DARKNET}

if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- processing images from /dev/video0 every ${YOLO_PERIOD} seconds" &> /dev/stderr; fi

while true; do
  # when we start
  DATE=$(date +%s)

  # path to image payload
  JPEG_FILE="${TMPDIR}/${0##*/}.$$.jpg"
  # capture image payload from /dev/video0
  fswebcam --no-banner "${JPEG_FILE}" &> /dev/null

  # process image payload into JSON
  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  YOLO_JSON_FILE=$(yolo_process "${JPEG_FILE}" "${ITERATION}")

  if [ -s "${YOLO_JSON_FILE}" ]; then
    # initialize output with configuration
    JSON_FILE="${TMPDIR}/${0##*/}.$$.json"
    echo "${CONFIG}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s)'|.entity="'${YOLO_ENTITY}'"' > "${JSON_FILE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- JSON_FILE: ${JSON_FILE}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${JSON_FILE}") &> /dev/stderr; fi

    # add two files
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- YOLO_JSON_FILE: ${YOLO_JSON_FILE}" $(jq -c '.image=(.image!=null)' ${YOLO_JSON_FILE}) &> /dev/stderr; fi
    jq -s add "${JSON_FILE}" "${YOLO_JSON_FILE}" > "${JSON_FILE}.$$" && mv -f "${JSON_FILE}.$$" "${JSON_FILE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- JSON_FILE: ${JSON_FILE}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${JSON_FILE}") &> /dev/stderr; fi

    # make it atomic
    if [ -s "${JSON_FILE}" ]; then
      service_update "${JSON_FILE}"
    fi
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- nothing seen" &> /dev/stderr; fi
  fi

  # wait for ..
  SECONDS=$((YOLO_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- sleep ${SECONDS}" &> /dev/stderr; fi
    sleep ${SECONDS}
  fi

done
