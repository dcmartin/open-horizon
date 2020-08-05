#!/usr/bin/with-contenv bashio

## tools
source /usr/bin/yolo-tools.sh
source /usr/bin/service-tools.sh

## process JSON motion event
yolo4motion::process()
{
  bashio::log.trace "${FUNCNAME[0]} ${*}"

  local payload="${1}"
  local config="${2}"
  local now="${3}"
  local sjf=$(mktemp).json
  local ijf=$(mktemp).jpeg
  local b64file=$(mktemp).b64
  local yjf
  local mqtt_args="-h ${MQTT_HOST} -p ${MQTT_PORT}"

  # configure MQTT
  if [ ! -z "${MQTT_USERNAME:-}" ]; then mqtt_args="${mqtt_args} -u ${MQTT_USERNAME}"; fi
  if [ ! -z "${MQTT_PASSWORD:-}" ]; then mqtt_args="${mqtt_args} -P ${MQTT_PASSWORD}"; fi
  
  ## initialize service JSON file
  echo "${config}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='${now} > ${sjf}
  jq -s add "${sjf}" "${payload}" > "${sjf}.$$" && mv -f "${sjf}.$$" "${sjf}"

  # extract image from payload
  jq -r '.event.image' ${payload} > ${b64file}
  if [ -s "${b64file}" ]; then
    cat ${b64file} | base64 --decode > ${ijf}
    bashio::log.debug "${FUNCNAME[0]}: decoded image; file: ${ijf}"
  else
    bashio::log.error "${FUNCNAME[0]}: zero-length BASE64-encoded image; payload:" $(jq -c '.event' ${payload})
  fi
  rm -f ${b64file}

  ## process image through yolo
  if [ -z "${ijf:-}" ] || [ ! -s "${ijf}" ]; then
    bashio::log.error "${FUNCNAME[0]} - no BASE64-decoded image; skipping"
  else
    local id=$(identify ${ijf})
    local ok=$?

    if [ "${ok:-}" == 0 ]; then
      bashio::log.debug "${FUNCNAME[0]} - processing image file: ${ijf}; id: ${id}"
      yjf=$(yolo::process ${ijf})
    else
      bashio::log.error "${FUNCNAME[0]} - invalid JPEG image: ${ijf}"
    fi
    rm -f ${ijf}
  fi

  # test for succes and publish
  if [ ! -z "${yjf:-}" ] && [ -s "${yjf}" ]; then

    ## publish annotated JPEG
    local ojf=$(mktemp).jpeg
    jq -r '.image' "${yjf}" | base64 --decode > ${ojf}
    if [ -s "${ojf}" ]; then
      local device=$(jq -r '.event.device' "${payload}")
      local camera=$(jq -r '.event.camera' "${payload}")
      local topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_PAYLOAD}/${YOLO_ENTITY}"

      mosquitto_pub -q 2 ${mqtt_args} -t "${topic}" -f ${ojf} &
      bashio::log.debug "${FUNCNAME[0]}: published JPEG; topic: ${topic}; JPEG: ${ojf}"
    else
      bashio::log.warning "${FUNCNAME[0]}: failed to publish JPEG; invalid image"
    fi
    rm -f "${ojf}"

    ## update service JSON file with yolo service output
    jq -c -s add "${sjf}" "${yjf}" > "${sjf}.$$" && mv -f "${sjf}.$$" "${sjf}"

    if [ -s "${sjf}" ]; then
      local device=$(jq -r '.event.device' "${payload}")
      local camera=$(jq -r '.event.camera' "${payload}")
      local topic="${MOTION_GROUP}/${device}/${camera}/${YOLO4MOTION_TOPIC_EVENT}/${YOLO_ENTITY}"

      mosquitto_pub -q 2 ${mqtt_args} -t "${topic}" -f "${sjf}" &
      bashio::log.info "${FUNCNAME[0]}: published JSON; topic: ${topic}; JSON: ${sjf}"
    else
      bashio::log.error "${FUNCNAME[0]}: failed to publish JSON; invalid service output"
    fi
    rm -f ${yjf}
  elif [ ! -z "${yjf:-}" ]; then
    bashio::log.error "${FUNCNAME[0]}: zero-length output"
    rm -f "${yjf}"
  else 
    bashio::log.error "${FUNCNAME[0]}: no output"
  fi

  # update service status
  hzn::service.update "${sjf}"

  # cleanup
  rm -f ${sjf}
}

## loop forever on MQTT
yolo4motion::loop()
{
  bashio::log.trace "${FUNCNAME[0]} ${*}"
  local config="${*}"
  local sjf=$(mktemp).service.json
  local payload=$(mktemp).payload.json
  local now
  local ago
  local thatdate
  local tz
  local ts
  local zn=$(date +%Z)
  local mqtt_args="-h ${MQTT_HOST} -p ${MQTT_PORT}"
  local yolo4motion_topic=${YOLO4MOTION_TOPIC:-}
  local yolo4motion_topic_event=${YOLO4MOTION_TOPIC_EVENT:-}
  local dt
  local device
  local camera
  local topic
  local message

  # configure MQTT
  if [ ! -z "${MQTT_USERNAME:-}" ]; then mqtt_args="${mqtt_args} -u ${MQTT_USERNAME}"; fi
  if [ ! -z "${MQTT_PASSWORD:-}" ]; then mqtt_args="${mqtt_args} -P ${MQTT_PASSWORD}"; fi
  
  ## announce service
  topic="service/$(hzn::service.label)/$(hostname -s)"
  message=$(echo "$(hzn::service.config)" | jq -c '.hostname="'$(hostname -s)'"')
  mosquitto_pub -r -q 2 ${mqtt_args} -t "${topic}" -m "${message}"
  bashio::log.info "${FUNCNAME[0]}: announced; host: ${MQTT_HOST}; topic: ${topic}; message: ${message}"

  ## forever process MQTT
  while true; do
    local topic=${yolo4motion_topic}/${yolo4motion_topic_event}

    # update service status
    echo "${config}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date -u +%s)'|.event=null' > ${sjf}
    hzn::service.update "${sjf}"
    bashio::log.debug "${FUNCNAME[0]}: initial service update: ${SERVICE_LABEL}; output:" $(jq -c '.' ${sjf})
  
    ## process payloads from inherent queue
    bashio::log.info "${FUNCNAME[0]}: listening; host: ${MQTT_HOST}; topic: ${topic}"
    mosquitto_sub ${mqtt_args} -t "${topic}" | while read; do

      # test for null
      if [ -z "${REPLY:-}" ]; then bashio::log.debug "${FUNCNAME[0]}: zero-length REPLY; continuing"; continue; fi

      # convert buffer to file
      echo '{"event":' > ${payload}
      echo "${REPLY}" >> "${payload}"
      echo '}' >> "${payload}"
      if [ ! -s "${payload}" ]; then
        bashio::log.warning "${FUNCNAME[0]}: invalid JSON; continuing; REPLY: ${REPLY}"
        continue
      fi
      bashio::log.debug "${FUNCNAME[0]}: received JSON; bytes:" $(wc -c ${payload} | awk '{ print $1 }')
    
      ## test for image
      if [ $(jq '.event.image!=null' ${payload}) != 'true' ]; then
        bashio::log.error "${FUNCNAME[0]}: invalid payload: no image; payload: $(cat ${payload})"
        continue
      fi
    
      ## test if too old
      ts=$(jq -r '.event.timestamp.publish' "${payload}")
      if [ "${ts:-null}" = 'null' ]; then
        bashio::log.warning "${FUNCNAME[0]}: invalid payload; no timestamp.publish:" $(jq -c '.event.image=(.event.image!=null)' ${payload})
        ts=$(jq -r '.event.timestamp' "${payload}")
        if [ "${ts:-null}" = 'null' ]; then
          bashio::log.error "${FUNCNAME[0]}: invalid payload; no event.timestamp:" $(jq -c '.event.image=(.event.image!=null)' ${payload})
          continue
        fi
      fi
      # calculate time of event in seconds since the epoch converted to local time
      thatdate=$(echo "${ts}" | dateutils.dconv -z ${zn} -f %s)
      # calculate now and difference (ago)
      now=$(date +%s) && ago=$((now - thatdate))
      # test if too old 
      if [ ${ago} -gt ${YOLO4MOTION_TOO_OLD:-300} ]; then 
        bashio::log.warning "${FUNCNAME[0]}: Too old; ${ago} > ${YOLO4MOTION_TOO_OLD:-300}; continuing; payload:" $(jq -c '.event.image=(.event.image!=null)' "${payload}")
        continue
      fi

      ## test date, camera, device
      dt=$(jq -r '.event.date' "${payload}")
      device=$(jq -r '.event.device' "${payload}")
      camera=$(jq -r '.event.camera' "${payload}")
      # test
      if [ "${dt:-null}" == 'null' ]; then
        bashio::log.error "${FUNCNAME[0]}: bad date; continuing; payload:" $(jq -c '.event.image=(.event.image!=null)' ${payload})
        continue
      elif [ "${device:-null}" == 'null' ] || [ "${camera:-null}" == 'null' ]; then
        bashio::log.error "${FUNCNAME[0]}: invalid device or camera; continuing; payload:" $(jq -c '.event.image=(.event.image!=null)' ${payload})
        continue
      else
        bashio::log.debug "${FUNCNAME[0]}: received event from device: ${device}; camera: ${camera}; ago: ${ago}"
      fi
      # process payload as motion end event
      yolo4motion::process "${payload}" "${config}" $((dt + ago))
    done
    # cleanup
  done
  rm -f ${sjf}
}

yolo4motion::options()
{
  bashio::log.trace "${FUNCNAME[0]} ${*}"
  local config="${*}"
  local result
  local options=$(jq '.' ${options})

  
}

## main function
yolo4motion::main()
{
  bashio::log.trace "${FUNCNAME[0]} ${*}"

  ## initialize service
  local init=$(yolo::init ${YOLO_CONFIG:-tiny})

  if [ ! -z "${init:-}" ]; then
    local SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
    local MQTT='{"host":"'${MQTT_HOST:-mqtt}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
    local config='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-}'","group":"'${MOTION_GROUP:-}'","client":"'${MOTION_CLIENT:-}'","camera":"'${YOLO4MOTION_CAMERA:-}'","event":"'${YOLO4MOTION_TOPIC_EVENT:-}'","old":'${YOLO4MOTION_TOO_OLD:-300}',"payload":"'${YOLO4MOTION_TOPIC_PAYLOAD:-}'","topic":"'${YOLO4MOTION_TOPIC:-}'","services":'"${SERVICES:-null}"',"mqtt":'"${MQTT}"',"'${SERVICE_LABEL}'":'${init}'}'

    hzn::service.init "${config}"
    bashio::log.info "${FUNCNAME[0]}: ${SERVICE_LABEL:-null} initialized:" $(echo "$(hzn::service.config)" | jq -c '.')

    bashio::log.info "${FUNCNAME[0]}: ${SERVICE_LABEL:-null} starting loop..."
    yolo4motion::loop ${config}
    bashio::log.error "${FUNCNAME[0]}: ${SERVICE_LABEL:-null} exiting loop"

  else
    bashio::log.error "${FUNCNAME[0]}: ${SERVICE_LABEL:-null} did not initialize"
  fi
}

###
### MAIN
###

# more defaults for testing
if [ -z "${MQTT_HOST:-}" ]; then export MQTT_HOST='mqtt'; fi
if [ -z "${MQTT_PORT:-}" ]; then export MQTT_PORT=1883; fi
if [ -z "${MOTION_GROUP:-}" ]; then export MOTION_GROUP='motion'; fi
if [ -z "${MOTION_CLIENT:-}" ]; then export MOTION_CLIENT='+'; fi
if [ -z "${YOLO4MOTION_CAMERA:-}" ]; then export YOLO4MOTION_CAMERA='+'; fi
if [ -z "${YOLO4MOTION_TOPIC_EVENT:-}" ]; then export YOLO4MOTION_TOPIC_EVENT='event/end'; fi
if [ -z "${YOLO4MOTION_TOPIC_PAYLOAD:-}" ]; then export YOLO4MOTION_TOPIC_PAYLOAD='image'; fi
if [ -z "${YOLO4MOTION_TOO_OLD:-}" ]; then export YOLO4MOTION_TOO_OLD=300; fi

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

## derived
export YOLO4MOTION_TOPIC="${MOTION_GROUP}/${MOTION_CLIENT}/${YOLO4MOTION_CAMERA}"

bashio::log.notice "Starting ${0} ${*}: ${SERVICE_LABEL:-null}"

yolo4motion::main ${*}

exit 1
