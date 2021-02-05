#!/usr/bin/with-contenv /usr/bin/bashio

# ==============================================================================
set -o nounset  # Exit script on use of an undefined variable
set -o pipefail # Return exit status of the last command in the pipe that failed
set -o errexit  # Exit script when a command exits with non-zero status
set -o errtrace # Exit on error inside any functions or sub-shells

source /usr/bin/service-tools.sh
source /usr/bin/minio-tools.sh

function minio::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local VALUE
  local TIMEZONE
  local PROJECT
  local WORKSPACE
  local PORT
  local HOST
  local PROTOCOL
  local USERNAME
  local PASSWORD
  local INIT
  local PID=0

  # TIMEZONE
  VALUE=$(bashio::config "timezone")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE="GMT"; fi
  hzn::log.info "Setting timezone: ${VALUE}" >&2
  TIMEZONE=${VALUE}
  cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

  # WORKSPACE
  VALUE=$(bashio::config "workspace")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_WORKSPACE:-'/data/minio'}; fi
  hzn::log.info "Setting workspace: ${VALUE}" >&2
  WORKSPACE=${VALUE}

  # PROJECT
  VALUE=$(bashio::config "project")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_PROJECT:-'MyProject'}; fi
  hzn::log.info "Setting project: ${VALUE}" >&2
  PROJECT=${VALUE}

  # HOST
  VALUE=$(bashio::config "host")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_HOST:-'0.0.0.0'}; fi
  hzn::log.info "Setting host: ${VALUE}" >&2
  HOST=${VALUE}

  # PORT
  VALUE=$(bashio::config "port")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_PORT:-'9000'}; fi
  hzn::log.info "Setting port: ${VALUE}" >&2
  PORT=${VALUE}

  # PROTOCOL
  VALUE=$(bashio::config "protocol")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_PROTOCOL:-'http://'}; fi
  hzn::log.info "Setting protocol: ${VALUE}" >&2
  PROTOCOL=${VALUE}

  # USERNAME
  VALUE=$(bashio::config "username")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_USERNAME:-'username'}; fi
  hzn::log.info "Setting username: ${VALUE}" >&2
  USERNAME=${VALUE}

  # PASSWORD
  VALUE=$(bashio::config "password")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_PASSWORD:-'password'}; fi
  hzn::log.info "Setting password: ${VALUE}" >&2
  PASSWORD=${VALUE}

  # INIT
  VALUE=$(bashio::config "init")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${MINIO_INIT:-'--init'}; fi
  hzn::log.info "Setting init: ${VALUE}" >&2
  INIT=${VALUE}

  # START 
  local config='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'$(bashio::config "log_level")'","period":'${SERVICE_PERIOD:-30}',"label":"'${SERVICE_LABEL:-}'","timezone":"'${TIMEZONE}'","hostname":"'$(hostname)'","arch":"'$(arch)'","date":'$(/bin/date +%s)',"'${SERVICE_LABEL:-}'":{"workspace":"'${WORKSPACE}'","project":"'${PROJECT}'","host":"'${HOST}'","port":'${PORT}',"protocol":"'${PROTOCOL}'","username":"'${USERNAME}'","password":"'${PASSWORD}'","init":"'${INIT}'"}}'

  local output=$(mktemp)

  hzn::log.notice "${FUNCNAME[0]}: initializing service: ${SERVICE_LABEL:-}" $(echo "${config}" | jq -c '.' || echo "INVALID: ${config}")
  hzn::service.init "${config}"

  # start minio
  PID=$(minio::start ${WORKSPACE} ${PROJECT} ${PROTOCOL} ${HOST} ${PORT} ${USERNAME} ${PASSWORD} ${INIT})

  # loop while node is alive
  while [ true ]; do

    # update minio status
    minio::service.update ${output}

    # update horizon
    if [ -s "${output}" ]; then
      hzn::log.info "${FUNCNAME[0]}: updating service: ${SERVICE_LABEL:-null}"
    else
      hzn::log.warn "${FUNCNAME[0]}: no service update output"
      echo '{"service":"'${SERVICE_LABEL:-}'","error":"no output"}' > ${output}
    fi
    hzn::service.update ${output}

    # sleep
    hzn::log.debug "${FUNCNAME[0]}: sleeping for ${SERVICE_PERIOD:-30} seconds..."
    sleep ${SERVICE_PERIOD:-30}
  done
  rm -f ${output} ${tmp} ${err}
}

###
### MAIN
###

hzn::log.notice "${0} ${*}"

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

minio::main ${*}
