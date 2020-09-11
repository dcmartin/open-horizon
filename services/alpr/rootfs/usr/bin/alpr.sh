#!/usr/bin/with-contenv bashio

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/alpr-tools.sh

###
### MAIN
###

alpr::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  # build configuation
  local config='{"log_level":"'${SERVICE_LOG_LEVEL:-info}'","timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"period":'${ALPR_PERIOD:-30}',"pattern":"'${ALPR_PATTERN:-}'","scale":"'${ALPR_SCALE:-}'","country":"'${ALPR_COUNTRY:-}'","topn":'${ALPR_TOPN:-10}',"services":'"${SERVICES:-null}"',"countries":'$(alpr::countries)',"resolution":"'${WEBCAM_RESOLUTION:-}'","device":"'${WEBCAM_DEVICE:-}'"}'

  ## initialize horizon
  hzn::log.notice "${FUNCNAME[0]}: initializing service: ${SERVICE_LABEL:-}" $(echo "${config}" | jq -c '.' || echo "INVALID: ${config}")
  hzn::init
  hzn::service.init "${config}"

  ## configure ALPR
  alpr::config ${ALPR_COUNTRY:-us}

  # start in alpr
  cd ${OPENALPR:-}

  hzn::log.notice "${FUNCNAME[0]}: processing images from /dev/video0 every ${ALPR_PERIOD:-} seconds"

  local OUTPUT_FILE=$(mktemp)
  echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"

  while true; do
    # when we start
    DATE=$(date +%s)
  
    # path to image payload
    JPEG_FILE=$(mktemp -t "${0##*/}-XXXXXX")
    # capture image payload from /dev/video0
    # fswebcam --resolution "${WEBCAM_RESOLUTION}" --device "${WEBCAM_DEVICE}" --no-banner "${JPEG_FILE}" &> /dev/null
  
    hzn::log.debug "Attempting to capture image"
    fswebcam --device "${WEBCAM_DEVICE}" --no-banner "${JPEG_FILE}" &> /dev/null
  
    # process image payload into JSON
    if [ -z "${ITERATION:-}" ]; then ITERATION=0; else ITERATION=$((ITERATION+1)); fi
    ALPR_OUTPUT_FILE=$(alpr::process "${JPEG_FILE}" "${ITERATION}")
  
    # remove
    rm -f ${JPEG_FILE}
  
    if [ -s "${ALPR_OUTPUT_FILE}" ]; then
      # add two files
      jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) "${ALPR_OUTPUT_FILE}" > "${OUTPUT_FILE}"
      # update
    else
      hzn::log.error "No output"
      echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
    fi
    # update
    hzn::service.update "${OUTPUT_FILE}"
  
    # wait for ..
    SECONDS=$((ALPR_PERIOD - $(($(date +%s) - DATE))))
    if [ ${SECONDS} -gt 0 ]; then
      hzn::log.debug "sleep ${SECONDS}"
      sleep ${SECONDS}
    fi
  done
}

###
### MAIN
###

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

# sanity
if [ -z "${OPENALPR:-}" ]; then hzn::log.fatal "OPENALPR unspecified; set environment variable for testing"; exit 1; fi

# defaults for testing
if [ -z "${ALPR_COUNTRY:-}" ]; then export ALPR_COUNTRY="us"; fi
if [ -z "${ALPR_PATTERN:-}" ]; then export ALPR_PATTERN=""; fi
if [ -z "${ALPR_TOPN:-}" ]; then export ALPR_TOPN=10; fi
if [ -z "${ALPR_SCALE:-}" ]; then export ALPR_SCALE="320x240"; fi
if [ -z "${ALPR_PERIOD:-}" ]; then export ALPR_PERIOD=30; fi
if [ -z "${WEBCAM_DEVICE}" ]; then export WEBCAM_DEVICE="/dev/video0"; fi
if [ -z "${WEBCAM_RESOLUTION}" ]; then export WEBCAM_RESOLUTION="320x240"; fi

hzn::log.notice "Starting ${0} ${*}: ${SERVICE_LABEL:-null}; version: ${SERVICE_VERSION:-null}"

alpr::main ${*}

exit 1
