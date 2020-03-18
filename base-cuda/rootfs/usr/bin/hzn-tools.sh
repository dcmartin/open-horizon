#!/usr/bin/env bash

## right off the bat
if [ -z "${TMPDIR:-}" ]; then if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi; fi
if [ -z "${LOGTO:-}" ] && [ ! -z "${HZN_PATTERN:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; else LOGTO=${LOGTO:-/dev/stderr}; fi

###
### HZN TOOLS
###

if [ -z "${HZN_CONFIG_FILE}" ]; then export HZN_CONFIG_FILE="${TMPDIR}/horizon.json"; fi

# hzn_pattern() - find the pattern with the given name; searches HZN_ORGANIZATION only
hzn_pattern() {
  hzn.log.trace "${FUNCNAME[0]}"

  PATTERN=
  if [ ! -z "${1}" ] && [ ! -z "${HZN_ORGANIZATION:-}" ] && [ ! -z "${HZN_EXCHANGE_APIKEY:-}" ] && [ ! -z "${HZN_EXCHANGE_URL:-}" ]; then
    ALL=$(curl -sL -u "${HZN_ORGANIZATION}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL}orgs/${HZN_ORGANIZATION}/patterns")
    if [ ! -z "${ALL}" ]; then
      hzn.log.trace "searching for pattern ${1} in all patterns ${ALL}"
      PATTERN=$(echo "${ALL}" | jq '.patterns|to_entries[]|select(.key=="'${1}'")')
    fi
  fi
  if [ ! -z "${1}" ]; then 
    if [ -z "${PATTERN}" ]; then 
      hzn.log.warn "pattern was not found: ${1}"
      PATTERN='"'${1}'"'
    fi
  else
    hzn.log.warn "pattern was not specified"
    PATTERN='null'
  fi
  echo ${PATTERN}
}

# initialize horizon
hzn_init() {
  hzn.log.trace "${FUNCNAME[0]}"

  HZN='{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"hzn":{"agreementid":"'${HZN_AGREEMENTID:-}'","arch":"'${HZN_ARCH:-}'","cpus":'${HZN_CPUS:-0}',"device_id":"'${HZN_DEVICE_ID:-}'","exchange_url":"'${HZN_EXCHANGE_URL:-}'","host_ips":['$(echo "${HZN_HOST_IPS:-}" | sed 's/,/","/g' | sed 's/\(.*\)/"\1"/')'],"organization":"'${HZN_ORGANIZATION:-}'","ram":'${HZN_RAM:-0}',"pattern":'$(hzn_pattern "${HZN_PATTERN:-}")'}}'

  hzn.log.debug "horizon configuration: ${HZN}"

  echo "${HZN}" > "${HZN_CONFIG_FILE}" && cat "${HZN_CONFIG_FILE}" || echo ''
}

# get horizon configuration
hzn_config() {
  hzn.log.trace "${FUNCNAME[0]}"
  if [ -z "${HZN}" ]; then
    if [ ! -s "${HZN_CONFIG_FILE}" ]; then
      hzn.log.error "environment HZN unset; empty ${HZN_CONFIG_FILE}; exiting"
      exit 1
    fi
    export HZN=$(jq -c '.' "${HZN_CONFIG_FILE}")
    hzn.log.warn "environment HZN unset; using file: ${HZN_CONFIG_FILE}; contents: ${HZN}"
    if [ -z "${HZN}" ]; then
      hzn.log.error "environment HZN unset; invalid ${HZN_CONFIG_FILE}; exiting" $(cat ${HZN_CONFIG_FILE})
      exit 1
    fi
  fi
  echo "${HZN}"
}

##
## logging
##

LOG_LEVEL_EMERG=0
LOG_LEVEL_ALERT=1
LOG_LEVEL_CRIT=2
LOG_LEVEL_ERROR=3
LOG_LEVEL_WARN=4
LOG_LEVEL_NOTICE=5
LOG_LEVEL_INFO=6
LOG_LEVEL_DEBUG=7
LOG_LEVEL_TRACE=8
LOG_LEVEL_ALL=9
LOG_LEVELS=(EMERGENCY ALERT CRITICAL ERROR WARNING NOTICE INFO DEBUG TRACE ALL)
LOG_FORMAT_DEFAULT='[TIMESTAMP] LEVEL >>>'
LOG_TIMESTAMP_DEFAULT='%FT%TZ'
LOG_FORMAT="${LOG_FORMAT:-${LOG_FORMAT_DEFAULT}}"
LOG_LEVEL="${LOG_LEVEL:-${LOG_LEVEL_INFO}}"
LOG_TIMESTAMP_FORMAT="${LOG_TIMESTAMP_FORMAT:-${LOG_TIMESTAMP_DEFAULT}}"

# logging by level

hzn.log.emerg()
{
  hzn.log.logto ${LOG_LEVEL_EMERG} "${*}"
}

hzn.log.alert()
{
  hzn.log.logto ${LOG_LEVEL_ALERT} "${*}"
}

hzn.log.crit()
{
  hzn.log.logto ${LOG_LEVEL_CRIT} "${*}"
}

hzn.log.error()
{
  hzn.log.logto ${LOG_LEVEL_ERROR} "${*}"
}

hzn.log.warn()
{
  hzn.log.logto ${LOG_LEVEL_WARN} "${*}"
}

hzn.log.notice()
{
  hzn.log.logto ${LOG_LEVEL_NOTICE} "${*}"
}

hzn.log.info()
{
  hzn.log.logto ${LOG_LEVEL_INFO} "${*}"
}

hzn.log.debug()
{
  hzn.log.logto ${LOG_LEVEL_DEBUG} "${*}"
}

hzn.log.trace()
{
  hzn.log.logto ${LOG_LEVEL_TRACE} "${*}"
}

hzn.log.level()
{
  case "${LOG_LEVEL}" in
    emerg) LL=${LOG_LEVEL_EMERG} ;;
    alert) LL=${LOG_LEVEL_ALERT} ;;
    crit) LL=${LOG_LEVEL_CRIT} ;;
    error) LL=${LOG_LEVEL_ERROR} ;;
    warn) LL=${LOG_LEVEL_WARN} ;;
    notice) LL=${LOG_LEVEL_NOTICE} ;;
    info) LL=${LOG_LEVEL_INFO} ;;
    debug) LL=${LOG_LEVEL_DEBUG} ;;
    trace) LL=${LOG_LEVEL_TRACE} ;;
    *) LL=${LOG_LEVEL_ALL} ;;
  esac
  echo ${LL:-${LOG_LEVEL_ALL}}
}

hzn.log.logto()
{
  local level="${1:-0}"
  local current=$(hzn.log.level)
  local exp='^[0-9]+$'

  if ! [[ ${level} =~ ${exp} ]] ; then
   echo "hzn.log.logto: error: level ${level} not a number ${FUNCNAME}" &> ${LOGTO}
   level=
  fi
  if ! [[ ${current} =~ ${exp} ]] ; then
   echo "hzn.log.logto: error: current ${current} not a number ${FUNCNAME}" &> ${LOGTO}
   current=
  fi
  if [ "${level:-0}" -le ${current:-9} ]; then 
    message="${2:-}"
    timestamp=$(date -u +"${LOG_TIMESTAMP_FORMAT}")
    output="${LOG_FORMAT}"
    output=$(echo "${output}" | sed 's/TIMESTAMP/'${timestamp}'/')
    output=$(echo "${output}" | sed 's/LEVEL/'${LOG_LEVELS[${level}]}'/')
    echo "${0##*/} $$ ${output} ${message}" &> ${LOGTO:-/dev/stderr}
  fi
}
