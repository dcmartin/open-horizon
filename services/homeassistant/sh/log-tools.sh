#!/usr/bin/env bash

##
## logging
##


## right off the bat
if [ -z "${TMPDIR:-}" ]; then if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi; fi
if [ -z "${LOGTO:-}" ] && [ ! -z "${HZN_PATTERN:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; else LOGTO=${LOGTO:-/dev/stderr}; fi

## GLOBALS
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
LOG_FORMAT_DEFAULT='[TIMESTAMP] LEVEL '
LOG_TIMESTAMP_DEFAULT='%FT%TZ'
LOG_FORMAT="${LOG_FORMAT:-${LOG_FORMAT_DEFAULT}}"
LOG_LEVEL="${LOG_LEVEL:-info}"
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
