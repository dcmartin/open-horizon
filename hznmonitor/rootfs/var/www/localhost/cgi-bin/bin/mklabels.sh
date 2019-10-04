#!/bin/bash

if [ -z "${HZNMONITOR_EXCHANGE_URL:-}" ]; then export HZNMONITOR_EXCHANGE_URL="${HZNSETUP_EXCHANGE}"; fi
if [ -z "${HZNMONITOR_EXCHANGE_APIKEY:-}" ]; then export HZNMONITOR_EXCHANGE_APIKEY="${HZNSETUP_APIKEY}"; fi
if [ -z "${HZNMONITOR_EXCHANGE_ORG:-}" ]; then export HZNMONITOR_EXCHANGE_ORG="${HZNSETUP_ORG}"; fi

hzn_services()
{
  echo $(curl -sL -u "${HZNMONITOR_EXCHANGE_ORG}/${HZNMONITOR_EXCHANGE_USER:-iamapikey}:${HZNMONITOR_EXCHANGE_APIKEY}" "${HZNMONITOR_EXCHANGE_URL%/}/orgs/${HZNMONITOR_EXCHANGE_ORG}/services" \
  | jq '{"services":[.services|to_entries[]|.value.id=.key|.value]|sort_by(.lastUpdated)|reverse}')
}

hzn_labels()
{
  SERVICES=$(hzn_services)
  ALL_LABELS=$(echo "${SERVICES}" | jq -r '.services[].label' | sort | uniq)
  echo '['
  h=0; for LABEL in ${ALL_LABELS}; do
    if [ ${h} -gt 0 ]; then echo ','; fi
    echo '{"label":"'${LABEL}'",'
    LABEL_SERVICES=$(echo "${SERVICES}" | jq -c '.services[]|select(.label=="'${LABEL}'")')
    SERVICES_URLS=$(echo "${LABEL_SERVICES}" | jq -r '.url' | sort | uniq)
    echo '"services":[';
    i=0; for URL in ${SERVICES_URLS}; do
      if [ ${i} -gt 0 ]; then echo ','; fi
      SVCS=$(echo "${LABEL_SERVICES}" | jq -c '.|select(.url=="'${URL}'")')
      echo '{"url":"'${URL}'",'
      echo '"public":"'$(echo "${SVCS}" | jq -r '.public' | sort | uniq | head -1)'",'
      echo '"shared":"'$(echo "${SVCS}" | jq -r '.sharable' | sort | uniq | head -1)'",'
      echo '"doc":"'$(echo "${SVCS}" | jq -r '.documentation' | sort | uniq | head -1)'",'
      # privileged
      OUT=$(echo "${SVCS}" | jq '.deployment|fromjson|.services|to_entries[]|.value.privileged!=null' | sort | uniq)
      if [ "${OUT}" = true ]; then echo '"privileged": true,'; fi
      # specific_ports
      OUT=$(echo "${SVCS}" | jq '.deployment|fromjson|.services|to_entries[]|.value.specific_ports!=null' | sort | uniq)
      if [ "${OUT}" = true ]; then echo '"specific_ports":true,'; fi
      # devices
      OUT=$(echo "${SVCS}" | jq '.deployment|fromjson|.services|to_entries[]|.value.devices!=null' | sort | uniq)
      if [ "${OUT}" = true ]; then echo '"devices": true,'; fi
      # binds
      OUT=$(echo "${SVCS}" | jq '.deployment|fromjson|.services|to_entries[]|.value.binds!=null' | sort | uniq)
      if [ "${OUT}" = true ]; then echo '"binds": true,'; fi
      # environment
      OUT=$(echo "${SVCS}" | jq '.deployment|fromjson|.services|to_entries[]|.value.environment!=null' | sort | uniq)
      if [ "${OUT}" = true ]; then echo '"environment": true,'; fi
      echo '"versions":['
      versions=$(echo "${SVCS}" | jq -r '.version' | sort -t\. -k1,1nr -k2,2nr -k3,3nr | uniq)
      j=0; for v in ${versions}; do
        if [ ${j} -gt 0 ]; then echo ','; fi
        VERS=$(echo "${SVCS}" | jq -c '.|select(.version=="'${v}'")')
        architectures=$(echo "${VERS}" | jq -r '.arch' | sort | uniq)
        echo '{"version":"'${v}'","containers":['
        k=0; for a in ${architectures}; do
          local this=$(echo "${VERS}" | jq -c '.|select(.arch=="'${a}'")|{"lastUpdated":.lastUpdated,"arch":.arch,"image":.deployment|fromjson|.services."'${LABEL}'".image}')
	  local image=$(echo "${this}" | jq -r '.image' | sed 's/\(^[^@:]*\)[@:].*/\1/')

          if [ ${k} -gt 0 ]; then echo ','; fi
	  echo "${this}" | jq '.image="'${image}'"'
          k=$((k+1))
        done
        echo ']'
        echo '}'
        j=$((j+1))
      done
      echo ']'
      echo '}'
      i=$((i+1))
    done
    echo ']'
    echo '}'
    h=$((h+1))
  done
  echo ']'
}

###
### MAIN
###

if [ ! -z "${1}" ]; then
  pidfile="${2:-/tmp/${0##*/}.pid}"
  mkdir -p ${pidfile%/*}
  if [ ! -s ${pidfile} ]; then
    echo "$$" > "${pidfile}"
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- initiating; pidfile: ${pidfile}; PID: " $(cat ${pidfile}) &> /dev/stderr; fi
    temp=$(mktemp -t "${0##*/}-XXXXXX")
    echo '{"labels":'$(hzn_labels)'}' | tee ${temp} | jq -c '.'
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- produced output; output: " $(cat ${temp}) &> /dev/stderr; fi
    mv -f ${temp} ${1}
    rm -f ${pidfile}
  else
    echo "+++ WARN -- $0 $$ -- currently processing; pidfile: ${pidfile}; PID: " $(cat ${pidfile}) &> /dev/stderr
  fi
else
  echo "*** ERROR -- $0 $$ -- provide file name for output" &> /dev/stderr
  exit 1
fi
