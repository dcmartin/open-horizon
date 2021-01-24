#!/usr/bin/with-contenv bashio

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/yolo-tools.sh

yolo::loop()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local jpeg=$(mktemp).jpg
  local output=$(mktemp).json
  local seconds
  local iteration

  ## initialize
  echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${output}"
  
  while true; do
      # when we start
      local DATE=$(date +%s)
      local yolo
  
      # get image from camera device
      fswebcam --device "${WEBCAM_DEVICE}" --no-banner "${jpeg}" &> /dev/null
      if [ ! -s "${jpeg}" ]; then hzn::log.warning "${FUNCNAME[0]}: no image captured"; fi
  
      # process image payload into JSON
      if [ -z "${iteration:-}" ]; then iteration=0; else iteration=$((iteration+1)); fi
      yolo=$(yolo::process "${jpeg}" "${iteration}")
      if [ -s "${yolo}" ]; then
        hzn::log.debug "${FUNCNAME[0]}: YOLO success; output: ${yolo}"
        jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) "${yolo}" > "${output}"
      else
        hzn::log.warning "${FUNCNAME[0]}: no YOLO output"
        echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${output}"
      fi
  
      # update
      hzn::service.update "${output}"
  
      # wait for ..
      seconds=$((YOLO_PERIOD - $(($(date +%s) - DATE))))
      if [ ${seconds} -gt 0 ]; then
        hzn::log.debug "${FUNCNAME[0]}: sleeping for ${seconds} seconds"
        sleep ${seconds}
      fi
  done
}

yolo::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  ## initialize service
  local init=$(yolo::init ${YOLO_CONFIG:-tiny})

  if [ ! -z "${init:-}" ]; then
    local config='{"log_level":"'${SERVICE_LOG_LEVEL:-}'", "timestamp":"'$(date -u +%FT%TZ)'", "date":'$(date +%s)',"'${SERVICE_LABEL}'":'${init}',"services":'"${SERVICES:-null}"'}'

    hzn::log.notice "${FUNCNAME[0]}: initializing service: ${SERVICE_LABEL:-}" $(echo "${config}" | jq -c '.' || echo "INVALID: ${config}")
    hzn::service.init "${config}"

    hzn::log.info "${FUNCNAME[0]}: ${SERVICE_LABEL:-null} starting loop..."
    yolo::loop
    hzn::log.error "${FUNCNAME[0]}: ${SERVICE_LABEL:-null} exiting loop"

  else
    hzn::log.error "${FUNCNAME[0]}: YOLO did not initialize"
  fi
}

###
### MAIN
###

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

# test
if [ -z "${DARKNET:-}" ]; then hzn::log.error "${0}: DARKNET unspecified; set environment variable for testing"; fi

# defaults for testing
if [ -z "${YOLO_PERIOD:-}" ]; then export YOLO_PERIOD=0; fi
if [ -z "${YOLO_ENTITY:-}" ]; then export YOLO_ENTITY=person; fi
if [ -z "${YOLO_THRESHOLD:-}" ]; then export YOLO_THRESHOLD=0.25; fi
if [ -z "${YOLO_SCALE:-}" ]; then export YOLO_SCALE="320x240"; fi
if [ -z "${YOLO_NAMES:-}" ]; then export YOLO_NAMES=""; fi
if [ -z "${YOLO_DATA:-}" ]; then export YOLO_DATA=""; fi
if [ -z "${YOLO_CFG_FILE:-}" ]; then export YOLO_CFG_FILE=""; fi
if [ -z "${YOLO_WEIGHTS:-}" ]; then export YOLO_WEIGHTS=""; fi
if [ -z "${YOLO_WEIGHTS_URL:-}" ]; then export YOLO_WEIGHTS_URL=""; fi
if [ -z "${YOLO_CONFIG}" ]; then export YOLO_CONFIG="tiny-v2"; fi

hzn::log.notice "Starting ${0} ${*}"

yolo::main ${*}

exit 1
