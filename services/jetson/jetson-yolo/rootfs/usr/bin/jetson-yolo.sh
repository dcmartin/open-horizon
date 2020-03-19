#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# source yolo functions
source /usr/bin/yolo-tools.sh

# configure YOLO
CONFIG=$(yolo_init)
yolo_config ${YOLO_CONFIG}

# update service status
echo "${CONFIG}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) > ${TMPDIR}/$$
mv -f ${TMPDIR}/$$ ${TMPDIR}/${SERVICE_LABEL}.json

# start in darknet
cd ${DARKNET}

if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- processing images from /dev/video0 every ${YOLO_PERIOD} seconds" &> /dev/stderr; fi

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
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- JSON_FILE: ${JSON_FILE}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${JSON_FILE}") &> /dev/stderr; fi

    # add two files
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- YOLO_JSON_FILE: ${YOLO_JSON_FILE}" $(jq -c '.image=(.image!=null)' ${YOLO_JSON_FILE}) &> /dev/stderr; fi
    jq -s add "${JSON_FILE}" "${YOLO_JSON_FILE}" > "${JSON_FILE}.$$" && mv -f "${JSON_FILE}.$$" "${JSON_FILE}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- JSON_FILE: ${JSON_FILE}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${JSON_FILE}") &> /dev/stderr; fi

    # make it atomic
    if [ -s "${JSON_FILE}" ]; then
      mv -f "${JSON_FILE}" "${TMPDIR}/${SERVICE_LABEL}.json"
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- ${TMPDIR}/${SERVICE_LABEL}.json:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${TMPDIR}/${SERVICE_LABEL}.json") &> /dev/stderr; fi
    fi
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- nothing seen" &> /dev/stderr; fi
  fi

  # wait for ..
  SECONDS=$((YOLO_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- sleep ${SECONDS}" &> /dev/stderr; fi
    sleep ${SECONDS}
  fi

done
