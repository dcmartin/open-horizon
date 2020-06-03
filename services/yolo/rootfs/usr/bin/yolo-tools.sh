#!/usr/bin/env bash

# test
if [ -z "${DARKNET}" ]; then hzn.log.error "DARKNET unspecified; set environment variable for testing"; fi

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
if [ -z "${YOLO_CONFIG}" ]; then YOLO_CONFIG="tiny"; fi

# temporary image and output
JPEG="${TMPDIR}/${0##*/}.$$.jpeg"
OUT="${TMPDIR}/${0##*/}.$$.out"
CONF_FILE=/etc/yolo.conf

yolo_init() 
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  ## configure YOLO
  local which=${1:-tiny-v2}
  local darknet=$(yolo_config ${which})

  local weights=$(echo "${darknet}" | jq -r '.weights')
  local weights_url=$(echo "${darknet}" | jq -r '.weights_url')
  local weights_md5=$(echo "${darknet}" | jq -r '.weights_md5')
  local namefile=$(echo "${darknet}" | jq -r '.names')
  local attempts=0

  hzn.log.debug "${FUNCNAME[0]} config: ${which}; weights: ${weights}"

  while [ ${attempts} -le ${YOLO_ATTEMPTS:-2} ]; do
    if [ -s "${weights}" ]; then
      local md5=$(md5sum ${weights} | awk '{ print $1 }')

      if [ "${md5}" != "${weights_md5}" ]; then
        hzn.log.notice "YOLO config: ${which}; attempt: ${attempts}; failed checksum: ${md5} != ${weights_md5}"
        rm -f ${weights}
      else
        break
      fi
    fi

    # download
    hzn.log.notice "YOLO config: ${which}; downloading ${weights} from ${weights_url}"
    curl -fsSL ${weights_url} -o ${weights}
    attempts=$((attempts+1))
  done
  if [ ! -s "${weights}" ]; then
    hzn.log.notice "YOLO config: ${which}; failed to download after ${YOLO_ATTEMPTS:-2}; defaulting to ${YOLO_DEFAULT:tiny}"
    yolo_config ${YOLO_DEFAULT:-tiny}
  else
    hzn.log.notice "YOLO config: ${which}; downloaded: ${weights}"
  fi

  # build configuation
  CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"period":'${YOLO_PERIOD}',"entity":"'${YOLO_ENTITY}'","scale":"'${YOLO_SCALE}'","config":"'${YOLO_CONFIG}'","services":'"${SERVICES:-null}"',"darknet":'"${darknet}"'}'
  # get namefile of entities that can be detected
  if [ -s "${namefile}" ]; then
    hzn.log.info "Processing ${namefile}"
    NAMES='['$(awk -F'|' '{ printf("\"%s\"", $1) }' "${namefile}" | sed 's|""|","|g')']'
  fi
  if [ -z "${NAMES:-}" ]; then NAMES='["person"]'; fi
  CONFIG=$(echo "${CONFIG}" | jq '.names='"${NAMES}")
  echo "${CONFIG}" | tee ${CONF_FILE}
}

yolo_config()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  case ${1} in
    tiny|tiny-v2)
      YOLO_WEIGHTS_URL="${DARKNET_TINYV2_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_TINYV2_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_TINYV2_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_TINYV2_CONFIG}"
      YOLO_DATA="${DARKNET_TINYV2_DATA}"
      YOLO_NAMES="${DARKNET_TINYV2_NAMES}"
    ;;
    tiny-v3)
      YOLO_WEIGHTS_URL="${DARKNET_TINYV3_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_TINYV3_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_TINYV3_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_TINYV3_CONFIG}"
      YOLO_DATA="${DARKNET_TINYV3_DATA}"
      YOLO_NAMES="${DARKNET_TINYV3_NAMES}"
    ;;
    v2)
      YOLO_WEIGHTS_URL="${DARKNET_V2_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_V2_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_V2_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_V2_CONFIG}"
      YOLO_DATA="${DARKNET_V2_DATA}"
      YOLO_NAMES="${DARKNET_V2_NAMES}"
    ;;
    v3)
      YOLO_WEIGHTS_URL="${DARKNET_V3_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_V3_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_V3_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_V3_CONFIG}"
      YOLO_DATA="${DARKNET_V3_DATA}"
      YOLO_NAMES="${DARKNET_V3_NAMES}"
    ;;
    *)
      hzn.log.error "Invalid YOLO_CONFIG: ${1}"
    ;;
  esac
  echo '{"threshold":'${YOLO_THRESHOLD}',"weights_url":"'${YOLO_WEIGHTS_URL}'","weights":"'${YOLO_WEIGHTS}'","weights_md5":"'${YOLO_WEIGHTS_MD5}'","cfg":"'${YOLO_CFG_FILE}'","data":"'${YOLO_DATA}'","names":"'${YOLO_NAMES}'"}'
}

yolo_process()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local PAYLOAD="${1}"
  local ITERATION="${2}"
  local output='{}'
  local MOCK=
  local JPEG=$(mktemp).jpeg

  # test image 
  if [ ! -s "${PAYLOAD}" ]; then 
    local MOCKS=( dog giraffe kite eagle horses person scream )
    if [ -z "${ITERATION}" ]; then MOCK_INDEX=0; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    MOCK='"'${MOCKS[${MOCK_INDEX}]}'"'
    cp -f "data/${MOCK}.jpg" ${PAYLOAD}
  else
    MOCK=null
  fi

  # scale image
  if [ "${YOLO_SCALE}" != 'none' ]; then
    convert -scale "${YOLO_SCALE}" "${PAYLOAD}" "${JPEG}"
  else
    mv -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn.log.debug "JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }')

  # get image information

  local data=$(jq -r '.darknet.data' ${CONF_FILE})
  local weights=$(jq -r '.darknet.weights' ${CONF_FILE})
  local cfg=$(jq -r '.darknet.cfg' ${CONF_FILE})
  local threshold=$(jq -r '.darknet.threshold' ${CONF_FILE})

  output=$(darknet_detector_test ${data} ${weights} ${cfg} ${threshold} ${JPEG})

  # capture annotated image as BASE64 encoded string
  local IMAGE=$(mktemp)
  local TEMP=$(mktemp)

  echo -n '{"mock": '${MOCK}', "image":"' > "${IMAGE}"
  if [ -s "predictions.jpg" ]; then
    base64 -w 0 -i predictions.jpg >> "${IMAGE}"
  fi
  echo '"}' >> "${IMAGE}"

  echo "${output}" > "${TEMP}"
  jq -s add "${TEMP}" "${IMAGE}" > "${TEMP}.$$" && mv -f "${TEMP}.$$" "${IMAGE}"
  rm -f "${TEMP}"

  # cleanup
  rm -f "${JPEG}" "${out}" predictions.jpg

  # return base64 encode image JSON path
  echo "${IMAGE}"
}


darknet_detector_test()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local data=${1}
  local weights=${2}
  local cfg=${3}
  local threshold=${5}
  local JPEG=${6}

  local out=$(mktemp)
  local err=$(mktemp)
  local info=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.')
  local output='{"info":'"${info}"'}'

  ## do YOLO
  hzn.log.debug "CALLING: ${DARKNET}/darknet detector test ${data} ${weights} ${cfg} -thresh ${threshold} ${JPEG}"
  ${DARKNET}/darknet detector test "${data}" "${cfg}" "${weights}" -thresh "${threshold}" "${JPEG}" > "${out}" 2> "${err}"

  # test for output
  if [ -s "${out}" ]; then
    hzn.log.debug "RETURNED: output: ${out}"
    # extract processing time in seconds
    TIME=$(cat "${out}" | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
    if [ -z "${TIME}" ]; then TIME=0; fi
    output=$(echo "${output}" | jq '.time="'${TIME}'"')

    TOTAL=0
    case ${YOLO_ENTITY} in
      all)
	# find entities in output
	cat "${out}" | tr '\n' '\t' | sed 's/.*Predicted in \([^ ]*\) seconds. */time: \1/' | tr '\t' '\n' | tail +2 > "${out}.$$"
	FOUND=$(cat "${out}.$$" | awk -F: '{ print $1 }' | sort | uniq)
	if [ ! -z "${FOUND}" ]; then
	  hzn.log.debug "Detected:" $(echo "${FOUND}" | fmt -1000)
	  JSON=
	  for F in ${FOUND}; do
	    if [ -z "${JSON:-}" ]; then JSON='['; else JSON="${JSON}"','; fi
	    C=$(egrep '^'"${F}" "${out}.$$" | wc -l | awk '{ print $1 }')
	    COUNT='{"entity":"'"${F}"'","count":'${C}'}'
	    JSON="${JSON}""${COUNT}"
	    TOTAL=$((TOTAL+C))
	  done
	  rm -f "${out}.$$"
	  if [ -z "${JSON}" ]; then JSON='null'; else JSON="${JSON}"']'; fi
	  DETECTED="${JSON}"
	else
	  hzn.log.debug "Detected nothing"
	  DETECTED='null'
	fi
	;;
      *)
	# count single entity
	C=$(egrep '^'"${YOLO_ENTITY}" "${out}" | wc -l | awk '{ print $1 }')
	COUNT='{"entity":"'"${YOLO_ENTITY}"'","count":'${C}'}'
	TOTAL=$((TOTAL+C))
	DETECTED='['"${COUNT}"']'
	;;
    esac
    output=$(echo "${output}" | jq '.count='${TOTAL}'|.detected='"${DETECTED}"'|.time='${TIME})
  else
    echo "+++ WARN $0 $$ -- no output:" $(cat ${out}) &> /dev/stderr
    hzn.log.debug "darknet failed:" $(cat "${TMPDIR}/darknet.$$.out")
    output=$(echo "${output}" | jq '.count=0|.detected=null|.time=0')
  fi
}
