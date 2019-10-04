#!/usr/bin/env bash

source /usr/bin/hzn-tools.sh

kafka_make_topic()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  topic=
  if [ ! -z "${1:-}" ]; then 
    topic='{"name":"'${1}'"}'
    response=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${STARTUP_KAFKA_APIKEY:-}" "${STARTUP_KAFKA_ADMIN_URL:-}/admin/topics" -d "${topic}")
    if [ "$(echo "${response}" | jq '.errorCode!=null')" == 'true' ]; then
      hzn.log.warn "topic: ${topic}; message:" $(echo "${response}" | jq -r '.errorMessage')
    fi
  fi
  echo "${topic}"
}

kafka_send_payload()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  RESULT=
  if [ ! -z "${1}" ] && [ -e "${1}" ]; then
    JSON="${1}"
    # package output for Kafka (single-line)
    PAYLOAD=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    jq -c '.' ${JSON} > ${PAYLOAD}
    hzn.log.debug "payload size:" $(wc -c ${PAYLOAD})
    if [ -s ${PAYLOAD} ]; then 
      kafkacat "${PAYLOAD}" \
        -P \
        -b "${STARTUP_KAFKA_BROKER}" \
        -X api.version.request=true \
        -X security.protocol=sasl_ssl \
        -X sasl.mechanisms=PLAIN \
        -X sasl.username=${STARTUP_KAFKA_APIKEY:0:16}\
        -X sasl.password="${STARTUP_KAFKA_APIKEY:16}" \
        -t "${STARTUP_KAFKA_TOPIC}"
      RESULT=$?
    else
      hzn.log.warn "zero-sized payload: ${PAYLOAD}"
    fi
    rm -f ${PAYLOAD}
  fi
  echo "${RESULT:-1}"
}

kafka_send_output()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  RESULT=
  if [ $(command -v kafkacat) ] && [ ! -z "${STARTUP_KAFKA_BROKER}" ] && [ ! -z "${STARTUP_KAFKA_APIKEY}" ]; then
    # get the combined service output
    TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    service_output ${TEMP}
    hzn.log.debug "service_output size:" $(wc -c ${TEMP})
    # process output
    if [ -s ${TEMP} ]; then
      RESULT=$(kafka_send_payload ${TEMP})
    else
      hzn.log.warn "zero-sized service_output: ${TEMP}"
    fi
    rm -f ${TEMP}
  else
    hzn.log.warn "kafka invalid"
  fi
  echo "${RESULT:-1}"
}
