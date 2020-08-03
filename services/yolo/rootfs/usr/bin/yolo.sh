#!/usr/bin/with-contenv bashio

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/yolo-tools.sh

main()
{
  bashio::log.trace "${FUNCNAME[0]} ${*}"

  local config=$(echo "${init}" | jq '.resolution="'${WEBCAM_RESOLUTION:-384x288}'"|.device="'${WEBCAM_DEVICE:-/dev/video0}'"')
  local output=$(mktemp)
  local init

  hzn::service.init "${config}"
  bashio::log.debug "${FUNCNAME[0]}: ${SERVICE_NAME:-null} initialialized:" $($(hzn::service.config) | jq -c '.')

  ## initialize YOLO
  init=$(yolo_init ${YOLO_CONFIG:-tiny})
  if [ ! -z "${init:-}" ]; then
    local jpeg=$(mktemp)
    local seconds
    local iteration

    ## initialize
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${output}"
  
    bashio::log.notice "${FUNCNAME[0]}: starting loop"
  
    while true; do
      # when we start
      local DATE=$(date +%s)
      local yolo
  
      # get image from camera device
      fswebcam --device "${WEBCAM_DEVICE}" --no-banner "${jpeg}" &> /dev/null
      if [ ! -s "${jpeg}" ]; then bashio::log.warning "${FUNCNAME[0]}: no image captured"; fi
  
      # process image payload into JSON
      if [ -z "${iteration:-}" ]; then iteration=0; else iteration=$((iteration+1)); fi
      yolo=$(yolo_process "${jpeg}" "${iteration}")
      if [ -s "${yolo}" ]; then
        bashio::log.debug "${FUNCNAME[0]}: YOLO success; output: ${yolo}"
        jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) "${yolo}" > "${output}"
      else
        bashio::log.warning "${FUNCNAME[0]}: no YOLO output"
        echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${output}"
      fi
  
      # update
      hzn::service.update "${output}"
  
      # wait for ..
      seconds=$((YOLO_PERIOD - $(($(date +%s) - DATE))))
      if [ ${seconds} -gt 0 ]; then
        bashio::log.debug "${FUNCNAME[0]}: sleeping for ${seconds} seconds"
        sleep ${seconds}
      fi

    done
  else
    bashio::log.error "${FUNCNAME[0]}: YOLO did not initialize"
  fi
}

###
### MAIN
###

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

# test
if [ -z "${DARKNET:-}" ]; then bashio::log.error "${0}: DARKNET unspecified; set environment variable for testing"; fi

# defaults for testing
if [ -z "${YOLO_PERIOD:-}" ]; then YOLO_PERIOD=0; fi
if [ -z "${YOLO_ENTITY:-}" ]; then YOLO_ENTITY=person; fi
if [ -z "${YOLO_THRESHOLD:-}" ]; then YOLO_THRESHOLD=0.25; fi
if [ -z "${YOLO_SCALE:-}" ]; then YOLO_SCALE="320x240"; fi
if [ -z "${YOLO_NAMES:-}" ]; then YOLO_NAMES=""; fi
if [ -z "${YOLO_DATA:-}" ]; then YOLO_DATA=""; fi
if [ -z "${YOLO_CFG_FILE:-}" ]; then YOLO_CFG_FILE=""; fi
if [ -z "${YOLO_WEIGHTS:-}" ]; then YOLO_WEIGHTS=""; fi
if [ -z "${YOLO_WEIGHTS_URL:-}" ]; then YOLO_WEIGHTS_URL=""; fi
if [ -z "${YOLO_CONFIG}" ]; then YOLO_CONFIG="tiny-v2"; fi

bashio::log.notice "Starting ${0} ${*}"

main ${*}
