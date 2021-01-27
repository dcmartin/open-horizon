#!/bin/bash

HZNMONITOR_KAFKA_BROKER=192.168.1.26:9092
HZNMONITOR_KAFKA_TOPIC=test

kafkacat -E -u -C -q -o end -f "%s\n" -b "${HZNMONITOR_KAFKA_BROKER}" \
    -t "${HZNMONITOR_KAFKA_TOPIC}" | while read -r; do echo "REPLY: ${REPLY:-}" &> /dev/stderr; done
