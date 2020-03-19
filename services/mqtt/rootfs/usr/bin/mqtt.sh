#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### INITIALIZE
###

## initialize horizon
hzn_init

###
### MAIN
###

# debugging only
if [ -z "${MQTT_HOST:-}" ]; then MQTT_HOST="${SERVICE_LABEL}"; fi

## configure service(s)
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"host":"'${MQTT_HOST}'","period":"'${MQTT_PERIOD:-60}'","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG_SERVICE}

# start MQTT broker as daemon
mosquitto -d -c /etc/mosquitto.conf
# get pid
PID=$(ps | grep "mosquitto" | grep -v grep | awk '{ print $1 }' | head -1)
if [ ! -z "${PID}" ]; then 
  VER=$(mosquitto_sub -C 1 -h ${MQTT_HOST} -t '$SYS/broker/version')
fi

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"pid":'${PID:-0}',"version":"'${VER:-unknown}'"}' > "${OUTPUT_FILE}"

## update
service_update "${OUTPUT_FILE}"

# iterate forever
while true; do
  # re-initialize
  OP=$(jq -c '.' ${OUTPUT_FILE})
  # get MQTT stats
  OP=$(echo "${OP}" | jq '.broker.bytes.received='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/bytes/received'))
  OP=$(echo "${OP}" | jq '.broker.bytes.sent='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/bytes/sent'))
  OP=$(echo "${OP}" | jq '.broker.clients.connected='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/clients/connected'))
  OP=$(echo "${OP}" | jq '.broker.load.messages.sent.one='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/sent/1min'))
  OP=$(echo "${OP}" | jq '.broker.load.messages.sent.five='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/sent/5min'))
  OP=$(echo "${OP}" | jq '.broker.load.messages.sent.fifteen='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/sent/15min'))
  OP=$(echo "${OP}" | jq '.broker.load.messages.received.one='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/received/1min'))
  OP=$(echo "${OP}" | jq '.broker.load.messages.received.five='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/received/5min'))
  OP=$(echo "${OP}" | jq '.broker.load.messages.received.fifteen='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/received/15min'))
  OP=$(echo "${OP}" | jq '.broker.publish.messages.received='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/publish/messages/received'))
  OP=$(echo "${OP}" | jq '.broker.publish.messages.sent='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/publish/messages/sent'))
  OP=$(echo "${OP}" | jq '.broker.publish.messages.dropped='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/publish/messages/dropped'))
  OP=$(echo "${OP}" | jq '.broker.subscriptions.count='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/subscriptions/count'))
  # update output
  echo "${OP}" | jq '.date='$(date +%s) > "${OUTPUT_FILE}"
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((MQTT_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
