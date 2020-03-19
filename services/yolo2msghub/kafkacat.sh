#!/bin/bash
BROKER="kafka05-prod02.messagehub.services.us-soutbluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093"

REQUIRED_VARIABLES=YOLO2MSGHUB_APIKEY
for R in ${REQUIRED_VARIABLES}; do
  if [ ! -s "${R}" ]; then echo "*** ERROR $0 $$ -- required variable ${R} file not found; exiting" &> /dev/stderr; fi
  APIKEY=$(sed -e 's|^["]*\([^"]*\)["]*|\1|' "${R}")
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- set ${R} to ${APIKEY}" &> /dev/stderr; fi
done

TOPIC="yolo2msghub"
DEVICES='[]'
TOTAL_BYTES=0
BEGIN=$(date +%s)

echo "--- INFO $0 $$ -- listening for topic ${TOPIC}" &> /dev/stderr

kafkacat -E -u -C -q -o end -f "%s\n" -b "${BROKER}" \
  -X "security.protocol=sasl_ssl" \
  -X "sasl.mechanisms=PLAIN" \
  -X "sasl.username=${APIKEY:0:16}" \
  -X "sasl.password=${APIKEY:16}" \
  -t "${TOPIC}" | while read -r; do

    NOW=$(date +%s)

    if [ -n "${REPLY}" ]; then
      PAYLOAD=${0##*/}.$$.json
      echo "${REPLY}" > ${PAYLOAD}
      VALID=$(echo "${REPLY}" | ./test-yolo2msghub.sh 2> ${PAYLOAD%.*}.out)
    else
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- received null payload:" $(date +%T) &> /dev/stderr; fi
      continue
    fi
    if [ "${VALID}" != true ]; then
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- invalid payload: ${VALID}" $(cat ${PAYLOAD%.*}.out) &> /dev/stderr; fi
    else
      BYTES=$(wc -c ${PAYLOAD} | awk '{ print $1 }')
      TOTAL_BYTES=$((TOTAL_BYTES+BYTES))
      ELAPSED=$((NOW-BEGIN))
      if [ ${ELAPSED} -ne 0 ]; then BPS=$(echo "${TOTAL_BYTES} / ${ELAPSED}" | bc -l); else BPS=1; fi
      echo "### DATA $0 $$ -- received at: $(date +%T); bytes: ${BYTES}; total bytes: ${TOTAL_BYTES}; bytes/sec: ${BPS}" &> /dev/stderr
    fi

    ID=$(jq -r '.hzn.device_id' ${PAYLOAD})
    ENTITY=$(jq -r '.yolo2msghub.yolo.detected[]?.entity' ${PAYLOAD})
    DATE=$(jq -r '.date' ${PAYLOAD})
    STARTED=$((NOW-DATE))

    # HZN
    if [ $(jq '.hzn?!=null' ${PAYLOAD}) = true ]; then
      HZN=$(jq '.hzn' ${PAYLOAD})
      HZN_STATUS=$(echo "${HZN}" | jq -c '.')
    fi
    HZN_STATUS=${HZN_STATUS:-null}

    # WAN
    if [ $(jq '.wan?!=null' ${PAYLOAD}) = true ]; then
      WAN=$(jq '.wan' ${PAYLOAD})
      WAN_DOWNLOAD=$(echo "${WAN}" | jq -r '.speedtest.download')
    fi
    WAN_DOWNLOAD=${WAN_DOWNLOAD:-0}

    # CPU
    if [ $(jq '.cpu?!=null' ${PAYLOAD}) = true ]; then
      CPU=$(jq '.cpu' ${PAYLOAD})
      CPU_PERCENT=$(echo "${CPU}" | jq -r '.percent')
    fi
    CPU_PERCENT=${CPU_PERCENT:-0}

    # HAL
    if [ $(jq '.hal?!=null' ${PAYLOAD}) = true ]; then
      HAL=$(jq '.hal' ${PAYLOAD})
      HAL_PRODUCT=$(echo "${HAL}" | jq -r '.lshw.product')
    fi
    HAL_PRODUCT="${HAL_PRODUCT:-unknown}"

    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- device: ${ID}; hzn: ${HZN_STATUS}; entity: ${ENTITY:-}; started: ${STARTED}; download: ${WAN_DOWNLOAD}; percent: ${CPU_PERCENT}; product: ${HAL_PRODUCT}" &> /dev/stderr; fi

    if [ ! -z "${ID:-}" ]; then
      THIS=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
    else
      THIS='null'
    fi
    if [ -z "${THIS}" ] || [ "${THIS}" = 'null' ]; then
      TOTAL_RECEIVED=0
      TOTAL_SEEN=0
      MOCK=0
      FIRST_SEEN=0
      LAST_SEEN=0
      SEEN_PER_SECOND=0
      THIS='{"id":"'${ID:-}'","entity":"'${ENTITY}'","date":'${DATE}',"started":'${STARTED}',"count":'${TOTAL_RECEIVED}',"mock":'${MOCK}',"seen":'${TOTAL_SEEN}',"first":'${FIRST_SEEN}',"last":'${LAST_SEEN}',"average":'${SEEN_PER_SECOND:-0}',"download":'${WAN_DOWNLOAD:-0}',"percent":'${CPU_PERCENT:-0}',"product":"'${HAL_PRODUCT:-unknown}'"}'
      DEVICES=$(echo "${DEVICES}" | jq '.+=['"${THIS}"']')
    else
      TOTAL_RECEIVED=$(echo "${THIS}" | jq '.count') || TOTAL_RECEIVED=0
      MOCK=$(echo "${THIS}" | jq '.mock') || MOCK=0
      TOTAL_SEEN=$(echo "${THIS}" | jq '.seen') || TOTAL_SEEN=0
      FIRST_SEEN=$(echo "${THIS}" | jq '.first') || FIRST_SEEN=0
      SEEN_PER_SECOND=$(echo "${THIS}" | jq '.average') || SEEN_PER_SECOND=0
    fi

    if [ $(jq '.yolo2msghub.yolo!=null' ${PAYLOAD}) = true ]; then
      if [ $(jq -r '.yolo2msghub.yolo.mock' ${PAYLOAD}) = 'null' ]; then
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- ${ID}: non-mock" &> /dev/stderr; fi
        WHEN=$(jq -r '.yolo2msghub.yolo.date' ${PAYLOAD})
        if [ ${WHEN} -gt ${LAST_SEEN} ]; then
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- ${ID}: new payload" &> /dev/stderr; fi
          SEEN=$(jq -r '.yolo2msghub.yolo.count' ${PAYLOAD})
          jq -r '.yolo2msghub.yolo.image' ${PAYLOAD} | base64 --decode > ${0##*/}.$$.${ID}.jpeg
          if [ ${SEEN} -gt 0 ]; then
	    # increment total entities seen
            TOTAL_SEEN=$((TOTAL_SEEN+SEEN))
	    # track when
	    LAST_SEEN=${WHEN}
	    AGO=$((NOW-LAST_SEEN))
            echo "### DATA $0 $$ -- ${ID}; ago: ${AGO:-0}; ${ENTITY} seen: ${SEEN}" &> /dev/stderr
            # calculate interval
	    if [ "${FIRST_SEEN:-0}" -eq 0 ]; then FIRST_SEEN=${LAST_SEEN}; fi
	    INTERVAL=$((LAST_SEEN-FIRST_SEEN))
	    if [ ${INTERVAL} -eq 0 ]; then 
              FIRST_SEEN=${WHEN}
	      INTERVAL=0
	      SEEN_PER_SECOND=1.0
	    else
	      SEEN_PER_SECOND=$(echo "${TOTAL_SEEN}/${INTERVAL}" | bc -l)
            fi
            THIS=$(echo "${THIS}" | jq '.date='${NOW}'|.interval='${INTERVAL:-0}'|.ago='${AGO:-0}'|.seen='${TOTAL_SEEN:-0}'|.last='${LAST_SEEN:-0}'|.first='${FIRST_SEEN:-0}'|.average='${SEEN_PER_SECOND:-0})
          else
            if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- ${ID} at ${WHEN}; did not see: ${ENTITY:-null}" &> /dev/stderr; fi
          fi
	else
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- old payload" &> /dev/stderr; fi
        fi
      else
        echo "+++ WARN $0 $$ -- ${ID} at ${WHEN}: mock" $(jq -c '.yolo2msghub.yolo.detected' ${PAYLOAD}) &> /dev/stderr
        MOCK=$((MOCK+1)) && THIS=$(echo "${THIS}" | jq '.mock='${MOCK})
      fi
    else
      echo "+++ WARN $0 $$ -- ${ID} at ${WHEN}: no yolo output" &> /dev/stderr
    fi
    echo ">>> $0 $$ -- $(date +%T)"
    TOTAL_RECEIVED=$((TOTAL_RECEIVED+1)) && THIS=$(echo "${THIS}" | jq '.count='${TOTAL_RECEIVED})
    DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")
    DEVICES=$(echo "${DEVICES}" | jq '.|sort_by(.average)|reverse')
    echo "${DEVICES}" | jq '.|first'
    count=$(echo "${DEVICES}" | jq '.|length')
    if [ ${count:-0}  -gt 1 ]; then
      echo "${DEVICES}" | jq -c ".|sort_by(.date)[]"
    fi
done
rm -f ${0##*/}.$$.*
