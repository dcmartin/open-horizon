#!/bin/bash

# set -o nounset  # Exit script on use of an undefined variable
# set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells

###
### parent functions
###

source /usr/bin/service-tools.sh
source /usr/bin/apache-tools.sh

###
### FUNCTIONS
###

mqtt_pub()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ -z "${MQTT_DEVICE:-}" ]; then MQTT_DEVICE=$(hostname) && hzn.log.debug "MQTT_DEVICE unspecified; using hostname: ${MQTT_DEVICE}"; fi
  ARGS=${*}
  if [ ! -z "${ARGS}" ]; then
    hzn.log.trace "got arguments: ${ARGS}"
    if [ ! -z "${HZNMONITOR_MQTT_USERNAME}" ]; then
      ARGS='-u '"${HZNMONITOR_MQTT_USERNAME}"' '"${ARGS}"
      hzn.log.trace "set username: ${ARGS}"
    fi
    if [ ! -z "${HZNMONITOR_MQTT_PASSWORD}" ]; then
      ARGS='-P '"${HZNMONITOR_MQTT_PASSWORD}"' '"${ARGS}"
      hzn.log.trace "set password: ${ARGS}"
    fi
    hzn.log.debug "publishing as ${MQTT_DEVICE} to ${HZNMONITOR_MQTT_HOST} port ${HZNMONITOR_MQTT_PORT} using arguments: ${ARGS}"
    mosquitto_pub -i "${MQTT_DEVICE}" -h "${HZNMONITOR_MQTT_HOST}" -p "${HZNMONITOR_MQTT_PORT}" ${ARGS}
  else
    hzn.log.notice "nothing to send"
  fi
}

## process a status payload from any conformant pattern/service
hznmonitor_process_payload()
{
  hzn.log.trace "${FUNCNAME[0]}"

  NOW=$(date +%s)
  DEVICES="${*}"
  BUFFER=$(cat)

  if [ ! -z "${BUFFER}" ]; then
    PAYLOAD=$(mktemp -t "${0##*/}-${FUNCNAME[0]}-XXXXXX")
    echo "${BUFFER}"  > ${PAYLOAD}

    BYTES=$(wc -c ${PAYLOAD} | awk '{ print $1 }')
    TOTAL_BYTES=$((TOTAL_BYTES+BYTES))
    ELAPSED=$((NOW-BEGIN))

    if [ ${ELAPSED} -ne 0 ]; then BPS=$(echo "${TOTAL_BYTES} / ${ELAPSED}" | bc -l); else BPS=1; fi
    hzn.log.trace "### DATA $0 $$ -- received at: $(date +%T); bytes: ${BYTES}; total bytes: ${TOTAL_BYTES}; bytes/sec: ${BPS}"

    # get payload generic
    DATE=$(jq -r '.date' ${PAYLOAD})
    STARTED=$((NOW-DATE))

    # breakdown payload
    if [ $(jq '.hzn?!=null' ${PAYLOAD}) = true ]; then 
      ID=$(jq -r '.hzn.device_id' ${PAYLOAD})
      DEV_EXCHANGE=$(jq -r '.hzn.exchange_url' ${PAYLOAD})
      DEV_ORGANIZATION=$(jq -r '.hzn.organization' ${PAYLOAD})
      DEV_PATTERN=$(jq -r '.hzn.pattern' ${PAYLOAD})
      DEV_HORIZON=$(jq '.hzn' ${PAYLOAD}) && HOST_IPS=$(echo "${DEV_HORIZON}" | jq -c '.host_ips')
    fi
    # CONFIG
    if [ $(jq '.config?!=null' ${PAYLOAD}) = true ]; then 
      DEV_CONFIG=$(jq '.config' ${PAYLOAD})
      # find services
      DEV_SERVICES=$(echo "${DEV_CONFIG}" | jq -r '.services[].name')
      for DS in ${DEV_SERVICES}; do
	case ${DS} in
	  wan)
	    if [ $(jq '.wan?!=null' ${PAYLOAD}) = true ]; then 
	      WAN=$(jq '.wan' ${PAYLOAD}) && WAN_DOWNLOAD=$(echo "${WAN}" | jq -r '.speedtest.download')
	      WAN_LATITUDE=$(jq '.wan' ${PAYLOAD}) && WAN_LATITUDE=$(echo "${WAN_LATITUDE}" | jq -r '.speedtest.client.lat')
	      WAN_LONGITUDE=$(jq '.wan' ${PAYLOAD}) && WAN_LONGITUDE=$(echo "${WAN_LONGITUDE}" | jq -r '.speedtest.client.lon')
            fi
	    ;;
	  hal)
	    if [ $(jq '.hal?!=null' ${PAYLOAD}) = true ]; then HAL=$(jq '.hal' ${PAYLOAD}) && HAL_PRODUCT=$(echo "${HAL}" | jq -r '.lshw.product'); fi
	    ;;
	  cpu)
	    if [ $(jq '.cpu?!=null' ${PAYLOAD}) = true ]; then CPU=$(jq '.cpu' ${PAYLOAD}) && CPU_PERCENT=$(echo "${CPU}" | jq -r '.percent'); fi
	    ;;
	  *)
	    hzn.log.warn "unknown service: ${DS}"
	    ;; 
	esac
      done
    fi

    hzn.log.trace "device: ${ID:-undefined}; started: ${STARTED}; ips: [${HOST_IPS:-}]; download: ${WAN_DOWNLOAD:-undefined}; percent: ${CPU_PERCENT:-undefined}; product: ${HAL_PRODUCT:-undefined}"

    # have we seen this before
    if [ ! -z "${ID:-}" ] && [ ! -z "${DEVICES:-}" ] && [ "${DEVICES}" != '[]' ]; then
      hzn.log.trace "LOOKING FOR ${ID}"
      THIS=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
      if [ -z "${THIS}" ]; then
        hzn.log.trace "DID NOT FIND ${ID}"
      fi
    fi
    if [ -z "${THIS}" ]; then
      THIS='{"id":"'${ID}'","count":'${COUNT:-0}',"hzn":{"url":"'${DEV_EXCHANGE:-}'","org":"'${DEV_ORGANIZATION:-}'","pattern":"'${DEV_PATTERN:-}'"},"ips":'${HOST_IPS:-null}',"download":'${WAN_DOWNLOAD:-0}',"latitude":'${WAN_LATITUDE:-0.0}',"longitude":'${WAN_LONGITUDE:-0.0}',"percent":'${CPU_PERCENT:-0}',"product":"'${HAL_PRODUCT:-unknown}'"}'
    fi

    # increment count
    COUNT=$(echo "${THIS}" | jq '.count') || COUNT=0
    COUNT=$((COUNT+1)) && THAT=$(echo "${THIS}" | jq '.count='${COUNT}) && THIS="${THAT}"

    # process startup payload
    THAT=$(cat ${PAYLOAD} | hznmonitor_process_startup ${THIS}) && THIS="${THAT}"

    # send copy of payload
    hzn.log.trace "sending payload to topic ${HZNMONITOR_MQTT_TOPIC}/payload"
    mqtt_pub -t "${HZNMONITOR_MQTT_TOPIC}/payload" -f ${PAYLOAD}

    # remove payload
    rm -f ${PAYLOAD}
  else
    hzn.log.trace  "received null payload:" $(date +%T)
    THIS=
  fi
  echo "${THIS:-}"
}

hznmonitor_process_startup()
{
  hzn.log.trace "${FUNCNAME[0]}"

  THIS="${*}"
  PAYLOAD=$(mktemp -t "${0##*/}-${FUNCNAME[0]}-XXXXXX")
  cat > ${PAYLOAD}
  ID=$(jq -r '.hzn.device_id' ${PAYLOAD})
  WHEN=$(jq -r '.date' ${PAYLOAD})

  NODE_FIRST=$(echo "${THIS}" | jq -r '.first?') && if [ "${NODE_FIRST}" = 'null' ]; then NODE_FIRST=0; fi
  NODE_LAST=${WHEN}

  # get count
  CONTAINERS_COUNT=$(echo "${THIS}" | jq '.containers') || CONTAINERS_COUNT=0

  # process payload
  if [ $(jq '.startup.docker!=null' ${PAYLOAD}) = true ]; then
    hzn.log.trace "${ID}: docker is true"
    CONTAINERS=$(jq '.startup.docker.containers|length' ${PAYLOAD})
    CONTAINERS_COUNT=$((CONTAINERS_COUNT+CONTAINERS))
  else
    hzn.log.warn "${ID}: no docker output"
  fi
  # increment count of measurements
  COUNT=$(echo "${THIS}" | jq '.count') && CONTAINERS_AVERAGE=$((CONTAINERS_COUNT/COUNT))

  # calculate interval
  if [ "${NODE_FIRST:-0}" -eq 0 ]; then NODE_FIRST=${NODE_LAST}; fi

  # get periodicity of client
  client_period=$(jq '.config.period' ${PAYLOAD})
  config_timestamp=$(jq -r '.config.timestamp' ${PAYLOAD})
  client_timestamp=$(jq -r '.timestamp' ${PAYLOAD})
 
   # build record
   THAT=$(echo "${THIS}" | jq '.sent="'${client_timestamp}'"|.configure="'${config_timestamp}'"|.timestamp="'$(date -u +%FT%TZ)'"|.id="'${ID}'"|.period='${client_period}'|.date='${WHEN:-0}'|.containers='${CONTAINERS_COUNT:-0}'|.last='${NODE_LAST:-0}'|.first='${NODE_FIRST:-0}'|.average='${CONTAINERS_AVERAGE:-0})
   THIS="${THAT}"

  # finish
  rm -f ${PAYLOAD}
  echo "${THIS}"
}

## update service
hznmonitor_service_update()
{
  hzn.log.trace "${FUNCNAME[0]}"

    # test for PID file
    if [ ! -z "${APACHE_PID_FILE:-}" ]; then
      if [ -s "${APACHE_PID_FILE}" ]; then
	PID=$(cat ${APACHE_PID_FILE})
      else
	hzn.log.warn "empty PID file: ${APACHE_PID_FILE}"
      fi
    else
      hzn.log.warn "no PID file defined"
    fi
    # create output
    TEMP=$(mktemp -t "${0##*/}-${FUNCNAME[0]}-XXXXXX")
    echo -n '{"pid":'${PID:-0}',"status":"' > ${TEMP}
    curl -sSL "localhost:${APACHE_PORT}/server-status" | base64 -w 0 >> ${TEMP}
    echo '"}' >> ${TEMP}
    service_update ${TEMP}
    rm -f ${TEMP}
}

hznmonitor_poll()
{
  hzn.log.trace "${FUNCNAME[0]}"

  # globals
  DEVICES=
  TOTAL_BYTES=0
  BEGIN=$(date +%s)
  TEMP=$(mktemp -t "${0##*/}-${FUNCNAME[0]}-XXXXXX")

  hzn.log.notice "listening: ${HZNMONITOR_KAFKA_TOPIC:-unspecified}; ${HZNMONITOR_KAFKA_APIKEY:-unspecified}; ${HZNMONITOR_KAFKA_BROKER:-unspecified}"
  kafkacat -E -u -C -q -o end -f "%s\n" -b "${HZNMONITOR_KAFKA_BROKER}" \
    -X "security.protocol=sasl_ssl" \
    -X "sasl.mechanisms=PLAIN" \
    -X "sasl.username=${HZNMONITOR_KAFKA_APIKEY:0:16}" \
    -X "sasl.password=${HZNMONITOR_KAFKA_APIKEY:16}" \
    -t "${HZNMONITOR_KAFKA_TOPIC}" | while read -r; do

    # process payload into summary
    THIS=$(echo "${REPLY}" | hznmonitor_process_payload "${DEVICES}")

    # check for null payload
    if [ ! -z "${THIS}" ]; then
      # check for existing devices
      if [ ! -z "${DEVICES}" ]; then
	ID=$(echo "${THIS}" | jq -r '.id')
	THAT=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
	if [ ! -z "${THAT}" ]; then
	  hzn.log.trace "updating device ${ID}"
	  DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")
	else
	  hzn.log.trace "adding device ${ID}"
	  DEVICES=$(echo "${DEVICES}" | jq '.+=['"${THIS}"']')
	fi
      else
	hzn.log.warn "no existing devices"
	DEVICES='['"${THIS}"']'
      fi 

      # sort devices
      DEVICES=$(echo "${DEVICES}" | jq '.|sort_by(.timestamp|strptime("%FT%TZ")|mktime)|reverse')
      # filter devices older than HZNMONITOR_PERIOD seconds from most recent
      DEVICES=$(echo "${DEVICES}" | jq -c '. as $u|.|first|.timestamp|strptime("%FT%TZ")|mktime as $t|[$u[]|select(.timestamp|strptime("%FT%TZ")|mktime > ($t - '${HZNMONITOR_PERIOD}'))]')

      # create JSON summary output payload
      echo "${DEVICES}" | jq -c '{"'${HZNMONITOR_MQTT_TOPIC}'":{"period":'${HZNMONITOR_PERIOD}',"timestamp":"'$(date -u +%FT%TZ)'","date":"'$(date +%s)'","activity":.}}' > ${TEMP}

      # send summary payload
      mqtt_pub -t ${HZNMONITOR_MQTT_TOPIC} -f ${TEMP}
      # copy summary data to well-known location
      cp -f ${TEMP} ${APACHE_LOG_DIR}/activity.json
      chmod 644 ${APACHE_LOG_DIR}/activity.json
    fi
    # check APACHE?
    if [ ${APACHE_PERIOD:-30} -gt ${ELAPSED:-0} ]; then
       hznmonitor_service_update
    fi
  done
  rm -f ${TEMP}
}

###
### MAIN
###

## initialize horizon
hzn.log.notice "initializing horizon"
hzn_init

## defaults
if [ -z "${APACHE_PID_FILE:-}" ]; then export APACHE_PID_FILE="/var/run/apache2.pid"; fi
if [ -z "${APACHE_RUN_DIR:-}" ]; then export APACHE_RUN_DIR="/var/run/apache2"; fi
if [ -z "${APACHE_ADMIN:-}" ]; then export APACHE_ADMIN="${HZN_ORG_ID}"; fi

## configuration
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","period":'${HZNMONITOR_PERIOD:-900}',"tmpdir":"'${TMPDIR}'", "logto":"'${LOGTO:-}'", "log_level":"'${LOG_LEVEL:-}'", "services":'"${SERVICES:-null}"', "debug":'${DEBUG:-true}', "org":"'${HZNMONITOR_EXCHANGE_ORG:-none}'", "exchange":"'${HZNMONITOR_EXCHANGE_URL:-none}'", "db":"'${HZNMONITOR_DB}'", "username":"'${HZNMONITOR_DB_USERNAME:-none}'", "apache":{"conf":"'${APACHE_CONF}'", "htdocs": "'${APACHE_HTDOCS}'", "cgibin": "'${APACHE_CGIBIN}'", "host": "'${APACHE_HOST}'", "port": "'${APACHE_PORT}'", "admin": "'${APACHE_ADMIN}'", "pidfile":"'${APACHE_PID_FILE:-none}'", "rundir":"'${APACHE_RUN_DIR:-none}'"}, "kafka":{"admin":"'${HZNMONITOR_KAFKA_ADMIN_URL:-unspecified}'", "broker":"'${HZNMONITOR_KAFKA_BROKER:-unspecified}'", "apikey":"'${HZNMONITOR_KAFKA_APIKEY:-unspecified}'", "topic":"'${HZNMONITOR_KAFKA_TOPIC:-unspecified}'"}, "mqtt":{"host":"'${HZNMONITOR_MQTT_HOST:-unspecified}'", "port":'${HZNMONITOR_MQTT_PORT:-1883}', "username":"'${HZNMONITOR_MQTT_USERNAME:-unspecified}'", "password":"'${HZNMONITOR_MQTT_PASSWORD:-unspecified}'", "topic":"'${HZNMONITOR_MQTT_TOPIC:-unspecified}'"}}'

## initialize service
hzn.log.notice "initializing service" $(echo "${CONFIG}" | jq -c '.')
service_init ${CONFIG}

## setup environment for apache CGI scripts
export HZNMONITOR_EXCHANGE_APIKEY="${HZNMONITOR_EXCHANGE_APIKEY:-none}"
export HZNMONITOR_EXCHANGE_URL="${HZNMONITOR_EXCHANGE_URL:-none}"
export HZNMONITOR_EXCHANGE_ORG="${HZNMONITOR_EXCHANGE_ORG:-none}"
export HZNMONITOR_EXCHANGE_USER="${HZNMONITOR_EXCHANGE_USER:-none}"

# start apache
apache_start HZNMONITOR_EXCHANGE_URL HZNMONITOR_EXCHANGE_APIKEY HZNMONITOR_EXCHANGE_ORG HZNMONITOR_EXCHANGE_USER HZNMONITOR_DB HZNMONITOR_DB_USERNAME HZNMONITOR_DB_PASSWORD

# update service
hznmonitor_service_update

# forever poll
while true; do
  # run
  hznmonitor_poll
done
