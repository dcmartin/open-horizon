#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# more defaults for testing
if [ -z "${MQTT_HOST:-}" ]; then MQTT_HOST='mqtt'; fi
if [ -z "${MQTT_PORT:-}" ]; then MQTT_PORT=1883; fi
if [ -z "${MOTION_GROUP:-}" ]; then MOTION_GROUP='motion'; fi
if [ -z "${MOTION_CLIENT:-}" ]; then MOTION_CLIENT='+'; fi
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

## wait for image from device/camera and process
process_yolo()
{
  local device=${1}
  local camera=${2}
  local iteration=${3}
  local input_jpeg_file=$(mktemp)
  local output_jpeg=$(mktemp)
  local output_json=$(mktemp)
  local input_image_topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_PAYLOAD}"
  local output_image_topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_PAYLOAD}/${YOLO_ENTITY}"
  local output_json_topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_EVENT}/${YOLO_ENTITY}"


  ## MOCK or NOT
  if [ "${YOLO4MOTION_USE_MOCK:-}" == 'true' ]; then 
    rm -f "${JPEG_FILE}"
    touch "${JPEG_FILE}"
  else
    hzn.log.debug "Listening to ${MQTT_HOST} on topic: ${input_image_topic}"
    mosquitto_sub ${MOSQUITTO_ARGS} -C 1 -t "${input_image_topic}"  > "${input_jpeg_file}"
  fi

  hzn.log.debug "Processing image: ${input_jpeg_file}"
  yolo_json_file=$(yolo_process "${input_jpeg_file}" ${iteration})
  hzn.log.debug "Processed image: ${input_jpeg_file}; result: ${yolo_json_file}"

  # create JSON
  echo "${CONFIG}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s)'|.event='"${REPLY}" > ${output_json}

  # add two files
  jq -s add "${output_json}" "${yolo_json_file}" > "${output_json}.$$" && mv -f "${output_json}.$$" "${output_json}"

  if [ ! -s "${output_json}" ]; then
    hzn.log.error "Failed to add JSON: ${output_json} and ${yolo_json_file}"
    exit 1
  fi

  # extract JPEG from payload and publish annotated image to MQTT
  jq -r '.image' "${yolo_json_file}" | base64 --decode > ${output_jpeg}
  hzn.log.debug "Publishing JPEG: topic: ${output_image_topic}; JPEG: ${output_jpeg}"
  mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${output_image_topic}" -f ${output_jpeg}

  # send annotated event back to MQTT
  hzn.log.debug "Publishing JSON; topic: ${output_json_topic}; JSON: ${output_json}"
  mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${output_json_topic}" -f "${output_json}"
  # update status
  service_update "${output_json}"

  # cleanup
  rm -f ${input_jpeg_file} ${output_jpeg} ${yolo_json_file} ${output_json}
}

###
### MAIN
###

## initialize horizon
hzn_init

## configure service
SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
MQTT='{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"group":"'${MOTION_GROUP:-}'","device":"'${MOTION_CLIENT}'","camera":"'${YOLO4MOTION_CAMERA}'","event":"'${YOLO4MOTION_TOPIC_EVENT:-}'","old":'${YOLO4MOTION_TOO_OLD:-300}',"payload":"'${YOLO4MOTION_TOPIC_PAYLOAD}'","topic":"'${YOLO4MOTION_TOPIC}'","services":'"${SERVICES:-null}"',"mqtt":'"${MQTT}"',"yolo":'$(yolo_init)'}'

## initialize servive
service_init ${CONFIG}

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

##
# listen forever
##

mosquitto_sub ${MOSQUITTO_ARGS} -t "${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" | while read; do

  # test for null
  if [ -z "${REPLY}" ]; then 
    # null
    hzn.log.debug "Zero-length payload; continuing"
    continue
  fi
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

  hzn.log.debug "Received event from device: ${DEVICE}; camera: ${CAMERA}; JSON: ${REPLY}"

  # process YOLO
  if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
  output_json=$(process_yolo "${DEVICE}" "${CAMERA}" ${ITERATION})

done
