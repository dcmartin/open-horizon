#!/usr/bin/with-contenv bashio

# set -o nounset  # Exit script on use of an undefined variable
# set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells

## parent functions
source /usr/bin/service-tools.sh
source /usr/bin/apache-tools.sh

apache::service.update()
{
  local output=${1:-}"

  if [ -z "${output}" ] || [ ! -e "${output}" ]; then
    hzn::log.error "${FUNCNAME[0]}: no file; output: ${output}"
  else
    local PID

    # test for PID file
    if [ ! -z "${APACHE_PID_FILE:-}" ]; then
      if [ -s "${APACHE_PID_FILE}" ]; then
        PID=$(cat ${APACHE_PID_FILE})
      else
        hzn::log.warning "${FUNCNAME[0]}: Apache failed to start"
      fi
    else
      hzn::log.error "${FUNCNAME[0]}: APACHE_PID_FILE is undefined"
    fi
  
    # create output
    echo -n '{"pid":'${PID:-0}',"status":"' > ${output}
  
    # get status
    if [ ${PID:-0} -ne 0 ]; then
      local tmp=$(mktemp)
      local err=$(mktemp)
  
      # request server status
      hzn::log.notice "${FUNCNAME[0]}: Apache PID: ${PID:-};requesting Apache server status: http://localhost:${APACHE_PORT:-}/server-status"
      curl -fkqsSL "http://localhost:${APACHE_PORT:-}/server-status" -o ${tmp} 2> ${err}
      # test server output
      if [ -s "${tmp}" ]; then
        hzn::log.debug "${FUNCNAME[0]}: RECEIVED: server status:" $(cat ${tmp})
        cat "${tmp}" | base64 -w 0 >> ${output}
      else
        hzn::log.warning "${FUNCNAME[0]}: FAILED: no server status; error:" $(cat ${err})
      fi
    else
      hzn::log.error "${FUNCNAME[0]}: No Apache PID"
    fi
  
    # terminate output
    echo '"}' >> ${output}
  fi
}

###
### MAIN
###

apache::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-}'","conf":"'${APACHE_CONF:-}'","htdocs": "'${APACHE_HTDOCS:-}'","cgibin": "'${APACHE_CGIBIN:-}'","host": "'${APACHE_HOST:-}'","port": "'${APACHE_PORT:-}'","admin": "'${APACHE_ADMIN:-}'","pidfile":"'${APACHE_PID_FILE:-}'","rundir":"'${APACHE_RUN_DIR:-}'","period":'${APACHE_PERIOD:-30}'}'
  local output=$(mktemp)

  hzn::log.notice "${FUNCNAME[0]}: initializing service: ${SERVICE_LABEL:-}" $(echo "${config}" | jq -c '.' || echo "INVALID: ${config}")
  hzn::service.init ${config}

  # start apache
  apache::start

  # loop while node is alive
  while [ true ]; do

    # update apache status
    apache::service.update ${output}

    # update horizon
    hzn::log.info "${FUNCNAME[0]}: updating service:" $(jq -c '.' ${output})
    hzn::service.update ${output}

    # sleep
    hzn::log.debug "${FUNCNAME[0]}: sleeping for ${APACHE_PERIOD:-30} seconds..."
    sleep ${APACHE_PERIOD:-30}
  done
  rm -f ${output} ${tmp} ${err}
}

###
### MAIN
###

hzn::log.notice "${0} ${*}"

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

## defaults
if [ -z "${APACHE_PID_FILE:-}" ]; then export APACHE_PID_FILE="/var/run/apache2.pid"; fi
if [ -z "${APACHE_RUN_DIR:-}" ]; then export APACHE_RUN_DIR="/var/run/apache2"; fi
if [ -z "${APACHE_ADMIN:-}" ]; then export APACHE_ADMIN="${HZN_ORG_ID:-}"; fi

apache::main ${*}
