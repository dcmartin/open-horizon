#!/usr/bin/with-contenv bashio

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh


hal::loop()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local output_file=$(mktemp)

  # intial update
  echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${output_file}"
  hzn::service.update ${output_file}

  while true; do
    local DATE=$(date +%s)
    local OUTPUT='{}'
  
    for ls in lshw lsusb lscpu lspci lsblk lsdf i2c; do
      local OUT

      hzn::log.debug "operator: ${ls}"
      if [ -z "$(command -v ${ls}.sh)" ]; then
        hzn::log.error "operator: ${ls}; not found"
        OUT='null'
      else
        OUT=$(${ls}.sh | jq '.'${ls}'?' || echo 'null')
      fi
      OUTPUT=$(echo "$OUTPUT" | jq '.'${ls}'='"${OUT}")
    done
    echo "${OUTPUT}" | jq '.timestamp="'$(date -u +%FT%TZ)'"|.date='$(date +%s) > "${output_file}"
    hzn::service.update "${output_file}"
    # wait for ..
    SECONDS=$((HAL_PERIOD - $(($(date +%s) - DATE))))
    if [ ${SECONDS} -gt 0 ]; then
      sleep ${SECONDS}
    fi
  done
}

hal::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config='{"timestamp":"'$(date -u +%FT%TZ)'","log_level":"'${SERVICE_LOG_LEVEL:-info}'","period":"'${HAL_PERIOD:-1800}'","services":'"${SERVICES:-null}"'}'

  ## initialize horizon
  hzn::log.notice "${FUNCNAME[0]}: initializing service: ${SERVICE_LABEL:-}" $(echo "${config}" | jq -c '.' || echo "INVALID: ${config}")
  hzn::init
  hzn::service.init "${config}"

  ## loop forever
  hzn::log.info "${FUNCNAME[0]}: looping forever"
  hal::loop
}

###
### MAIN
###

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

hzn::log.notice "Starting ${0} ${*}: ${SERVICE_LABEL:-null}; version: ${SERVICE_VERSION:-null}"

hal::main ${*}

exit 1
