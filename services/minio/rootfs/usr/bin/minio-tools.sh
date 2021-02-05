#!/usr/bin/with-contenv bashio

minio::start()
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

  MINIO_ROOT_USER=${USERNAME} MINIO_ROOT_PASSWORD=${PASSWORD} /usr/local/bin/minio server --address :${PORT} ${WORKSPACE}

  echo "${PID:-0}"
}

function minio::service.update()
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
    curl -sSL ${protocol}${username}:${password}@127.0.0.1:${port}/minio/v2/metrics/node > ${output}
  fi
}
