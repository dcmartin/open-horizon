#!/usr/bin/env bash

# defaults for testing
if [ -z "${YOLO_PERIOD:-}" ]; then YOLO_PERIOD=0; fi
if [ -z "${YOLO_ENTITY:-}" ]; then YOLO_ENTITY=person; fi
if [ -z "${YOLO_THRESHOLD:-}" ]; then YOLO_THRESHOLD=0.25; fi
if [ -z "${YOLO_SCALE:-}" ]; then YOLO_SCALE="320x240"; fi
if [ -z "${YOLO_CONFIG}" ]; then YOLO_CONFIG="tiny"; fi
if [ -z "${DARKNET}" ]; then echo "*** ERROR -- $0 $$ -- DARKNET unspecified; set environment variable for testing"; fi

# temporary image and output
JPEG="${TMPDIR}/${0##*/}.$$.jpeg"
OUT="${TMPDIR}/${0##*/}.$$.out"

# same for all configurations
YOLO_NAMES="${DARKNET}/data/coco.names"

yolo_init() 
{
  # build configuation
  CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"period":'${YOLO_PERIOD}',"entity":"'${YOLO_ENTITY}'","scale":"'${YOLO_SCALE}'","config":"'${YOLO_CONFIG}'","device":"'${YOLO_DEVICE}'","threshold":'${YOLO_THRESHOLD}',"services":'"${SERVICES:-null}"'}}'
  # get names of entities that can be detected
  if [ -s "${YOLO_NAMES}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- processing ${YOLO_NAMES}" &> /dev/stderr; fi
    NAMES='['$(awk -F'|' '{ printf("\"%s\"", $1) }' "${YOLO_NAMES}" | sed 's|""|","|g')']'
  fi
  if [ -z "${NAMES:-}" ]; then NAMES='["person"]'; fi
  CONFIG=$(echo "${CONFIG}" | jq '.names='"${NAMES}")
  echo "${CONFIG}"
}

yolo_config()
{
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- YOLO config: ${1}" &> /dev/stderr; fi
  case ${1} in
    tiny|tiny-v2)
      DARKNET_WEIGHTS="${DARKNET_TINYV2_WEIGHTS_URL}"
      YOLO_WEIGHTS="${DARKNET_TINYV2_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_TINYV2_CONFIG}"
      YOLO_DATA="${DARKNET_TINYV2_DATA}"
    ;;
    tiny-v3)
      DARKNET_WEIGHTS="${DARKNET_TINYV3_WEIGHTS_URL}"
      YOLO_WEIGHTS="${DARKNET_TINYV3_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_TINYV3_CONFIG}"
      YOLO_DATA="${DARKNET_TINYV3_DATA}"
    ;;
    v2)
      DARKNET_WEIGHTS="${DARKNET_V2_WEIGHTS_URL}"
      YOLO_WEIGHTS="${DARKNET_V2_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_V2_CONFIG}"
      YOLO_DATA="${DARKNET_V2_DATA}"
    ;;
    v3)
      DARKNET_WEIGHTS="${DARKNET_V3_WEIGHTS_URL}"
      YOLO_WEIGHTS="${DARKNET_V3_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_V3_CONFIG}"
      YOLO_DATA="${DARKNET_V3_DATA}"
    ;;
    *)
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- invalid YOLO_CONFIG: ${1}" &> /dev/stderr; fi
    ;;
  esac
  if [ ! -s "${YOLO_WEIGHTS}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- YOLO config: ${1}; updating ${YOLO_WEIGHTS} from ${DARKNET_WEIGHTS}" &> /dev/stderr; fi
    curl -fsSL ${DARKNET_WEIGHTS} -o ${YOLO_WEIGHTS}
    if [ ! -s "${YOLO_WEIGHTS}" ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- YOLO config: ${1}; failed to download: ${DARKNET_WEIGHTS}" &> /dev/stderr; fi
    fi
  fi
}

yolo_process()
{
  PAYLOAD="${1}"
  ITERATION="${2}"
  OUTPUT='{}'

  # test image 
  if [ ! -s "${PAYLOAD}" ]; then 
    MOCKS=( dog giraffe kite eagle horses person scream )
    if [ -z "${ITERATION}" ]; then MOCK_INDEX=0; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- MOCK index: ${MOCK_INDEX} of ${#MOCKS[@]}" &> /dev/stderr; fi
    MOCK="${MOCKS[${MOCK_INDEX}]}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- MOCK image: ${MOCK}" &> /dev/stderr; fi
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
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }') &> /dev/stderr; fi

  # get image information
  INFO=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- INFO: ${INFO}" &> /dev/stderr; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.info='"${INFO}")

  ## do YOLO
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- DARKNET: ./darknet detector test ${YOLO_DATA} ${YOLO_CFG_FILE} ${YOLO_WEIGHTS} ${JPEG} -thresh ${YOLO_THRESHOLD}" &> /dev/stderr; fi
  ./darknet detector test "${YOLO_DATA}" "${YOLO_CFG_FILE}" "${YOLO_WEIGHTS}" "${JPEG}" -thresh "${YOLO_THRESHOLD}" > "${OUT}" 2> "${TMPDIR}/darknet.$$.out"
  # extract processing time in seconds
  TIME=$(cat "${OUT}" | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
  if [ -z "${TIME}" ]; then TIME=0; fi
  OUTPUT=$(echo "${OUTPUT}" | jq '.time="'${TIME}'"')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- TIME: ${TIME}" &> /dev/stderr; fi
  # test for output
  if [ -s "${OUT}" ]; then
    TOTAL=0
    case ${YOLO_ENTITY} in
      all)
	# find entities in output
	cat "${OUT}" | tr '\n' '\t' | sed 's/.*Predicted in \([^ ]*\) seconds. */time: \1/' | tr '\t' '\n' | tail +2 > "${OUT}.$$"
	FOUND=$(cat "${OUT}.$$" | awk -F: '{ print $1 }' | sort | uniq)
	if [ ! -z "${FOUND}" ]; then
	  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- detected:" $(echo "${FOUND}" | fmt -1000) &> /dev/stderr; fi
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
	  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- detected nothing" &> /dev/stderr; fi
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
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- darknet failed:" $(cat "${TMPDIR}/darknet.$$.out") &> /dev/stderr; fi
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

