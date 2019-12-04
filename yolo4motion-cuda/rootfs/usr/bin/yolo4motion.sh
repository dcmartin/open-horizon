#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# more defaults for testing
if [ -z "${MQTT_HOST:-}" ]; then MQTT_HOST='mqtt'; fi
if [ -z "${MQTT_PORT:-}" ]; then MQTT_PORT=1883; fi
if [ -z "${MOTION_GROUP:-}" ]; then MOTION_GROUP='motion'; fi
if [ -z "${MOTION_CLIENT:-}" ]; then MOTION_CLIENT=$(hostname); fi
if [ -z "${YOLO4MOTION_CAMERA:-}" ]; then YOLO4MOTION_CAMERA='+'; fi
if [ -z "${YOLO4MOTION_TOPIC_EVENT:-}" ]; then YOLO4MOTION_TOPIC_EVENT='event/end'; fi
if [ -z "${YOLO4MOTION_TOPIC_PAYLOAD:-}" ]; then YOLO4MOTION_TOPIC_PAYLOAD='image'; fi
if [ -z "${YOLO4MOTION_TOO_OLD:-}" ]; then YOLO4MOTION_TOO_OLD=300; fi

## derived
YOLO4MOTION_TOPIC="${MOTION_GROUP}/${MOTION_CLIENT}/${YOLO4MOTION_CAMERA}"

###
### FUNCTIONS
###

source /usr/bin/yolo-tools.sh
source /usr/bin/service-tools.sh

###
### initialization
###

## initialize horizon
hzn_init

## configure service
SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
MQTT='{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"group":"'${MOTION_GROUP:-}'","device":"'${MOTION_CLIENT}'","camera":"'${YOLO4MOTION_CAMERA}'","event":"'${YOLO4MOTION_TOPIC_EVENT:-}'","old":'${YOLO4MOTION_TOO_OLD:-300}',"payload":"'${YOLO4MOTION_TOPIC_PAYLOAD}'","topic":"'${YOLO4MOTION_TOPIC}'","services":'"${SERVICES:-null}"',"mqtt":'"${MQTT}"',"yolo":'$(yolo_init)'}'

## initialize servive
service_init ${CONFIG}

###
### MAIN
###

# configure YOLO
yolo_config ${YOLO_CONFIG}

# update service status
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > ${OUTPUT_FILE}
service_update ${OUTPUT_FILE}

# MQTT arguments
MOSQUITTO_ARGS="-h ${MQTT_HOST} -p ${MQTT_PORT}"
if [ ! -z "${MQTT_USERNAME:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -u ${MQTT_USERNAME}"; fi
if [ ! -z "${MQTT_PASSWORD:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -P ${MQTT_PASSWORD}"; fi

# start in darknet
cd ${DARKNET}

hzn.log.debug "listening to ${MQTT_HOST} on topic: ${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}"

# listen forever
mosquitto_sub ${MOSQUITTO_ARGS} -t "${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" | while read; do

  # test for null
  if [ ! -z "${REPLY}" ]; then 
    DATE=$(echo "${REPLY}" | jq -r '.date')
    NOW=$(date +%s)
    if [ $((NOW - DATE)) -gt ${YOLO4MOTION_TOO_OLD} ]; then echo "+++ WARN -- $0 $$ -- too old: ${REPLY}" &> /dev/stderr; continue; fi
    DEVICE=$(echo "${REPLY}" | jq -r '.device')
    CAMERA=$(echo "${REPLY}" | jq -r '.camera')
    if [ -z "${DEVICE}" ] || [ -z "${CAMERA}" ] || [ "${DEVICE}" == 'null' ] || [ "${CAMERA}" == 'null' ]; then
      # invalid payload
      hzn.log.warn "invalid event; continuing:" $(echo "${REPLY}" | jq -c '.')
      continue
    fi
  else
    # null
    continue
  fi

  # name image payload
  JPEG_FILE="${OUTPUT_FILE%%.*}.jpeg"

  ## MOCK or NOT
  if [ "${YOLO4MOTION_USE_MOCK:-}" == 'true' ]; then 
    rm -f "${JPEG_FILE}"
    touch "${JPEG_FILE}"
  else 
    # build image topic
    TOPIC="${MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_PAYLOAD}"
    hzn.log.debug "listening to ${MQTT_HOST} on topic: ${TOPIC}"
    # get image
    mosquitto_sub ${MOSQUITTO_ARGS} -C 1 -t "${TOPIC}"  > "${JPEG_FILE}"
  fi

  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  IMAGE=$(yolo_process "${JPEG_FILE}" "${ITERATION}")

  # send annotated image back to MQTT
  TOPIC="${MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_PAYLOAD}/${YOLO_ENTITY}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- publishing to ${MQTT_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
  jq -r '.image' "${IMAGE}" | base64 --decode > "${TMPDIR}/${0##*/}.$$.jpeg"
  mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${TOPIC}" -f "${TMPDIR}/${0##*/}.$$.jpeg"
  rm -f ${JPEG_FILE}

  # initiate output
  echo "${CONFIG}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s)'|.event='"${REPLY}" > "${OUTPUT_FILE}"

  # add two files
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- IMAGE: ${IMAGE}" $(jq -c '.image=(.image!=null)' ${IMAGE}) &> /dev/stderr; fi
  jq -s add "${OUTPUT_FILE}" "${IMAGE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
  if [ -s "${OUTPUT_FILE}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- OUTPUT_FILE: ${OUTPUT_FILE}:" $(jq -c '.image=(.image!=null)|.names=(.names!=null)' "${OUTPUT_FILE}") &> /dev/stderr; fi
    # update status
    service_update "${OUTPUT_FILE}"
    # send annotated event back to MQTT
    TOPIC="${MOTION_GROUP}/${DEVICE}/${CAMERA}/${YOLO4MOTION_TOPIC_EVENT}/${YOLO_ENTITY}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- publishing to ${MQTT_HOST} on topic: ${TOPIC}" &> /dev/stderr; fi
    mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${TOPIC}" -f "${TMPDIR}/${SERVICE_LABEL}.json"
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- failed to create OUTPUT_FILE" &> /dev/stderr; fi
  fi
  rm -f "${IMAGE}"
done
