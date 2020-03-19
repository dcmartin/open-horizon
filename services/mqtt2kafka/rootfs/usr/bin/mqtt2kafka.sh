#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

## source tools
source /usr/bin/kafka-tools.sh
source /usr/bin/service-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## configure service
SERVICES='[{"name":"wan","url":"http://wan"},{"name":"mqtt","url":"http://mqtt"}]'
MQTT='{"host":"'${MQTT_HOST:-}'","port":'${MQTT_PORT:-1883}',"username":"'${MQTT_USERNAME:-}'","password":"'${MQTT_PASSWORD:-}'"}'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"subscribe":"'${MQTT2KAFKA_SUBSCRIBE}'","payload":"'${MQTT2KAFKA_PAYLOAD}'","publish":"'${MQTT2KAFKA_PUBLISH}'","services":'"${SERVICES}"',"mqtt":'"${MQTT:-null}"',"wan":'"${WAN:-null}"'}'

## initialize servive
service_init ${CONFIG}

## MQTT arguments
MOSQUITTO_ARGS="-h ${MQTT_HOST} -p ${MQTT_PORT}"
if [ ! -z "${MQTT_USERNAME:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -u ${MQTT_USERNAME}"; fi
if [ ! -z "${MQTT_PASSWORD:-}" ]; then MOSQUITTO_ARGS="${MOSQUITTO_ARGS} -P ${MQTT_PASSWORD}"; fi

## initial output
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update ${OUTPUT_FILE}

if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- listening to ${MQTT_HOST} on topic: ${MQTT2KAFKA_SUBSCRIBE}" &> /dev/stderr; fi

# listen forever
mosquitto_sub -v ${MOSQUITTO_ARGS} -t "${MQTT2KAFKA_SUBSCRIBE}" | while read; do
  # test for null
  if [ ! -z "${REPLY}" ]; then 
    TOPIC_PUB=$(echo "${REPLY}" | sed 's/\([^ ]*\) .*/\1/')
    if [ -z "${MQTT2KAFKA_PUBLISH:-}" ]; then
      TOPIC="${TOPIC_PUB}"
    else
      TOPIC="${MQTT2KAFKA_PUBLISH}"
    fi
    # ensure topic exists
    if [ -z "$(kafka_mktopic ${TOPIC})" ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- failed to create Kafka topic: ${TOPIC}" &> /dev/stderr; fi
      continue
    fi
    # name image payload
    PAYLOAD="$(mktemp -t "${0##*/}-XXXXXX")"
    echo "${REPLY}" | sed 's/[^ ]* \(.*\)/\2/' > ${PAYLOAD}
    if [ -s "${PAYLOAD}" ]; then
      DATE=$(jq -r '.date' ${PAYLOAD})
      if [ -z "${DATE}" ] || [ "${DATE}" == 'null' ]; then DATE=0; fi
      NOW=$(date +%s)
      if [ $((NOW - DATE)) -gt ${MQTT2KAFKA_TOO_OLD} ]; then echo "+++ WARN -- $0 $$ -- too old: $((NOW-DATE)) > ${MQTT2KAFKA_TOO_OLD}" &> /dev/stderr; continue; fi
    else
      # null
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- MQTT received; topic: ${TOPIC}; payload: null" &> /dev/stderr; fi
      rm -f ${PAYLOAD}
      continue
    fi
  else
    # null
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- MQTT received; topic ${MQTT2KAFKA_SUBSCRIBE};  null message" &> /dev/stderr; fi
    continue
  fi
  if [ ! -z "${MQTT2KAFKA_PAYLOAD}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- not implemented (yet); MQTT2KAFKA_PAYLOAD: ${MQTT2KAFKA_PAYLOAD}" &> /dev/stderr; fi
  fi

  # update output
  echo "${CONFIG}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s)'|.mqtt.sub="'${MQTT2KAFKA_SUBSCRIBE}'"|.mqtt.pub="'${TOPIC_PUB}'"|.kafka.topic="'${TOPIC}'"' > ${OUTPUT_FILE}
  service_update ${OUTPUT_FILE}

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${MQTT2KAFKA_BROKER}" ] && [ ! -z "${MQTT2KAFKA_APIKEY}" ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG $0 $$ -- payload:" $(jq -c '.' ${PAYLOAD}) &> /dev/stderr; fi
      kafkacat "${PAYLOAD}" \
          -P \
          -b "${MQTT2KAFKA_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=${MQTT2KAFKA_APIKEY:0:16}\
          -X sasl.password="${MQTT2KAFKA_APIKEY:16}" \
          -t "${TOPIC}"
      rm -f ${PAYLOAD} ${PAYLOAD_DATA:-}
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi
done
