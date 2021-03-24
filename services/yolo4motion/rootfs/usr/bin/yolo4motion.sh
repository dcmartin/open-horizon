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

## process JSON motion event
process_motion_event()
{
  hzn.log.debug "${FUNCNAME[0]} ${*}"

  local payload="${1}"
  local config="${2}"
  local now="${3}"

  local service_json_file=$(mktemp).json

  local input_jpeg_file
  local yolo_json_file

  hzn.log.debug "${FUNCNAME[0]} - initializing service update"
  echo "${config}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='${now} > ${service_json_file}

  # update service status
  service_update "${service_json_file}"

  hzn.log.debug "${FUNCNAME[0]} - adding event to service status"
  jq -s add "${service_json_file}" "${payload}" > "${service_json_file}.$$" && mv -f "${service_json_file}.$$" "${service_json_file}"

  hzn.log.debug "${FUNCNAME[0]} - decoding image provided in motion event"
  local b64file=$(mktemp).b64
  jq -r '.event.image' ${payload} > ${b64file}
  if [ -s "${b64file}" ]; then
    input_jpeg_file=$(mktemp).jpeg
    cat ${b64file} | base64 --decode > ${input_jpeg_file}
  else
    hzn.log.error "${FUNCNAME[0]} - zero-length BASE64-encoded image: $(jq -c '.event' ${payload})"
  fi
  rm -f ${b64file}

  if [ -z "${input_jpeg_file:-}" ] || [ ! -s "${input_jpeg_file}" ]; then
    hzn.log.error "${FUNCNAME[0]} - no BASE64-decoded image; skipping"
  else
    local id=$(identify ${input_jpeg_file})
    local ok=$?

    if [ "${ok:-}" == 0 ]; then
      hzn.log.debug "${FUNCNAME[0]} - processing image file: ${input_jpeg_file}; id: ${id}"
      yolo_json_file=$(yolo_process ${input_jpeg_file})
    else
      hzn.log.error "${FUNCNAME[0]} - invalid JPEG image: ${input_jpeg_file}"
    fi
    rm -f ${input_jpeg_file}
  fi

  if [ -z "${yolo_json_file:-}" ] || [ ! -s "${yolo_json_file}" ]; then
    hzn.log.error "${FUNCNAME[0]} - no YOLO output; skipping"
  else
    ## IMAGE
    hzn.log.debug "${FUNCNAME[0]} - extracting annotated image from JSON: ${yolo_json_file}"
    local output_jpeg=$(mktemp).jpeg
    jq -r '.image' "${yolo_json_file}" | base64 --decode > ${output_jpeg}
    if [ -s "${output_jpeg}" ]; then
      local device=$(jq -r '.event.device' "${payload}")
      local camera=$(jq -r '.event.camera' "${payload}")
      local topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_PAYLOAD}/${YOLO_ENTITY}"

      # publish image
      hzn.log.debug "${FUNCNAME[0]} - publishing JPEG; topic: ${topic}; JPEG: ${output_jpeg}"
      mosquitto_pub -q 2 ${MOSQUITTO_ARGS} -t "${topic}" -f ${output_jpeg}
    else
      hzn.log.error "${FUNCNAME[0]} - zero-length output JPEG file"
    fi
    rm -f "${output_jpeg}"

    ## EVENT
    hzn.log.debug "${FUNCNAME[0]} - combine YOLO output with service configuration file"
    jq -c -s add "${service_json_file}" "${yolo_json_file}" > "${service_json_file}.$$" && mv -f "${service_json_file}.$$" "${service_json_file}"
    if [ -s "${service_json_file}" ]; then
      local device=$(jq -r '.event.device' "${payload}")
      local camera=$(jq -r '.event.camera' "${payload}")
      local topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_EVENT}/${YOLO_ENTITY}"

      # publish event
      hzn.log.debug "${FUNCNAME[0]} - publishing event JSON; topic: ${topic}; JSON: ${service_json_file}"
      mosquitto_pub -q 2 ${MOSQUITTO_ARGS} -t "${topic}" -f "${service_json_file}"
    else
      hzn.log.error "Failed to add JSON: ${service_json_file} and ${yolo_json_file}"
    fi
    rm -f ${yolo_json_file}
  fi

  rm -f ${service_json_file}
}

###
### MAIN
###

## initialize horizon
hzn_init

## define service(s)
SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
MQTT='{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"group":"'${MOTION_GROUP:-}'","client":"'${MOTION_CLIENT}'","camera":"'${YOLO4MOTION_CAMERA}'","event":"'${YOLO4MOTION_TOPIC_EVENT:-}'","old":'${YOLO4MOTION_TOO_OLD:-300}',"payload":"'${YOLO4MOTION_TOPIC_PAYLOAD}'","topic":"'${YOLO4MOTION_TOPIC}'","services":'"${SERVICES:-null}"',"mqtt":'"${MQTT}"',"yolo":'$(yolo_init ${YOLO_CONFIG})'}'

## initialize servive
service_init ${CONFIG}

##
# main
##

# start in darknet
cd ${DARKNET}

## listen forever
while true; do


  # update service status
  SERVICE_JSON_FILE=$(mktemp).json
  echo "${CONFIG}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date -u +%s)'|.event=null' > ${SERVICE_JSON_FILE}
  service_update "${SERVICE_JSON_FILE}"
  
  # configure MQTT
  MOSQUITTO_ARGS="-h ${MQTT_HOST} -p ${MQTT_PORT}"
  if [ ! -z "${MQTT_USERNAME:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -u ${MQTT_USERNAME}"; fi
  if [ ! -z "${MQTT_PASSWORD:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -P ${MQTT_PASSWORD}"; fi
  hzn.log.notice "Listening to MQTT host: ${MQTT_HOST}; topic: ${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}"

  # build topic from in-coming topic
  topic="${YOLO4MOTION_TOPIC#*/}" && topic="${topic%%/*}" && topic="service/${SERVICE_LABEL}/${topic}"
  
  ## announce service
  ipaddr=$(ip addr | egrep -A4 UP | egrep 'inet ' | egrep -v 'scope host lo' | egrep -v 'scope global docker' | awk '{ print $2 }')
  message=$(echo "$(service_config)" | jq -c '.hostname="'$(hostname -s)'"|.ipaddr="'${ipaddr}'"')
  mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${topic}" -m "${message}"
  hzn.log.notice "Announced on MQTT: ${MOSQUITTO_ARGS}; topic: ${topic}; message: ${message}"

  mosquitto_sub ${MOSQUITTO_ARGS} -t "${YOLO4MOTION_TOPIC}/${YOLO4MOTION_TOPIC_EVENT}" | while read; do
  
    # test for null
    if [ -z "${REPLY:-}" ]; then 
      hzn.log.debug "Zero-length REPLY; continuing"
      continue
    else
      PAYLOAD=$(mktemp).json
      echo '{"event":' > ${PAYLOAD}
      echo "${REPLY}" >> "${PAYLOAD}"
      echo '}' >> "${PAYLOAD}"
    fi
    if [ ! -s "${PAYLOAD}" ]; then
      hzn.log.debug "Invalid JSON; continuing; REPLY: ${REPLY}"
      continue
    else
      hzn.log.debug "Received JSON; bytes:" $(wc -c ${PAYLOAD} | awk '{ print $1 }')
    fi
  
    # check for image
    if [ $(jq '.event.image!=null' ${PAYLOAD}) != 'true' ]; then
      hzn.log.error "INVALID PAYLOAD: no image; payload: $(cat ${PAYLOAD})"
      continue
    fi
  
    # check timestamp
    THISZONE=$(date +%Z)
    TIMESTAMP=$(jq -r '.event.timestamp.publish' "${PAYLOAD}")
    if [ "${TIMESTAMP:-null}" = 'null' ]; then
      hzn.log.warn "INVALID PAYLOAD; no timestamp.publish: $(jq -c '.event.image=(.event.image!=null)' ${PAYLOAD})"
      TIMESTAMP=$(jq -r '.event.timestamp' "${PAYLOAD}")
      if [ "${TIMESTAMP:-null}" = 'null' ]; then
        hzn.log.error "INVALID PAYLOAD; no event.timestamp: $(jq -c '.event.image=(.event.image!=null)' ${PAYLOAD})"
        continue
      fi
    fi
  
    hzn.log.debug "Timezone: ${THISZONE}; Timestamp: ${TIMESTAMP}"
    THATDATE=$(echo "${TIMESTAMP}" | dateutils.dconv -z ${THISZONE} -f %s)
  
    # calculate ago and age
    NOW=$(date +%s) && AGO=$((NOW - THATDATE))
  
    # test if too old
    if [ ${AGO} -gt ${YOLO4MOTION_TOO_OLD} ]; then 
      hzn.log.warn "Too old; ${AGO} > ${YOLO4MOTION_TOO_OLD}; continuing; PAYLOAD:" $(jq -c '.event.image=="redacted"' "${PAYLOAD}")
      continue
    fi
  
    # update date
    device=$(jq -r '.event.device' "${PAYLOAD}")
    camera=$(jq -r '.event.camera' "${PAYLOAD}")
    DATE=$(jq -r '.event.date' "${PAYLOAD}")
  
    if [ -z "${DATE:-}" ] || [ "${DATE:-}" == 'null' ]; then
      hzn.log.error "Bad date; continuing; PAYLOAD:" $(jq -c '.' "${PAYLOAD}")
      continue
    elif [ -z "${device}" ] || [ -z "${camera}" ] || [ "${device}" == 'null' ] || [ "${camera}" == 'null' ]; then
      hzn.log.error "Invalid device or camera; continuing; JSON:" $(jq -c '.' "${PAYLOAD}")
      continue
    else
      hzn.log.debug "Received event from device: ${device}; camera: ${camera}; AGO: ${AGO}"
      DATE=$((DATE + AGO))
    fi
  
    # process PAYLOAD as motion end event
    process_motion_event "${PAYLOAD}" "${CONFIG}" ${DATE}
    rm -f ${PAYLOAD}
  
  done
  rm -f ${SERVICE_JSON_FILE}

done

