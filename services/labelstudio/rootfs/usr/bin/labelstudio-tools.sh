#!/usr/bin/with-contenv bashio

function labelstudio::start()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config="${*}"
  local WORKSPACE=$(echo "${config:-null}" | jq -r '.labelstudio.workspace'}
  local PROJECT=$(echo "${config:-null}" | jq -r '.labelstudio.project'}
  local PROTOCOL=$(echo "${config:-null}" | jq -r '.labelstudio.protocol'}
  local HOST=$(echo "${config:-null}" | jq -r '.labelstudio.host'}
  local PORT=$(echo "${config:-null}" | jq -r '.labelstudio.port'}
  local USERNAME=$(echo "${config:-null}" | jq -r '.labelstudio.username'}
  local PASSWORD=$(echo "${config:-null}" | jq -r '.labelstudio.password'}
  local INIT=$(echo "${config:-null}" | jq -r '.labelstudio.init'}
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
