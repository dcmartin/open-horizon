#!/bin/bash

if [ ! -z "${1:-}" ]; then
  OUTPUT="${1}"
else
  OUTPUT=/dev/stdout
fi

BROKER="kafka05-prod02.messagehub.services.us-soutbluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093"

REQUIRED_VARIABLES=STARTUP_KAFKA_APIKEY
for R in ${REQUIRED_VARIABLES}; do
  if [ ! -s "${R}" ]; then echo "*** ERROR $0 $$ -- required variable ${R} file not found; exiting" &> /dev/stderr; fi
  APIKEY=$(sed -e 's|^["]*\([^"]*\)["]*|\1|' "${R}")
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- set ${R} to ${APIKEY}" &> /dev/stderr; fi
done

TOPIC=${STARTUP_KAFKA_TOPIC:-"startup"}
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
      VALID=$(echo "${REPLY}" | ./test-startup.sh 2> ${PAYLOAD%.*}.out)
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
    CONTAINER_COUNT=$(jq '.startup.docker.containers|length' ${PAYLOAD})
    if [ ${CONTAINER_COUNT:-0} -gt 0 ]; then
      CONTAINER_ARRAY=$(jq '[.startup.docker.containers[].inspect.Name]' ${PAYLOAD})
    else
      jq '.startup.docker' ${PAYLOAD}
      CONTAINER_ARRAY='[]'
    fi

    DATE=$(jq -r '.date' ${PAYLOAD})
    STARTED=$((NOW-DATE))

    # HZN
    if [ $(jq '.hzn?!=null' ${PAYLOAD}) = true ]; then
      HZN=$(jq '.hzn' ${PAYLOAD})
      HZN_STATUS=$(echo "${HZN}" | jq -c '.')
    fi
    HZN_STATUS=${HZN_STATUS:-[]}

    # WAN
    if [ $(jq '.wan?!=null' ${PAYLOAD}) = true ]; then
      WAN=$(jq '.wan' ${PAYLOAD})
      WAN_DOWNLOAD=$(echo "${WAN}" | jq -r '.speedtest.download')
    fi
    WAN_DOWNLOAD=${WAN_DOWNLOAD:-0}

    # HAL
    if [ $(jq '.hal?!=null' ${PAYLOAD}) = true ]; then
      HAL=$(jq '.hal' ${PAYLOAD})
      HAL_PRODUCT=$(echo "${HAL}" | jq -r '.lshw.product')
    fi
    HAL_PRODUCT="${HAL_PRODUCT:-unknown}"

    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- device: ${ID}; hzn: ${HZN_STATUS}; containers: ${CONTAINER_ARRAY:-}; started: ${STARTED}; download: ${WAN_DOWNLOAD}; product: ${HAL_PRODUCT}" &> /dev/stderr; fi

    if [ ! -z "${ID:-}" ]; then
      THIS=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
    else
      THIS='null'
    fi
    if [ -z "${THIS}" ] || [ "${THIS}" = 'null' ]; then
      TOTAL_RECEIVED=0
      TOTAL_CONTAINERS=0
      FIRST_SEEN=0
      LAST_SEEN=0
      CONTAINERS_AVERAGE=0
      THIS='{"id":"'${ID:-}'","containers":'${CONTAINER_ARRAY:-[]}',"date":'${DATE}',"started":'${STARTED}',"count":'${TOTAL_RECEIVED}',"seen":'${TOTAL_CONTAINERS}',"first":'${FIRST_SEEN}',"last":'${LAST_SEEN}',"average":'${CONTAINERS_AVERAGE:-0}',"download":'${WAN_DOWNLOAD:-0}',"product":"'${HAL_PRODUCT:-unknown}'"}'
      DEVICES=$(echo "${DEVICES}" | jq '.+=['"${THIS}"']')
    else
      TOTAL_RECEIVED=$(echo "${THIS}" | jq '.count') || TOTAL_RECEIVED=0
      TOTAL_CONTAINERS=$(echo "${THIS}" | jq '.seen') || TOTAL_CONTAINERS=0
      FIRST_SEEN=$(echo "${THIS}" | jq '.first') || FIRST_SEEN=0
      CONTAINERS_AVERAGE=$(echo "${THIS}" | jq '.average') || CONTAINERS_AVERAGE=0
    fi

    if [ $(jq '.startup.docker!=null' ${PAYLOAD}) = true ]; then
      WHEN=$(jq -r '.startup.date' ${PAYLOAD})
      if [ ${WHEN} -gt ${LAST_SEEN} ]; then
        TOTAL_RECEIVED=$((TOTAL_RECEIVED+1)) && THIS=$(echo "${THIS}" | jq '.count='${TOTAL_RECEIVED})
	if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- ${ID}: new payload" &> /dev/stderr; fi
	CONTAINERS=$(jq -r '.startup.docker.containers|length' ${PAYLOAD})
	# jq -r '.startup.docker.image' ${PAYLOAD} | base64 --decode > ${0##*/}.$$.${ID}.jpeg
	if [ ${CONTAINERS} -gt 0 ]; then
	  # increment total entities seen
	  TOTAL_CONTAINERS=$((TOTAL_CONTAINERS+CONTAINERS))
	  # track when
	  LAST_SEEN=${WHEN}
	  AGO=$((NOW-LAST_SEEN))
	  echo "### DATA $0 $$ -- ${ID}; ago: ${AGO:-0}; containers: ${CONTAINERS}" &> /dev/stderr
	  # calculate interval
	  if [ "${FIRST_SEEN:-0}" -eq 0 ]; then FIRST_SEEN=${LAST_SEEN}; fi
	  INTERVAL=$((LAST_SEEN-FIRST_SEEN))
	  if [ ${TOTAL_RECEIVED} -eq 1 ]; then 
	    FIRST_SEEN=${WHEN}
	    INTERVAL=0
	  fi
	  CONTAINERS_AVERAGE=$(echo "${TOTAL_CONTAINERS}/${TOTAL_RECEIVED}" | bc -l)
	  THIS=$(echo "${THIS}" | jq '.date='${NOW}'|.interval='${INTERVAL:-0}'|.ago='${AGO:-0}'|.seen='${TOTAL_CONTAINERS:-0}'|.last='${LAST_SEEN:-0}'|.first='${FIRST_SEEN:-0}'|.average='${CONTAINERS_AVERAGE:-0})
	else
	  if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- ${ID} at ${WHEN}; did not see: ${CONTAINER_ARRAY:-[]}" &> /dev/stderr; fi
	fi
      else
	if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- old payload" &> /dev/stderr; fi
      fi
    else
      echo "+++ WARN $0 $$ -- ${ID} at ${WHEN}: no docker output" &> /dev/stderr
    fi
    DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")
    echo "${DEVICES}" | jq -c '{"nodes":.|sort_by(.date)}' > "${OUTPUT}"
done
rm -f ${0##*/}.$$.*
