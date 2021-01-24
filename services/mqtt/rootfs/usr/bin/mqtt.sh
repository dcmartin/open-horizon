#!/usr/bin/with-contenv bashio

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

mqtt::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  ## configure service(s)
  local config='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-info}'","host":"'${MQTT_HOST:-}'","period":"'${MQTT_PERIOD:-60}'","services":'"${SERVICES:-null}"'}'

  ## initialize horizon
  hzn::init
  hzn::log.notice "${FUNCNAME[0]}: initializing service: ${SERVICE_LABEL:-}" $(echo "${config}" | jq -c '.' || echo "INVALID: ${config}")
  hzn::service.init ${config}

  # start MQTT broker as daemon
  mosquitto -c /etc/mosquitto.conf &> /dev/null &
  local PID=$!

  if [ ${PID:-0} -le 0 ]; then 
    hzn::log.fatal "${FUNCNAME[0]}: mosquitto did not start"
  else
    local output_file=$(mktemp)
    local version
    local DATE=$(date +%s)

    # iterate forever
    while true; do
      # re-initialize
      local OP='{}'

      # set PID
      OP=$(echo "${OP}" | jq '.pid='${PID})
      # get MQTT version
      version=$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/version')
      OP=$(echo "${OP}" | jq '.version="'"${version:-null}"'"')
  
      # get MQTT stats
      OP=$(echo "${OP}" | jq '.broker.bytes.received='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/bytes/received'))
      OP=$(echo "${OP}" | jq '.broker.bytes.sent='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/bytes/sent'))
      OP=$(echo "${OP}" | jq '.broker.clients.connected='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/clients/connected'))
      OP=$(echo "${OP}" | jq '.broker.load.messages.sent.one='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/load/messages/sent/1min'))
      OP=$(echo "${OP}" | jq '.broker.load.messages.sent.five='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/load/messages/sent/5min'))
      OP=$(echo "${OP}" | jq '.broker.load.messages.sent.fifteen='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/load/messages/sent/15min'))
      OP=$(echo "${OP}" | jq '.broker.load.messages.received.one='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/load/messages/received/1min'))
      OP=$(echo "${OP}" | jq '.broker.load.messages.received.five='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/load/messages/received/5min'))
      OP=$(echo "${OP}" | jq '.broker.load.messages.received.fifteen='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/load/messages/received/15min'))
      OP=$(echo "${OP}" | jq '.broker.publish.messages.received='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/publish/messages/received'))
      OP=$(echo "${OP}" | jq '.broker.publish.messages.sent='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/publish/messages/sent'))
      OP=$(echo "${OP}" | jq '.broker.publish.messages.dropped='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/publish/messages/dropped'))
      OP=$(echo "${OP}" | jq '.broker.subscriptions.count='$(mosquitto_sub -C 1 -h "localhost" -t '$SYS/broker/subscriptions/count'))
  
      # update output
      echo "${OP}" | jq -c '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) > "${output_file}"
      hzn::service.update "${output_file}"
  
      # wait for ..
      SECONDS=$((MQTT_PERIOD - $(($(date +%s) - DATE))))
      if [ ${SECONDS} -gt 0 ]; then
        sleep ${SECONDS}
      fi
    done
  fi
}

###
### MAIN
###

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

# debugging only
if [ -z "${MQTT_HOST:-}" ]; then export MQTT_HOST="localhost"; fi
if [ -z "${MQTT_PERIOD:-}" ]; then export MQTT_PERIOD=30; fi

hzn::log.notice "Starting ${0} ${*}: ${SERVICE_LABEL:-null}; version: ${SERVICE_VERSION:-null}"

mqtt::main ${*}

exit 1
