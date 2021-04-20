#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# more defaults for testing
if [ -z "${MQTT_HOST:-}" ]; then MQTT_HOST='mqtt'; fi
if [ -z "${MQTT_PORT:-}" ]; then MQTT_PORT=1883; fi
if [ -z "${MOTION_GROUP:-}" ]; then MOTION_GROUP='motion'; fi
if [ -z "${MOTION_CLIENT:-}" ]; then MOTION_CLIENT='+'; fi
if [ -z "${FACE4MOTION_CAMERA:-}" ]; then FACE4MOTION_CAMERA='+'; fi
if [ -z "${FACE4MOTION_TOPIC_EVENT:-}" ]; then FACE4MOTION_TOPIC_EVENT='event/end'; fi
if [ -z "${FACE4MOTION_TOPIC_PAYLOAD:-}" ]; then FACE4MOTION_TOPIC_PAYLOAD='image'; fi
if [ -z "${FACE4MOTION_TOO_OLD:-}" ]; then FACE4MOTION_TOO_OLD=300; fi

## derived
FACE4MOTION_TOPIC="${MOTION_GROUP}/${MOTION_CLIENT}/${FACE4MOTION_CAMERA}"

###
### FUNCTIONS
###

source /usr/bin/face-tools.sh
source /usr/bin/service-tools.sh

## process JPEG image through FACE
process_face()
{
  hzn.log.debug "${FUNCNAME[0]} ${*}"

  local input_jpeg_file=${1}
  local face_json_file=$(face_process "${input_jpeg_file}")

  echo "${face_json_file:-}"
}


## process JSON motion event
process_motion_event()
{
  hzn.log.debug "${FUNCNAME[0]} ${*}"

  local payload="${1}"
  local config="${2}"
  local now="${3}"
  local device=$(jq -r '.event.device' "${payload}")
  local camera=$(jq -r '.event.camera' "${payload}")
  local service_json_file=$(mktemp)
  local input_jpeg_file=$(mktemp)
  local face_json_file

  # create service update
  echo "${config}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='${now} > ${service_json_file}

  # update service status
  service_update "${service_json_file}"

  hzn.log.debug "Decoding image provided in motion event"
  jq -r '.event.image' ${payload} | base64 --decode > "${input_jpeg_file}"

  # add event to service status
  jq -s add "${service_json_file}" "${payload}" > "${service_json_file}.$$" && mv -f "${service_json_file}.$$" "${service_json_file}"

  # process image
  face_json_file=$(process_face "${input_jpeg_file}")

  if [ -s "${face_json_file}" ]; then

    # extract image
    local output_jpeg=$(mktemp)
    jq -r '.image' "${face_json_file}" | base64 --decode > ${output_jpeg}
    if [ -s "${output_jpeg}" ]; then
      local topic="${MOTION_GROUP}/${device}/${camera}/${FACE4MOTION_TOPIC_PAYLOAD%%/*}/face/${FACE_PATTERN:-all}"
      hzn.log.debug "Publishing JPEG; topic: ${topic}; JPEG: ${output_jpeg}"
      mosquitto_pub -q 2 ${MOSQUITTO_ARGS} -t "${topic}" -f ${output_jpeg}
    else
      hzn.log.error "Zero-length output JPEG file"
    fi
    rm -f "${output_jpeg}"

    # combine FACE output with service configuration file
    jq -s add "${service_json_file}" "${face_json_file}" > "${service_json_file}.$$" && mv -f "${service_json_file}.$$" "${service_json_file}"
    # test for success
    if [ -s "${service_json_file}" ]; then
      local topic="${MOTION_GROUP}/${device}/${camera}/${FACE4MOTION_TOPIC_EVENT%%/*}/face/${FACE_PATTERN:-all}"
      hzn.log.debug "Publishing JSON; topic: ${topic}; JSON: ${service_json_file}"
      mosquitto_pub -q 2 ${MOSQUITTO_ARGS} -t "${topic}" -f "${service_json_file}"
    else
      hzn.log.error "Failed to add JSON: ${service_json_file} and ${face_json_file}"
    fi

  else
    hzn.log.error "Zero-length output JSON file"
  fi

  # cleanup
  rm -f ${payload} ${input_jpeg_file} ${face_json_file} ${service_json_file}
}

###
### MAIN
###

## initialize horizon
hzn_init

## define service(s)
SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
MQTT='{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"group":"'${MOTION_GROUP:-}'","client":"'${MOTION_CLIENT}'","camera":"'${FACE4MOTION_CAMERA}'","event":"'${FACE4MOTION_TOPIC_EVENT:-}'","old":'${FACE4MOTION_TOO_OLD:-300}',"payload":"'${FACE4MOTION_TOPIC_PAYLOAD}'","topic":"'${FACE4MOTION_TOPIC}'","services":'"${SERVICES:-null}"',"mqtt":'"${MQTT}"',"face":'$(face_init)'}'

## initialize servive
service_init ${CONFIG}

# configure FACE
face_config ${FACE_COUNTRY:-}

##
# main
##

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

  ## announce service
  ipaddr=$(ip addr | egrep -A4 UP | egrep 'inet ' | egrep -v 'scope host lo' | egrep -v 'scope global docker' | awk '{ print $2 }')
  message=$(echo "$(service_config)" | jq -c '.hostname="'$(hostname -s)'"|.ipaddr="'${ipaddr%%/*}'"')
  topic="service/$(service_label)/$(hostname -s)"
  mosquitto_pub -r -q 2 ${MOSQUITTO_ARGS} -t "${topic}" -m "${message}"
  hzn.log.notice "Announced on MQTT: ${MOSQUITTO_ARGS}; topic: ${topic}; message: ${message}"

  ## listen forever
  mosquitto_sub ${MOSQUITTO_ARGS} -t "${FACE4MOTION_TOPIC}/${FACE4MOTION_TOPIC_EVENT}" | while read; do

    # test for null
    if [ -z "${REPLY:-}" ]; then 
      hzn.log.debug "Zero-length REPLY; continuing"
      continue
    else
      PAYLOAD=$(mktemp)
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
    if [ ${AGO} -gt ${FACE4MOTION_TOO_OLD} ]; then 
      hzn.log.warn "Too old; ${AGO} > ${FACE4MOTION_TOO_OLD}; continuing; PAYLOAD:" $(jq -c '.event.image=="redacted"' "${PAYLOAD}")
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

  done
  rm -f ${SERVICE_JSON_FILE}
done
