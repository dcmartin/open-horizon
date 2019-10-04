#!/usr/bin/env bash

## LOGTO
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### HZN TOOLS
###

if [ -z "${HZN_CONFIG_FILE}" ]; then export HZN_CONFIG_FILE="${TMPDIR}/horizon.json"; fi

# hzn_pattern() - find the pattern with the given name; searches HZN_ORGANIZATION only
hzn_pattern() {
  PATTERN=
  if [ ! -z "${1}" ] && [ ! -z "${HZN_ORGANIZATION:-}" ] && [ ! -z "${HZN_EXCHANGE_APIKEY:-}" ] && [ ! -z "${HZN_EXCHANGE_URL:-}" ]; then
    ALL=$(curl -sL -u "${HZN_ORGANIZATION}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL}orgs/${HZN_ORGANIZATION}/patterns")
    if [ ! -z "${ALL}" ]; then
      PATTERN=$(echo "${ALL}" | jq '.patterns|to_entries[]|select(.key=="'${1}'")')
    fi
  fi
  if [ -z "${PATTERN}" ]; then if [ ! -z "${1}" ]; then PATTERN='"'${1}'"'; else PATTERN='null'; fi; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- hzn_pattern: ${PATTERN}" >> ${LOGTO} 2&>1; fi
  echo ${PATTERN}
}

# initialize horizon
hzn_init() {
  if [ ! -z "${1}" ]; then
    export HZN_EXCHANGE_URL=${1}
    sed -i -e "s|HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${1}|" /etc/default/horizon
    sed -i -e "s|HZN_FSS_CSSURL=.*|HZN_FSS_CSSURL=${HZN_EXCHANGE_URL%/v1}/css/api/v1|" /etc/default/horizon
  fi
  HZN='{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"hzn":{"agreementid":"'${HZN_AGREEMENTID:-}'","arch":"'${HZN_ARCH:-}'","cpus":'${HZN_CPUS:-0}',"device_id":"'${HZN_DEVICE_ID:-}'","exchange_url":"'${HZN_EXCHANGE_URL:-}'","host_ips":['$(echo "${HZN_HOST_IPS:-}" | sed 's/,/","/g' | sed 's/\(.*\)/"\1"/')'],"organization":"'${HZN_ORGANIZATION:-}'","ram":'${HZN_RAM:-0}',"pattern":'$(hzn_pattern "${HZN_PATTERN:-}")'}}'
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- hzn_init: ${HZN}" >> ${LOGTO} 2&>1; fi
  echo "${HZN}" > "${HZN_CONFIG_FILE}" && cat "${HZN_CONFIG_FILE}" || echo ''
}

# get horizon configuration
hzn_config() {
  if [ -z "${HZN}" ]; then
    if [ ! -s "${HZN_CONFIG_FILE}" ]; then
      echo "*** ERROR $0 $$ -- environment HZN unset; empty ${HZN_CONFIG_FILE}; exiting" >> ${LOGTO} 2&>1
      exit 1
    fi
    export HZN=$(jq -c '.' "${HZN_CONFIG_FILE}")
    echo "+++ WARN $0 $$ -- environment HZN unset; using file: ${HZN_CONFIG_FILE}; contents: ${HZN}" >> ${LOGTO} 2&>1
    if [ -z "${HZN}" ]; then
      echo "*** ERROR $0 $$ -- environment HZN unset; invalid ${HZN_CONFIG_FILE}; exiting" $(cat ${HZN_CONFIG_FILE}) >> ${LOGTO} 2&>1
      exit 1
    fi
  fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- hzn_config:" $(echo "${HZN}" | jq -c '.') >> ${LOGTO} 2&>1; fi
  echo "${HZN}"
}
