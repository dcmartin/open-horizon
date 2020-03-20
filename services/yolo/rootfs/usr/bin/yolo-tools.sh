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

  PAYLOAD="${1}"
  ITERATION="${2}"
  OUTPUT='{}'

  # test image 
  if [ ! -s "${PAYLOAD}" ]; then 
    MOCKS=( dog giraffe kite eagle horses person scream )
    if [ -z "${ITERATION}" ]; then MOCK_INDEX=0; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    hzn.log.debug "MOCK index: ${MOCK_INDEX} of ${#MOCKS[@]}"
    MOCK="${MOCKS[${MOCK_INDEX}]}"
    hzn.log.debug "MOCK image: ${MOCK}"
    cp -f "data/${MOCK}.jpg" ${PAYLOAD}
    # update output to be mock
    OUTPUT=$(echo "${OUTPUT}" | jq '.mock="'${MOCK}'"')
  fi

  # scale image
  if [ "${YOLO_SCALE}" != 'none' ]; then
    convert -scale "${YOLO_SCALE}" "${PAYLOAD}" "${JPEG}"
  else
    mv -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn.log.debug "JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }')

  # get image information
  INFO=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.')
  hzn.log.debug "JPEG: ${JPEG}; info: ${INFO}"
  OUTPUT=$(echo "${OUTPUT}" | jq '.info='"${INFO}")

  local data=$(jq -r '.darknet.data' ${CONF_FILE})
  local weights=$(jq -r '.darknet.weights' ${CONF_FILE})
  local cfg=$(jq -r '.darknet.cfg' ${CONF_FILE})
  local threshold=$(jq -r '.darknet.threshold' ${CONF_FILE})

  ## do YOLO
  hzn.log.debug "DARKNET: ./darknet detector test ${data} ${cfg} ${weights} ${JPEG} -thresh ${threshold}"
  ./darknet detector test "${data}" "${cfg}" "${weights}" "${JPEG}" -thresh "${threshold}" > "${OUT}" 2> "${TMPDIR}/darknet.$$.out"
  # extract processing time in seconds
  TIME=$(cat "${OUT}" | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
  if [ -z "${TIME}" ]; then TIME=0; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.time="'${TIME}'"')
  hzn.log.debug "TIME: ${TIME}"
  # test for output
  if [ -s "${OUT}" ]; then
    TOTAL=0
    case ${YOLO_ENTITY} in
      all)
	# find entities in output
	cat "${OUT}" | tr '\n' '\t' | sed 's/.*Predicted in \([^ ]*\) seconds. */time: \1/' | tr '\t' '\n' | tail +2 > "${OUT}.$$"
	FOUND=$(cat "${OUT}.$$" | awk -F: '{ print $1 }' | sort | uniq)
	if [ ! -z "${FOUND}" ]; then
	  hzn.log.debug "Detected:" $(echo "${FOUND}" | fmt -1000)
	  JSON=
	  for F in ${FOUND}; do
	    if [ -z "${JSON:-}" ]; then JSON='['; else JSON="${JSON}"','; fi
	    C=$(egrep '^'"${F}" "${OUT}.$$" | wc -l | awk '{ print $1 }')
	    COUNT='{"entity":"'"${F}"'","count":'${C}'}'
	    JSON="${JSON}""${COUNT}"
	    TOTAL=$((TOTAL+C))
	  done
	  rm -f "${OUT}.$$"
	  if [ -z "${JSON}" ]; then JSON='null'; else JSON="${JSON}"']'; fi
	  DETECTED="${JSON}"
	else
	  hzn.log.debug "Detected nothing"
	  DETECTED='null'
	fi
	;;
      *)
	# count single entity
	C=$(egrep '^'"${YOLO_ENTITY}" "${OUT}" | wc -l | awk '{ print $1 }')
	COUNT='{"entity":"'"${YOLO_ENTITY}"'","count":'${C}'}'
	TOTAL=$((TOTAL+C))
	DETECTED='['"${COUNT}"']'
	;;
    esac
    OUTPUT=$(echo "${OUTPUT}" | jq '.count='${TOTAL}'|.detected='"${DETECTED}"'|.time='${TIME})
  else
    echo "+++ WARN $0 $$ -- no output:" $(cat ${OUT}) &> /dev/stderr
    hzn.log.debug "darknet failed:" $(cat "${TMPDIR}/darknet.$$.out")
    OUTPUT=$(echo "${OUTPUT}" | jq '.count=0|.detected=null|.time=0')
  fi

  # capture annotated image as BASE64 encoded string
  IMAGE="${TMPDIR}/predictions.$$.json"
  echo -n '{"image":"' > "${IMAGE}"
  if [ -s "predictions.jpg" ]; then
    base64 -w 0 -i predictions.jpg >> "${IMAGE}"
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

