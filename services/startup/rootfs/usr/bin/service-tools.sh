#!/usr/bin/env bash

source /usr/bin/hzn-tools.sh

## utility functions

service_output_file()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  echo "${TMPDIR:-/tmp}/$(service_label).json"
}

service_otherServices()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local OUTPUT=
  local CONFIG=$(service_config)

  if [ ! -z "${CONFIG}" ]; then OUTPUT=$(echo "${CONFIG}" | jq -c '.config.services'); fi
  if [ "${OUTPUT}" == 'null' ]; then OUTPUT=; fi
  hzn.log.debug "service_otherServices: ${OUTPUT}"
  echo "${OUTPUT}"
}

service_label()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  echo "${SERVICE_LABEL:-}"
}

service_version()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  echo "${SERVICE_VERSION:-}"
}

## configuration


service_config_file()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local file=${SERVICE_CONFIG_FILE:-${TMPDIR:-/tmp}/config.json}

  echo "${file}"
}

service_init()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local CONFIG="${*}"

  if [ -s "$(service_config_file)" ]; then
    hzn.log.warn "service_init: service already initialized"
  fi
  echo "${CONFIG}" | jq -c '.' > $(service_config_file)
  if [ -s $(service_config_file) ]; then
    OUTPUT=$(jq -c '.' $(service_config_file))
    hzn.log.debug "service_init: service initialized: ${OUTPUT}"
  else
    hzn.log.debug "service_init: service initialization failed: ${CONFIG}"
    OUTPUT= 
  fi
  echo "${OUTPUT}"
}

service_config()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local CONFIG="null"
  local OUT

  if [ ! -s "$(service_config_file)" ]; then
    hzn.log.warn "service_config: service not initialized"
  else
    CONFIG=$(jq -c '.' $(service_config_file))
  fi
  OUT='{"config":'${CONFIG}',"service":{"label":"'$(service_label)'","version":"'$(service_version)'"}}' 
  hzn.log.debug "service_config: ${OUT}"
  echo "${OUT}"
}

## update services functions
service_otherServices_output()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local OUTPUT=${1}
  local SERVICES=$(echo "$(service_otherServices)" | jq -r '.[]|.name')

  echo '{}' > "${OUTPUT}"
  if [ ! -z "${SERVICES}" ] && [ "${SERVICES}" != 'null' ]; then
    for S in ${SERVICES}; do
      URL=$(echo "$(service_otherServices)" | jq -r '.[]|select(.name=="'${S}'").url')
      TEMP_FILE=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
      if [ ! -z "${URL}" ]; then
	curl -sSL "${URL}" | jq -c '.'"${S}" > ${TEMP_FILE} 2> /dev/null
      fi
      TEMP_OUTPUT=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
      echo '{"'${S}'":' > ${TEMP_OUTPUT}
      if [ -s "${TEMP_FILE:-}" ]; then
	cat ${TEMP_FILE} >> ${TEMP_OUTPUT}
      else
	echo 'null' >> ${TEMP_OUTPUT}
      fi
      rm -f ${TEMP_FILE}
      echo '}' >> ${TEMP_OUTPUT}
      jq -s add "${TEMP_OUTPUT}" "${OUTPUT}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT}"
      rm -f ${TEMP_OUTPUT}
    done
    hzn.log.debug "service_otherServices_output: ${OUTPUT}"
  else
    hzn.log.debug "service_otherServices_output: no services"
  fi
  if [ -s "${OUTPUT}" ]; then echo 0; else echo 1; fi
}

## update service output
service_update()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local INPUT_FILE="${1}"
  local UPDATE_FILE=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  local SOF=$(service_output_file)

  hzn.log.debug "service_update: input: ${1}:" $(wc -c ${1})
  if [ -s "${INPUT_FILE}" ]; then
    jq -c '.' ${INPUT_FILE} > "${UPDATE_FILE}" 2> /dev/null
    if [ ! -s "${UPDATE_FILE}" ]; then
      hzn.log.warn "service_update: invalid JSON:" $(cat "${INPUT_FILE}")
    else
      hzn.log.debug "service_update: success" $(wc -c "${UPDATE_FILE}")
    fi
  fi
  if [ ! -s "${UPDATE_FILE}" ]; then
    hzn.log.warn "service_update: no input"
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${UPDATE_FILE}"
  fi
  hzn.log.debug "service_update: moving ${UPDATE_FILE} to ${SOF}"
  mv -f "${UPDATE_FILE}" "${SOF}"
  hzn.log.debug "service_update: output:" $(wc -c ${SOF})
}

## provide response in supplied file
service_output()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local OUTPUT=${1}
  local HCF=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  local SCF=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  local SOF=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  local RSOF=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")

  # get horizon config, service config, add together, clean-up
  hzn_config > "${HCF}"
  service_config > "${SCF}"
  jq -s add "${HCF}" "${SCF}" > "${OUTPUT}"
  rm -f "${HCF}" "${SCF}"

  # get service output
  hzn.log.debug "service_output: ${SERVICE_LABEL}: checking $(service_output_file)"
  echo '{"'${SERVICE_LABEL}'":' > "${SOF}"
  if [ -s $(service_output_file) ]; then
    cat $(service_output_file) >> "${SOF}"
  else
    hzn.log.warn "service_output: ${SERVICE_LABEL}: $(service_output_file) EMPTY"
    echo 'null' >> "${SOF}"
  fi
  echo '}' >> "${SOF}"

  # get required services
  if [ $(service_otherServices_output ${RSOF}) != 0 ]; then
    hzn.log.warn "service_output: service_otherServices_update failed"
  else
    # add required services
    jq -s add "${RSOF}" "${SOF}" > "${SOF}.$$" && mv -f "${SOF}.$$" "${SOF}"
    hzn.log.debug "service_output: success:" $(wc -c ${SOF})
  fi
  rm -f "${RSOF}"

  # add consolidated services & clean-up
  jq -s add "${SOF}" "${OUTPUT}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT}"
  rm -f "${SOF}"

  hzn.log.debug "service_output: complete: ${OUTPUT}; size:" $(wc -c ${OUTPUT})
}
