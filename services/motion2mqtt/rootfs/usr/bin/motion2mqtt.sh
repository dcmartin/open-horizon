#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

## timezone
set_timezone()
{
  TZ=${1}
  ZONEINFO="/usr/share/zoneinfo/${TZ}"
  if [ -e "${ZONEINFO}" ]; then
    cp "${ZONEINFO}" /etc/localtime
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- zoneinfo: ${ZONEINFO}" >> ${LOGTO} 2>&1; fi
  else
    echo "+++ WARN $0 $$ -- cannot locate time zone: ${TZ}" >> ${LOGTO} 2>&1
    ZONEINFO=
  fi
  echo "${ZONEINFO}"
}

## Bus 001 Device 004: ID 046d:0821 Logitech, Inc. HD Webcam C910
## Bus 001 Device 004: ID 1415:2000 Nam Tai E&E Products Ltd. or OmniVision Technologies, Inc. Sony Playstation Eye

###
### FUNCTIONS
###

source /usr/bin/motion-tools.sh
source /usr/bin/service-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## configure service

CONFIG_SERVICES='[{"name":"cpu","url":"http://cpu"},{"name":"mqtt","url":"http://mqtt"},{"name":"hal","url":"http://hal"}]'
CONFIG_MQTT='{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
CONFIG_MOTION='{"post_pictures":"'${MOTION_POST_PICTURES:-best}'","locate_mode":"'${MOTION_LOCATE_MODE:-off}'","event_gap":'${MOTION_EVENT_GAP:-60}',"framerate":'${MOTION_FRAMERATE:-5}',"threshold":'${MOTION_THRESHOLD:-5000}',"threshold_tune":'${MOTION_THRESHOLD_TUNE:-false}',"noise_level":'${MOTION_NOISE_LEVEL:-0}',"noise_tune":'${MOTION_NOISE_TUNE:-false}',"log_level":'${MOTION_LOG_LEVEL:-9}',"log_type":"'${MOTION_LOG_TYPE:-all}'"}'
CONFIG_SERVICE='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"group":"'${MOTION_GROUP:-}'","device":"'$(motion_device)'","timezone":"'$(set_timezone ${MOTION_TIMEZONE:-})'","services":'"${CONFIG_SERVICES}"',"mqtt":'"${CONFIG_MQTT}"',"motion":'"${CONFIG_MOTION}"'}'

## initialize servive
service_init ${CONFIG_SERVICE}

## initialize motion
motion_init ${CONFIG_MOTION}

## start motion
motion_start
if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion started; PID:" $(motion_pid) >> ${LOGTO} 2>&1; fi

## start motion watchdog
motion_watchdog
if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion watchdog started" >> ${LOGTO} 2>&1; fi

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":"'$(date +%s)'"}' > "${OUTPUT_FILE}"


## set directory to watch
DIR=/var/lib/motion

## forever
while true; do 
  # update service
  service_update ${OUTPUT_FILE}
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- waiting on directory: ${DIR}" >> ${LOGTO} 2>&1; fi
  # wait (forever) on changes in ${DIR}
  inotifywait -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- inotifywait ${FULLPATH}" >> ${LOGTO} 2>&1; fi
    if [ ! -z "${FULLPATH}" ]; then 
      # process updates
      case "${FULLPATH##*/}" in
	*-*-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    # don't update always
	    if [ "${MOTION_POST_PICTURES}" == 'all' ]; then
	      jq '.motion.image='"${OUT}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	      IMAGE_PATH="${FULLPATH%.*}.jpg"
	      if [ -s "${IMAGE_PATH}" ]; then
		IMG_B64_FILE="${TMPDIR}/${IMAGE_PATH##*/}"; IMG_B64_FILE="${IMG_B64_FILE%.*}.b64"
		base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"image":{"base64":"\1"}}}|' > "${IMG_B64_FILE}"
	      fi
	    fi
	  else
	    echo "+++ WARN $0 $$ -- no content in ${FULLPATH}; continuing..." >> ${LOGTO} 2>&1
	    continue
	  fi
	  if [ "${MOTION_POST_PICTURES}" != 'all' ]; then 
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}: posting ONLY ${MOTION_POST_PICTURES} picture; continuing..." >> ${LOGTO} 2>&1; fi
	    continue
	  fi
	  ;;
	*-*.json)
	  if [ -s "${FULLPATH}" ]; then
	    OUT=$(jq '.' "${FULLPATH}")
	    if [ -z "${OUT}" ]; then OUT='null'; fi
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT:" $(echo "${OUT}" | jq -c .) >> ${LOGTO} 2>&1; fi
	  else
	    echo "+++ WARN $0 $$ -- EVENT: no content in ${FULLPATH}" >> ${LOGTO} 2>&1
	    continue
	  fi
	  # test for end
	  IMAGES=$(jq -r '.images[]?' "${FULLPATH}")
	  if [ -z "${IMAGES}" ] || [ "${IMAGES}" == 'null' ]; then 
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}: EVENT start; continuing..." >> ${LOGTO} 2>&1; fi
	    continue
	  else
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}: EVENT end" >> ${LOGTO} 2>&1; fi
	    # update event
	    jq '.motion.event='"${OUT}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT: updated ${OUTPUT_FILE} with event JSON:" $(echo "${OUT}" | jq -c) >> ${LOGTO} 2>&1; fi
	    # check for GIF
	    IMAGE_PATH="${FULLPATH%.*}.gif"
	    if [ -s "${IMAGE_PATH}" ]; then
	      GIF_B64_FILE="${TMPDIR}/${IMAGE_PATH##*/}"; GIF_B64_FILE="${GIF_B64_FILE%.*}.b64"
	      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- EVENT: found GIF: ${IMAGE_PATH}; creating ${GIF_B64_FILE}" >> ${LOGTO} 2>&1; fi
	      base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"event":{"base64":"\1"}}}|' > "${GIF_B64_FILE}"
	    fi
	    rm -f "${IMAGE_PATH}"
	    # find posted picture
	    POSTED_IMAGE_JSON=$(jq -r '.image?' "${FULLPATH}")
	    if [ ! -z "${POSTED_IMAGE_JSON}" ] && [ "${POSTED_IMAGE_JSON}" != 'null' ]; then
	      PID=$(echo "${POSTED_IMAGE_JSON}" | jq -r '.id?')
	      if [ ! -z "${PID}" ] && [ "${PID}" != 'null' ]; then
		IMAGE_PATH="${FULLPATH%/*}/${PID}.jpg"
		if [ -s  "${IMAGE_PATH}" ]; then
		  IMG_B64_FILE="${TMPDIR}/${IMAGE_PATH##*/}"; IMG_B64_FILE="${IMG_B64_FILE%.*}.b64"
		  base64 -w 0 "${IMAGE_PATH}" | sed -e 's|\(.*\)|{"motion":{"image":{"base64":"\1"}}}|' > "${IMG_B64_FILE}"
		fi
	      fi
	      rm -f "${IMAGE_PATH}"
	      # update output to posted image
	      jq '.motion.image='"${POSTED_IMAGE_JSON}" "${OUTPUT_FILE}" > "${OUTPUT_FILE}.$$" && mv -f "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
	    fi
	    # cleanup
	    find "${FULLPATH%/*}" -name "${FULLPATH%.*}*" -print | xargs rm -f
	  fi
	  ;;
	*)
	  if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${FULLPATH}; continuing..." >> ${LOGTO} 2>&1; fi
	  continue
	  ;;
      esac
    else
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- timeout" >> ${LOGTO} 2>&1; fi
    fi
    # merge image base64 iff exists
    if [ ! -z "${IMG_B64_FILE:-}" ] && [ -s "${IMG_B64_FILE}" ]; then
      if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${IMG_B64_FILE}" >> ${LOGTO} 2>&1; fi
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${IMG_B64_FILE}" > "${OUTPUT_FILE}.$$" && mv "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
      rm -f "${IMG_B64_FILE}"
      IMG_B64_FILE=
    fi
    # merge GIF base64 iff exists
    if [ ! -z "${GIF_B64_FILE:-}" ] && [ -s "${GIF_B64_FILE}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found ${GIF_B64_FILE}" >> ${LOGTO} 2>&1; fi
      jq -s 'reduce .[] as $item ({}; . * $item)' "${OUTPUT_FILE}" "${GIF_B64_FILE}" > "${OUTPUT_FILE}.$$" && mv "${OUTPUT_FILE}.$$" "${OUTPUT_FILE}"
      rm -f "${GIF_B64_FILE}"
      GIF_B64_FILE=
    fi
    # update output
    service_update ${OUTPUT_FILE}
  done 
done

exit 1
