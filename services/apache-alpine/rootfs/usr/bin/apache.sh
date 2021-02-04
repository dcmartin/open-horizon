#!/usr/bin/with-contenv bashio

# set -o nounset  # Exit script on use of an undefined variable
# set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells

## parent functions
source /usr/bin/service-tools.sh
source /usr/bin/apache-tools.sh

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
