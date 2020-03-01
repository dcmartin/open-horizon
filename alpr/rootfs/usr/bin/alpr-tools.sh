#!/usr/bin/env bash

# defaults for testing
if [ -z "${ALPR_PERIOD:-}" ]; then ALPR_PERIOD=0; fi
if [ -z "${ALPR_PATTERN:-}" ]; then ALPR_PATTERN=""; fi
if [ -z "${ALPR_TOPN:-}" ]; then ALPR_TOPN=10; fi
if [ -z "${ALPR_SCALE:-}" ]; then ALPR_SCALE="320x240"; fi
if [ -z "${ALPR_CONFIG}" ]; then ALPR_CONFIG="tiny"; fi
if [ -z "${OPENALPR}" ]; then echo "*** ERROR -- $0 $$ -- OPENALPR unspecified; set environment variable for testing"; fi

# temporary image and output
JPEG="${TMPDIR}/${0##*/}.$$.jpeg"
OUT="${TMPDIR}/${0##*/}.$$.out"

# same for all configurations
ALPR_NAMES="${OPENALPR}/data/coco.names"

alpr_init() 
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  # build configuation
  CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"period":'${ALPR_PERIOD}',"pattern":"'${ALPR_PATTERN}'","scale":"'${ALPR_SCALE}'","config":"'${ALPR_CONFIG}'","threshold":'${ALPR_TOPN}',"services":'"${SERVICES:-null}"'}'
  # get names of entities that can be detected
  if [ -s "${ALPR_NAMES}" ]; then
    hzn.log.debug "Processing ${ALPR_NAMES}"
    NAMES='['$(awk -F'|' '{ printf("\"%s\"", $1) }' "${ALPR_NAMES}" | sed 's|""|","|g')']'
  fi
  if [ -z "${NAMES:-}" ]; then NAMES='["person"]'; fi
  CONFIG=$(echo "${CONFIG}" | jq '.names='"${NAMES}")
  echo "${CONFIG}"
}

alpr_config()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  case ${1} in
    us)
      OPENALPR_WEIGHTS="${OPENALPR_US_WEIGHTS_URL}"
      ALPR_WEIGHTS="${OPENALPR_US_WEIGHTS}"
      ALPR_CFG_FILE="${OPENALPR_US_CONFIG}"
      ALPR_DATA="${OPENALPR_US_DATA}"
    ;;
    eu)
      OPENALPR_WEIGHTS="${OPENALPR_EU_WEIGHTS_URL}"
      ALPR_WEIGHTS="${OPENALPR_EU_WEIGHTS}"
      ALPR_CFG_FILE="${OPENALPR_EU_CONFIG}"
      ALPR_DATA="${OPENALPR_EU_DATA}"
    ;;
    *)
      hzn.log.error "Invalid ALPR_CONFIG: ${1}"
    ;;
  esac
  if [ ! -z "${ALPR_WEIGHTS:-}" ] && [ ! -s "${ALPR_WEIGHTS}" ]; then
    hzn.log.debug "ALPR config: ${1}; updating ${ALPR_WEIGHTS} from ${OPENALPR_WEIGHTS}"
    curl -fsSL ${OPENALPR_WEIGHTS} -o ${ALPR_WEIGHTS}
    if [ ! -s "${ALPR_WEIGHTS}" ]; then
      hzn.log.error "ALPR config: ${1}; failed to download: ${OPENALPR_WEIGHTS}"
    fi
  fi
}

alpr_process()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local PAYLOAD="${1}"
  local ITERATION="${2}"
  local OUTPUT='{}'
  local MOCKS=( ${OPENALPR_EU_DATA}/h786poj.jpg ${OPENALPR_US_DATA}/va/ea7the.jpg )

  # test image 
  if [ ! -s "${PAYLOAD}" ]; then 
    if [ -z "${ITERATION}" ]; then MOCK_INDEX=0; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    hzn.log.debug "MOCK index: ${MOCK_INDEX} of ${#MOCKS[@]}"
    MOCK="${MOCKS[${MOCK_INDEX}]}"
    hzn.log.debug "MOCK image: ${MOCK}"
    cp -f "${MOCK}" ${PAYLOAD}
    # update output to be mock
    OUTPUT=$(echo "${OUTPUT}" | jq '.mock="'${MOCK##*/}'"')
  fi

  # scale image
  if [ "${ALPR_SCALE}" != 'none' ]; then
    convert -scale "${ALPR_SCALE}" "${PAYLOAD}" "${JPEG}"
  else
    mv -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn.log.debug "JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }')

  # get image information
  INFO=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.')
  hzn.log.debug "JPEG: ${JPEG}; info: ${INFO}"
  OUTPUT=$(echo "${OUTPUT}" | jq '.info='"${INFO}")

  # check configuration options
  if [ ! -z "${ALPR_CONFIG:-}" ]; then CONFIG="-c ${ALPR_CONFIG}"; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.config="'${ALPR_CONFIG:-}'"')
  if [ ! -z "${ALPR_PATTERN:-}" ]; then PATTERN="-p ${ALPR_PATTERN}"; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.pattern="'${ALPR_PATTERN:-}'"')
  if [ ! -z "${ALPR_CFG_FILE:-}" ]; then CFG_FILE="--config ${ALPR_CFG_FILE}"; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.cfg_file="'${ALPR_CFG_FILE:-}'"')


  ## do ALPR
  hzn.log.debug "OPENALPR: alpr --clock --json ${CFG_FILE} ${CONFIG} ${PATTERN} -n ${ALPR_TOPN} ${JPEG}"
  alpr --clock --json ${CFG_FILE} ${CONFIG} ${PATTERN} -n ${ALPR_TOPN} ${JPEG} > "${OUT}" 2> "${TMPDIR}/alpr.$$.out"

  # test for output
  if [ -s "${OUT}" ]; then
    local TIME=$(jq '.processing_time_ms?' ${OUT})
    local TOTAL=$(jq '.regions_of_interest?|length' ${OUT})

    if [ "${TIME:-null}" != 'null' ] && [ ${TIME} -gt 0 ]; then
      TIME=$(echo "${TIME} / 1000.0" | bc -l)
    fi
    if [ ${TOTAL:-0} -gt 0 ]; then
      local plates=$(jq -r '.results[].plate' h786poj.json)

      for plate in ${plates}; do
        if [ "${detected:-null}" != 'null' ]; then detected="${detected},"; else detected='['; fi
        detected="${detected}"'"'${plate}'"'
      done
      if [ "${detected:-null}" != 'null' ]; then detected="${detected}"']'; fi
    fi
    OUTPUT=$(echo "${OUTPUT}" | jq '.count='${TOTAL:-null}'|.detected='"${detected:-null}"'|.time='${TIME:-null})
  else
    echo "+++ WARN $0 $$ -- no output:" $(cat ${OUT}) &> /dev/stderr
    hzn.log.debug "alpr failed:" $(cat "${TMPDIR}/alpr.$$.out")
    OUTPUT=$(echo "${OUTPUT}" | jq '.count=0|.detected=null|.time=0')
  fi

  # capture annotated image as BASE64 encoded string
  IMAGE="${TMPDIR}/predictions.$$.json"
  echo -n '{"image":"' > "${IMAGE}"
  if [ -s "${PAYLOAD}" ]; then
    base64 -w 0 -i ${PAYLOAD} >> "${IMAGE}"
  fi
  echo '"}' >> "${IMAGE}"

  TEMP="${TMPDIR}/${0##*/}.$$.json"
  echo "${OUTPUT}" > "${TEMP}"
  jq -s add "${TEMP}" "${IMAGE}" > "${TEMP}.$$" && mv -f "${TEMP}.$$" "${IMAGE}"
  rm -f "${TEMP}"

  # cleanup
  rm -f "${JPEG}" "${OUT}" predictions.jpg

  # return base64 encode image JSON path
  echo "${IMAGE}"
}

