#!/usr/bin/env bash

source /usr/bin/hzn-tools.sh

## utility functions

service_output_file()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  echo "${TMPDIR}/$(service_label).json"
}

service_otherServices()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  OUTPUT=
  CONFIG=$(service_config)
  if [ ! -z "${CONFIG}" ]; then OUTPUT=$(echo "${CONFIG}" | jq -c '.config.services'); fi
  if [ "${OUTPUT}" == 'null' ]; then OUTPUT=; fi
  echo "${OUTPUT}"
}

service_label()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  echo "${SERVICE_LABEL:-}"
}

service_version()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  echo "${SERVICE_VERSION:-}"
}

service_port()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  echo "${SERVICE_PORT:-0}"
}

## configuration

SERVICE_CONFIG_FILE=${TMPDIR}/config.json

service_init()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  CONFIG="${*}"
  if [ -s "${SERVICE_CONFIG_FILE}" ]; then
    hzn.log.warn "service already initialized"
  fi
  echo "${CONFIG}" | jq -c '.' > ${SERVICE_CONFIG_FILE}
  if [ -s ${SERVICE_CONFIG_FILE} ]; then
    hzn.log.notice "service initialized: " $(cat ${SERVICE_CONFIG_FILE})
  else
    hzn.log.warn "service initialization failed"
  fi
}

service_config()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  if [ ! -s "${SERVICE_CONFIG_FILE}" ]; then
    hzn.log.alert "service not initialized"
    CONFIG='null'
  else
    CONFIG=$(jq -c '.' ${SERVICE_CONFIG_FILE})
  fi
  OUT='{"config":'${CONFIG}',"service":{"label":"'$(service_label)'","version":"'$(service_version)'","port":'$(service_port)'}}' 
  echo "${OUT}"
}

## update services functions
service_otherServices_output()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  OUTPUT=${1}
  echo '{}' > "${OUTPUT}"
  SERVICES=$(echo "$(service_otherServices)" | jq -r '.[]|.name')
  if [ ! -z "${SERVICES}" ] && [ "${SERVICES}" != 'null' ]; then
    for S in ${SERVICES}; do
      URL=$(echo "$(service_otherServices)" | jq -r '.[]|select(.name=="'${S}'").url')
      TEMP_FILE=$(mktemp)
      if [ ! -z "${URL}" ]; then
	curl -sSL "${URL}" | jq -c '.'"${S}" > ${TEMP_FILE} 2> /dev/null
      fi
      TEMP_OUTPUT=$(mktemp)
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
  else
    hzn.log.info "no services"
  fi
  if [ -s "${OUTPUT}" ]; then echo 0; else echo 1; fi
}

## update service output
service_update()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  INPUT_FILE="${1}"
  UPDATE_FILE=$(mktemp)
  if [ -s "${INPUT_FILE}" ]; then
    jq -c '.' ${INPUT_FILE} > "${UPDATE_FILE}"
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
  SOF=$(service_output_file)
  mv -f ${UPDATE_FILE} ${SOF}
}

## provide response in supplied file
service_output()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  OUTPUT=${1}
  HCF=$(mktemp)
  # get horizon config
  hzn_config > "${HCF}"
  # get service config
  SCF=$(mktemp)
  service_config > "${SCF}"
  # add configurations together
  jq -s add "${HCF}" "${SCF}" > "${OUTPUT}"
  # remove files
  rm -f "${HCF}" "${SCF}"
  # get service output
  SOF=$(mktemp)
  echo '{"'${SERVICE_LABEL}'":' > "${SOF}"
  if [ -s $(service_output_file) ]; then
    hzn.log.debug "service_output: ${SERVICE_LABEL}: valid: $(service_output_file)"
    cat $(service_output_file) >> "${SOF}"
  else
    hzn.log.warn "service_output: ${SERVICE_LABEL}: EMPTY: $(service_output_file)"
    echo 'null' >> "${SOF}"
  fi
  echo '}' >> "${SOF}"
  # get required services
  RSOF=$(mktemp)
  if [ $(service_otherServices_output ${RSOF}) != 0 ]; then
    hzn.log.debug "no additional services output"
  else
    # add required services
    jq -s add "${RSOF}" "${SOF}" > "${SOF}.$$" && mv -f "${SOF}.$$" "${SOF}"
    hzn.log.debug "service_output: success:" $(wc -c ${SOF})
  fi
  rm -f "${RSOF}"
  # add consolidated services
  jq -s add "${SOF}" "${OUTPUT}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT}"
  # remove
  rm -f "${SOF}"
}
