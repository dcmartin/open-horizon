#!/usr/bin/env bash

###
### MOTION tools
### 

export MOTION_CONF_FILE="/etc/motion/motion.conf"
export MOTION_PID_FILE="/var/run/motion/motion.pid" 
export MOTION_CMD=$(command -v motion)


KNOWN_CAMERAS='[{"name":"ps3eye","usb":"1415:2000","width":640,"height":480,"bits":8,"fov":65,"palette":8},{"name":"kinect","usb":"045e:02ae","width":640,"height":480,"bits":8,"fps":30,"fov":57,"palette":14},{"name":"c910","usb":"046d:0821","width":1280,"height":720,"bits":8,"fov":83,"fps":"30","palette":8,"aspect":"16:9","focal":{"value":43,"unit":"mm"},"vidpid":"VID_046D&PID_0821","capture":[{"aspect":"4:3","video":["320x240","640x480","1600x1200"],"image":["640x480","1280x960","2560x1920","3840x2880"]},{"aspect":"16:9","video":["480x360","858x480","1280x720","1920x1080"],"image":["480x360","858x480","1280x720","1920x1080"]}]}]'

#    "lsusb": [
#      {
#        "bus_number": "001",
#        "device_id": "001",
#        "device_bus_number": "1d6b",
#        "manufacture_id": "Bus 001 Device 001: ID 1d6b:0002",
#        "manufacture_device_name": "Bus 001 Device 001: ID 1d6b:0002"
#      },
#      {
#        "bus_number": "001",
#        "device_id": "002",
#        "device_bus_number": "80ee",
#        "manufacture_id": "Bus 001 Device 002: ID 80ee:0021",
#        "manufacture_device_name": "Bus 001 Device 002: ID 80ee:0021"
#      },
#      {
#        "bus_number": "002",
#        "device_id": "001",
#        "device_bus_number": "1d6b",
#        "manufacture_id": "Bus 002 Device 001: ID 1d6b:0003",
#        "manufacture_device_name": "Bus 002 Device 001: ID 1d6b:0003"
#      },
#      {
#        "bus_number": "001",
#        "device_id": "003",
#        "device_bus_number": "1415",
#        "manufacture_id": "Bus 001 Device 003: ID 1415:2000",
#        "manufacture_device_name": "Bus 001 Device 003: ID 1415:2000"
#      }
#    ]

hal_lsusb()
{
  lsusb=$(curl -fsSL "http://hal" 2> /dev/null | jq '.lsusb?')
  if [ -z "${lsusb:-}" ]; then lsusb='null'; fi
  echo "${lsusb}"
}

motion_usb_camera()
{
  # get all usb device
  if [[ lsusb=$(hal_lsusb) != 'null' ]]; then
    # search by manufacture identifier
    for mid in $(echo "${lsusb}" | jq -r '.[].manufacture_id'); do
      for id in $(echo "${KNOWN_CAMERAS}" | jq -r '.[].usb'); do
	usb=$(echo "${lsusb}" | jq '.[]|select(.manufacture_id|test("'${id}'")')
	if [ -z "${usb} ] || [ "${usb}" == 'null' ]; then continue; fi
	device=$(echo "${usb}" | jq -r '.manufacture_id' | sed 's/.*Device \([0-9]*\).*/\1/')
      done
    done
  fi
  echo "${device:-}"
}

motion_device()
{
  if [ -z "${MOTION_CLIENT:-}" ] || [ "${MOTION_CLIENT}" == 'default' ]; then
    if [ -z "${HZN_DEVICE_ID}" ]; then
      export MOTION_CLIENT="$(hostname)"
    else
      export MOTION_CLIENT="${HZN_DEVICE_ID}"
    fi
  fi
  echo "${MOTION_CLIENT}"
}

motion_init()
{
  # start motion
  DIR=/var/lib/motion
  TEMPDIR="${TMPDIR}/${0##*/}.$$/motion"
  rm -fr "${DIR}" "${TEMPDIR}"
  mkdir -p "${TEMPDIR}"
  ln -s "${TEMPDIR}" "${DIR}"
  # set configuration parameters
  if [ "${MOTION_THRESHOLD_TUNE:-}" == 'true' ]; then sed -i "s|.*threshold_tune.*|threshold_tune on|" "${MOTION_CONF_FILE}";fi
  if [ "${MOTION_NOISE_TUNE:-}" == 'true' ]; then sed -i "s|.*noise_tune.*|noise_tune on|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_THRESHOLD}" ]; then sed -i "s|.*threshold.*|threshold ${MOTION_THRESHOLD}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_NOISE_LEVEL}" ]; then sed -i "s|.*noise_level.*|noise_level ${MOTION_NOISE_LEVEL}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_EVENT_GAP}" ]; then sed -i "s|.*event_gap.*|event_gap ${MOTION_EVENT_GAP}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_LOG_LEVEL}" ]; then sed -i "s|.*log_level.*|log_level ${MOTION_LOG_LEVEL}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_LOG_TYPE}" ]; then sed -i "s|.*log_type.*|log_type ${MOTION_LOG_TYPE}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_FRAMERATE}" ]; then sed -i "s|.*framerate.*|framerate ${MOTION_FRAMERATE}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_LOCATE_MODE}" ]; then 
    case ${MOTION_LOCATE_MODE} in
      off)
        sed -i "s|.*locate_motion_mode.*|locate_motion_mode off|" "${MOTION_CONF_FILE}" 
        ;;
      box|cross|redbox|redcross)
        sed -i "s|.*locate_motion_mode.*|locate_motion_mode on|" "${MOTION_CONF_FILE}"
        sed -i "s|.*locate_motion_style.*|locate_motion_style ${MOTION_LOCATE_MODE}|" "${MOTION_CONF_FILE}"
	;;
      *)
	if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- MOTION_LOCATE_MODE: ${MOTION_LOCATE_MODE}" &> /dev/stderr; fi
        ;;
    esac
  fi
}

motion_pid()
{
  PID=
  if [ -s "${MOTION_PID_FILE}" ]; then
    PID=$(cat ${MOTION_PID_FILE})
  fi
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion PID: ${PID}" &> /dev/stderr; fi
  echo ${PID}
}

motion_start()
{
  PID=$(motion_pid)
  if [ -z "${PID}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- starting ${MOTION_CMD} with ${MOTION_CONF_FILE}" &> /dev/stderr; fi
    rm -f ${MOTION_PID_FILE}
    ${MOTION_CMD} -b -c "${MOTION_CONF_FILE}" &
    while [ ! -s "${MOTION_PID_FILE}" ]; do
      if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- waiting on motion" &> /dev/stderr; fi
      sleep 1
    done
    PID=$(motion_pid)
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion started ${MOTION_CMD}; PID: ${PID}" &> /dev/stderr; fi
  else
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion running ${MOTION_CMD}; PID: ${PID}" &> /dev/stderr; fi
  fi
}

motion_watchdog()
{
  WATCHDOG_CMD=$(command -v motion-watchdog.sh)
  if [ -z "${WATCHDOG_CMD}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- no motion-watchdog.sh command found" &> /dev/stderr; fi
  else
    PID=$(ps | awk '{ print $1,$4 }' | egrep "${WATCHDOG_CMD}" | awk '{ print $1 }')
    if [ -z "${PID}" ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- starting ${WATCHDOG_CMD} on ${MOTION_CMD}" &> /dev/stderr; fi
      ${WATCHDOG_CMD} ${MOTION_CMD} &
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- started ${WATCHDOG_CMD} on ${MOTION_CMD}; PID: $!" &> /dev/stderr; fi
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- ${WATCHDOG_CMD} running; PID: ${PID}" &> /dev/stderr; fi
    fi
  fi
}

##
## DATEUTILS
##

if [ -e /usr/bin/dateutils.dconv ]; then
  dateconv=/usr/bin/dateutils.dconv
elif [ -e /usr/bin/dateconv ]; then
  dateconv=/usr/bin/dateconv
elif [ -e /usr/local/bin/dateconv ]; then
  dateconv=/usr/local/bin/dateconv
else
  exit 1
fi

##
## MQTT
##

mqtt_pub()
{
  hzn::log.trace "${FUNCNAME[0]}"

  if [ -z "${MQTT_DEVICE:-}" ]; then MQTT_DEVICE=$(hostname) && hzn::log.notice "MQTT_DEVICE unspecified; using hostname: ${MQTT_DEVICE}"; fi
  ARGS=${*}
  if [ ! -z "${ARGS}" ]; then
    if [ ! -z "${MQTT_USERNAME}" ]; then
      ARGS='-u '"${MQTT_USERNAME}"' '"${ARGS}"
    fi
    if [ ! -z "${MQTT_PASSWORD}" ]; then
      ARGS='-P '"${MQTT_PASSWORD}"' '"${ARGS}"
    fi
    hzn::log.debug "mosquitto_pub -i ${MQTT_DEVICE} -h ${MQTT_HOST} -p ${MQTT_PORT} ${ARGS}"
    mosquitto_pub -i "${MQTT_DEVICE}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" ${ARGS}
  fi
}

##
## logging
##

HZN_LEVEL_EMERG=0
HZN_LEVEL_ALERT=1
HZN_LEVEL_CRIT=2
HZN_LEVEL_ERROR=3
HZN_LEVEL_WARN=4
HZN_LEVEL_NOTICE=5
HZN_LEVEL_INFO=6
HZN_LEVEL_DEBUG=7
HZN_LEVEL_TRACE=8
HZN_LEVEL_ALL=9
HZN_LEVELS=(EMERGENCY ALERT CRITICAL ERROR WARNING NOTICE INFO DEBUG TRACE ALL)
HZN_FORMAT_DEFAULT='[TIMESTAMP] LEVEL >>>'
HZN_TIMESTAMP_DEFAULT='%FT%TZ'
HZN_FORMAT="${HZN_FORMAT:-${HZN_FORMAT_DEFAULT}}"
HZN_LEVEL="${HZN_LEVEL:-${HZN_LEVEL_INFO}}"
HZN_TIMESTAMP_FORMAT="${HZN_TIMESTAMP_FORMAT:-${HZN_TIMESTAMP_DEFAULT}}"

# logging by level

hzn::log.emerg()
{
  hzn::log.logto ${HZN_LEVEL_EMERG} "${*}"
}

hzn::log.alert()
{
  hzn::log.logto ${HZN_LEVEL_ALERT} "${*}"
}

hzn::log.crit()
{
  hzn::log.logto ${HZN_LEVEL_CRIT} "${*}"
}

hzn::log.error()
{
  hzn::log.logto ${HZN_LEVEL_ERROR} "${*}"
}

hzn::log.warn()
{
  hzn::log.logto ${HZN_LEVEL_WARN} "${*}"
}

hzn::log.notice()
{
  hzn::log.logto ${HZN_LEVEL_NOTICE} "${*}"
}

hzn::log.info()
{
  hzn::log.logto ${HZN_LEVEL_INFO} "${*}"
}

hzn::log.debug()
{
  hzn::log.logto ${HZN_LEVEL_DEBUG} "${*}"
}

hzn::log.trace()
{
  hzn::log.logto ${HZN_LEVEL_TRACE} "${*}"
}

hzn::log.level()
{
  case "${HZN_LEVEL}" in
    emerg) LL=${HZN_LEVEL_EMERG} ;;
    alert) LL=${HZN_LEVEL_ALERT} ;;
    crit) LL=${HZN_LEVEL_CRIT} ;;
    error) LL=${HZN_LEVEL_ERROR} ;;
    warn) LL=${HZN_LEVEL_WARN} ;;
    notice) LL=${HZN_LEVEL_NOTICE} ;;
    info) LL=${HZN_LEVEL_INFO} ;;
    debug) LL=${HZN_LEVEL_DEBUG} ;;
    trace) LL=${HZN_LEVEL_TRACE} ;;
    *) LL=${HZN_LEVEL_ALL} ;;
  esac
  echo ${LL:-${HZN_LEVEL_ALL}}
}

hzn::log.logto()
{
  local level="${1:-0}"
  local current=$(hzn::log.level)
  local exp='^[0-9]+$'

  if ! [[ ${level} =~ ${exp} ]] ; then
   echo "hzn::log.logto: error: level ${level} not a number ${FUNCNAME}" &> ${LOGTO}
   level=
  fi
  if ! [[ ${current} =~ ${exp} ]] ; then
   echo "hzn::log.logto: error: current ${current} not a number ${FUNCNAME}" &> ${LOGTO}
   current=
  fi
  if [ "${level:-0}" -le ${current:-9} ]; then
    message="${2:-}"
    timestamp=$(date -u +"${HZN_TIMESTAMP_FORMAT}")
    output="${HZN_FORMAT}"
    output=$(echo "${output}" | sed 's/TIMESTAMP/'${timestamp}'/')
    output=$(echo "${output}" | sed 's/LEVEL/'${HZN_LEVELS[${level}]}'/')
    echo "${output} ${message}" &> ${LOGTO:-/dev/stderr}
  fi
}
