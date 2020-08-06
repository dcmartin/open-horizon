#!/bin/bash

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/kafka-tools.sh
source /usr/bin/ess-tools.sh
source /usr/bin/host-tools.sh
source /usr/bin/docker-tools.sh

## configuration file
startup_config_file()
{
  echo "${TMPDIR}/${SERVICE_LABEL}-config.json"
}

startup_sync_period()
{
  local out=$(jq -r '.sync.period'  $(startup_config_file) 2> /dev/null)
  echo "${out:-0}"
}

startup_period()
{
  jq -r '.period'  $(startup_config_file)
}


###
### MAIN
###

## initialize horizon
hzn_init

## configure service

SERVICES='[{"name":"cpu","url":"http://cpu"},{"name":"hal","url":"http://hal"},{"name":"wan","url":"http://wan"}]'
CONFIG='{"logto":"'${LOGTO}'","date":'$(date +%s)',"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${LOG_LEVEL}'","services":'${SERVICES}',"sync":{"org":"'${HZN_ORGANIZATION:-}'","period":'${STARTUP_SYNC_PERIOD:-30}'},"period":'${STARTUP_PERIOD:-300}',"kafka":{"apikey":"'${STARTUP_KAFKA_APIKEY}'","topic":"'${STARTUP_KAFKA_TOPIC:-}'","broker":"'${STARTUP_KAFKA_BROKER}'","admin":"'${STARTUP_KAFKA_ADMIN_URL}'"}}'

## initialize servive
service_init ${CONFIG}

## initialize ESS
ess_init ${HZN_ORGANIZATION:-}
if [ -z "${STARTUP_SYNC_GET:-}" ]; then STARTUP_SYNC_GET='config'; fi
if [ -z "${STARTUP_SYNC_PUT:-}" ]; then STARTUP_SYNC_PUT='status'; fi

## initial output
OUTPUT_FILE=$(mktemp -t "${0##*/}-out-XXXXXX")
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${OUTPUT_FILE}"
# let 'em know we're alive
service_update "${OUTPUT_FILE}"

# make Kafka topic
if [ ! -z $(kafka_make_topic "${STARTUP_KAFKA_TOPIC}") ]; then
  hzn::log.debug "topic ${STARTUP_KAFKA_TOPIC}; success"
else
  hzn::log.debug "topic ${STARTUP_KAFKA_TOPIC}; failure"
fi

# test if initialized properly
if [ -z "$(ess_url)" ]; then
  hzn::log.warn "no ESS service URL"
else
  health=$(ess_health)
  if [ ! -z "${health:-}" ]; then
    hzn::log.debug "ESS service health: ${health}"
  else 
    hzn::log.debug "ESS service dead"
  fi
fi

# get old objects
OBJS=$(ess_object_list ${STARTUP_SYNC_GET} true)
if [ ! -z ${OBJS:-} ] && [ "${OBJS:-}" != 'null' ]; then
  OBJIDS=$(echo "${OBJS}" | jq '.[].objectID')
  for id in ${OBJIDS}; do
    hzn::log.debug "old object: ${id}"
    data=$(ess_get_data ${TMPDIR} ${id} ${STARTUP_SYNC_GET})
    if [ ! -z "${data}" ]; then
      hzn::log.debug "object: ${id}; data: ${data}; size: " $(wc -c ${data})
    else
      hzn::log.debug "object: ${id}; no data"
    fi
  done
else
  hzn::log.debug "no old objects of type ${STARTUP_SYNC_GET}"
fi

## never inspected
INSPECT_DATE=0
## never synchronized
SYNC_DATE=0

## do forever
while true; do

  # reset for update
  UPDATED=false

  # test if synchronizing
  if [ $(startup_sync_period) -le 0 ]; then
    hzn::log.debug "not synchronizing; startup synchronization period: $(startup_sync_period)"
  elif [ $(($(startup_sync_period) - $(($(date +%s) - SYNC_DATE)))) -le 0 ]; then
    hzn::log.debug "polling for new objects: ${STARTUP_SYNC_GET}"

    # ask for new ${STARTUP_SYNC_GET} objects which have not been received
    OBJS=$(ess_object_list ${STARTUP_SYNC_GET})
    if [ ! -z "${OBJS:-}" ] && [ "${OBJS:-}" != 'null' ]; then
      OBJIDS=$(echo "${OBJS}" | jq -r '.[].objectID')
      for id in ${OBJIDS}; do
	hzn::log.debug "FOUND: ${STARTUP_SYNC_GET}; objectID: ${id}"
	file=$(ess_object_download ${id} ${STARTUP_SYNC_GET})
	if [ ! -z "${file}" ] && [ -s ${file} ]; then
	  hzn::log.info "DOWNLOAD: objectType: ${STARTUP_SYNC_GET}; objectID: ${id}; size: " $(wc -c ${file})
	  mv -f ${file} $(startup_config_file)
	  SYNC_DATE=$(date +%s)
	  UPDATED=true
	else
	  hzn::log.debug "object: ${id}; no data"
	  if [ ! -z "${file:-}" ]; then rm -f "${file}"; fi
	fi
      done
    else
      hzn::log.debug "no new objects; type: ${STARTUP_SYNC_GET}"
    fi
  else
    hzn::log.debug "not yet time to synchronize"
  fi

  # test if time to inspect host and docker (again)
  if [ $(($(startup_period) - $(($(date +%s) - INSPECT_DATE)))) -le 0 ]; then
    ## inspect host
    INSPECT=$(host_inspect)
    if [ ! -z "${INSPECT:-}" ]; then
      hzn::log.debug "host inspection: " $(echo "${INSPECT}" | jq '.horizon=(.horizon!=null)|.docker=(.docker!=null)|.nmap=(.nmap!=null)')
      INSPECT_DATE=$(date +%s)
      UPDATED=true
    else
      hzn::log.warn "unable to inspect host"
    fi
    ## inspect docker
    CONTAINERS=$(docker_status)
    if [ ! -z "${CONTAINERS:-}" ]; then
      hzn::log.debug "docker inspection: " $(echo "${CONTAINERS}" | jq '.containers=(.containers!=null)')
      INSPECT_DATE=$(date +%s)
      UPDATED=true
    else
      hzn::log.warn "unable to inspect docker"
    fi
  fi

  # create output 
  if [ "${UPDATED:-false}" = true ]; then
    if [ -s "$(startup_config_file)" ]; then
      hzn::log.debug "configuration file: $(startup_config_file)"
      echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"docker":'${CONTAINERS:-null}',"host":'"${INSPECT:-null}"',"'${STARTUP_SYNC_GET}'":'$(cat $(startup_config_file))'}' > "${OUTPUT_FILE}"
    else
      echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"docker":'${CONTAINERS:-null}',"host":'"${INSPECT:-null}"',"'${STARTUP_SYNC_GET}'":null}' > "${OUTPUT_FILE}"
    fi
    # update this service output with contents from file
    service_update ${OUTPUT_FILE}
    # collect the composite service(s) output
    SVCOUT=$(mktemp -t "${0##*/}-svcout-XXXXXX")
    service_output ${SVCOUT}

    if [ -s "${SVCOUT}" ]; then
      # update object
      if [ $(ess_object_upload ${SVCOUT} ${HZN_DEVICE_ID%%.*} ${SERVICE_VERSION} ${STARTUP_SYNC_PUT}) ]; then
	hzn::log.debug "--- UPLOAD objectType: ${STARTUP_SYNC_PUT}; objectID: ${HZN_DEVICE_ID%%.*}; size: " $(wc -c ${SVCOUT})
      else
	hzn::log.debug "object upload failed"
      fi
    else
      hzn::log.debug "empty service_output: ${SVCOUT}"
    fi
    # remove temporary output data file
    rm -f ${SVCOUT}

    # send service output via kafka
    if [ $(kafka_send_output) ]; then
      hzn::log.debug "send Kafka: success"
    else
      hzn::log.debug "send Kafka: failure"
    fi
  else
    hzn::log.debug "no updated objects, host, or docker"
  fi

  # wait for ..
  SECONDS=$(($(startup_sync_period) - $(($(date +%s) - SYNC_DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done

rm -f ${OUTPUT_FILE}
