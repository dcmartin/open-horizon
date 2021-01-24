#!/usr/bin/with-contenv bashio

# set -o nounset  # Exit script on use of an undefined variable
# set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells

## parent functions
source /usr/bin/service-tools.sh

## configuration
base::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-info}'"}'
  local output=$(mktemp)

  hzn::service.init ${config}
  hzn::log.info "${FUNCNAME[0]}: initialized:" $(echo "$(hzn::service.config)" | jq -c '.')

  # loop while node is alive
  while [ true ]; do
    # create output
    echo '{"pid":'$$',"timestamp":"'$(date -u +%FT%TZ)'"}' > ${output}
    hzn::service.update ${output}
    if [ -s "${output}" ]; then
      hzn::log.debug "${FUNCNAME[0]}: updated; output: $(cat ${output})"
    else
      hzn::log.warning "${FUNCNAME[0]}: update failed; configuration: $(hzn::service.config)"
    fi
    sleep ${BASE_PERIOD:-30}
    hzn::log.debug "${FUNCNAME[0]}: wakeup"
  done
  rm -f ${output}
}

###
### MAIN
###

hzn::log.notice "${0} ${*}"

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

base::main ${*}
