#!/bin/bash

STARTUP_KAFKA_BROKER=192.168.1.26:9092
STARTUP_KAFKA_TOPIC=test
STARTUP_KAFKA_APIKEY="1234567890123456"

PAYLOAD=$(mktemp)
echo '{"timestamp": "'$(date -u +%FT%TZ)'"}' | jq -c '.' > ${PAYLOAD}

kafkacat \
        -X api.version.request=true \
        -P \
        -b "${STARTUP_KAFKA_BROKER}" \
        -t "${STARTUP_KAFKA_TOPIC}" \
        "${PAYLOAD}"

rm -f ${PAYLOAD}
