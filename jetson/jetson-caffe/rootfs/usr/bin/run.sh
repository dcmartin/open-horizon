#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

##
## hzn_pattern() - find the pattern with the given name; searches HZN_ORGANIZATION only
##

hzn_pattern() {
  if [ ! -z "${1}" ] && [ ! -z "${HZN_ORGANIZATION:-}" ] && [ ! -z "${HZN_EXCHANGE_APIKEY:-}" ] && [ ! -z "${HZN_EXCHANGE_URL:-}" ]; then
    ALL=$(curl -sL -u "${HZN_ORGANIZATION}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL}orgs/${HZN_ORGANIZATION}/patterns")
    if [ ! -z "${ALL}" ]; then
      PATTERN=$(echo "${ALL}" | jq '.patterns|to_entries[]|select(.key=="'${1}'")')
      if [ -z "${PATTERN}" ]; then PATTERN='"'${1}'"'; fi
    fi
  fi
  if [ -z "${PATTERN:-}" ]; then PATTERN='null'; fi
  echo ${PATTERN}
}

# hzn config
export HZN='{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"hzn":{"agreementid":"'${HZN_AGREEMENTID:-}'","arch":"'${HZN_ARCH:-}'","cpus":'${HZN_CPUS:-0}',"device_id":"'${HZN_DEVICE_ID:-}'","exchange_url":"'${HZN_EXCHANGE_URL:-}'","host_ips":['$(echo "${HZN_HOST_IPS:-}" | sed 's/,/","/g' | sed 's/\(.*\)/"\1"/')'],"organization":"'${HZN_ORGANIZATION:-}'","ram":'${HZN_RAM:-0}',"service":"'${SERVICE_LABEL:-}'","version":"'${SERVICE_VERSION:-}'","pattern":'$(hzn_pattern "${HZN_PATTERN:-}")'}}'

# make a file
echo "${HZN}" > "${TMPDIR}/config.json"

# label
if [ ! -z "${SERVICE_LABEL:-}" ]; then
  CMD=$(command -v "${SERVICE_LABEL:-}.sh")
  if [ ! -z "${CMD}" ]; then
    ${CMD} &
  fi
else
  echo "+++ WARN $0 $$ -- executable ${SERVICE_LABEL:-}.sh not found" &> /dev/stderr
fi

# port
if [ -z "${SERVICE_PORT:-}" ]; then 
  SERVICE_PORT=80
else
  echo "+++ WARN: using localhost port ${SERVICE_PORT}" &> /dev/stderr
fi

# start listening
socat TCP4-LISTEN:${SERVICE_PORT},fork EXEC:service.sh
