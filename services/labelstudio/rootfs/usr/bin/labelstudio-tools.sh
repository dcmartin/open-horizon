#!/usr/bin/with-contenv bashio

labelstudio::start()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local WORKSPACE=${1}
  local PROJECT=${2}
  local PROTOCOL=${3}
  local HOST=${4}
  local PORT=${5}
  local USERNAME=${6}
  local PASSWORD=${7}
  local INIT=${8}
  local PID=0

  cd ${LABEL_STUDIO} \
    && \
    label-studio start \
      --root-dir ${WORKSPACE} \
      --use-gevent \
      "${PROJECT}" \
      -b \
      --force \
      --host "${HOST}" \
      --port "${PORT}" \
      --protocol "${PROTOCOL}" \
      --username "${USERNAME}" \
      --password "${PASSWORD}" \
      "${INIT}" &
  PID=$!

  echo "${PID:-0}"
}

function labelstudio::service.update()
{ 
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config=$(hzn::service.config)
  local label=$(echo "${config}" | jq -r ".label")
  local username=$(echo "${config}" | jq -r ".config.${label}.username")
  local password=$(echo "${config}" | jq -r ".config.${label}.password")
  local protocol=$(echo "${config}" | jq -r ".config.${label}.protocol")
  local port=$(echo "${config}" | jq -r ".config.${label}.port")

  local output=${1:-}

  if [ -z "${output}" ] || [ ! -e "${output}" ]; then
    hzn::log.error "${FUNCNAME[0]}: no file; output: ${output}"
  else
    curl -sSL ${protocol}${username}:${password}@127.0.0.1:${port}/api/health > ${output}
  fi
}
