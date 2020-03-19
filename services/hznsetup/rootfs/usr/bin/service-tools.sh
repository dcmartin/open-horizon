#!/usr/bin/env bash

if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

source /usr/bin/hzn-tools.sh

## utility functions

service_output_file()
{
  echo "${TMPDIR}/$(service_label).json"
}

service_otherServices()
{
  OUTPUT=
  CONFIG=$(service_config)
  if [ ! -z "${CONFIG}" ]; then OUTPUT=$(echo "${CONFIG}" | jq -c '.config.services'); fi
  if [ "${OUTPUT}" == 'null' ]; then OUTPUT=; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_otherServices: ${OUTPUT}" >> ${LOGTO} 2>&1; fi
  echo "${OUTPUT}"
}

service_label()
{
  echo "${SERVICE_LABEL:-}"
}

service_version()
{
  echo "${SERVICE_VERSION:-}"
}

## configuration

SERVICE_CONFIG_FILE=${TMPDIR}/config.json

service_init()
{
  CONFIG="${*}"
  if [ -s "${SERVICE_CONFIG_FILE}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_init: service already initialized" >> ${LOGTO} 2>&1; fi
  fi
  echo "${CONFIG}" | jq -c '.' > ${SERVICE_CONFIG_FILE}
  if [ -s ${SERVICE_CONFIG_FILE} ]; then
    OUTPUT=$(jq -c '.' ${SERVICE_CONFIG_FILE})
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_init: service initialized: ${OUTPUT}" >> ${LOGTO} 2>&1; fi
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_init: service initialization failed" >> ${LOGTO} 2>&1; fi
    OUTPUT= 
  fi
  echo "${OUTPUT}"
}

service_config()
{
  if [ ! -s "${SERVICE_CONFIG_FILE}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_config: service not initialized" >> ${LOGTO} 2>&1; fi
    CONFIG='null'
  else
    CONFIG=$(jq -c '.' ${SERVICE_CONFIG_FILE})
  fi
  OUT='{"config":'${CONFIG}',"service":{"label":"'$(service_label)'","version":"'$(service_version)'"}}' 
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_config: ${OUT}" >> ${LOGTO} 2>&1; fi
  echo "${OUT}"
}

## update services functions
service_otherServices_output() {
  OUTPUT=${1}
  echo '{}' > "${OUTPUT}"
  SERVICES=$(echo "$(service_otherServices)" | jq -r '.[]|.name')
  if [ ! -z "${SERVICES}" ] && [ "${SERVICES}" != 'null' ]; then
    for S in ${SERVICES}; do
      URL=$(echo "$(service_otherServices)" | jq -r '.[]|select(.name=="'${S}'").url')
      TEMP_FILE=$(mktemp -t "${0##*/}-XXXXXX")
      if [ ! -z "${URL}" ]; then
	curl -sSL "${URL}" | jq -c '.'"${S}" > ${TEMP_FILE} 2> /dev/null
      fi
      TEMP_OUTPUT=$(mktemp -t "${0##*/}-XXXXXX")
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
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_otherServices_output: ${OUTPUT}" >> ${LOGTO} 2>&1; fi
  else
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_otherServices_output: no services" >> ${LOGTO} 2>&1; fi
  fi
  if [ -s "${OUTPUT}" ]; then echo 0; else echo 1; fi
}

## update service output
service_update() {
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_update: input: ${1}:" $(wc -c ${1}) >> ${LOGTO} 2>&1; fi
  INPUT_FILE="${1}"
  UPDATE_FILE=$(mktemp -t "${0##*/}-XXXXXX")
  if [ -s "${INPUT_FILE}" ]; then
    jq -c '.' ${INPUT_FILE} > "${UPDATE_FILE}"
    if [ ! -s "${UPDATE_FILE}" ]; then
      if [ "${DEBUG}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_update: invalid JSON:" $(cat "${INPUT_FILE}") >> ${LOGTO} 2>&1; fi
    else
      if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_update: success" $(wc -c "${UPDATE_FILE}") >> ${LOGTO} 2>&1; fi
    fi
  fi
  if [ ! -s "${UPDATE_FILE}" ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_update: no input" >> ${LOGTO} 2>&1; fi
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${UPDATE_FILE}"
  fi
  SOF=$(service_output_file)
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_update: moving ${UPDATE_FILE} to ${SOF}" >> ${LOGTO} 2>&1; fi
  mv -f "${UPDATE_FILE}" "${SOF}"
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_update: output:" $(wc -c ${SOF}) >> ${LOGTO} 2>&1; fi
}

## provide response in supplied file
service_output()
{
  OUTPUT=${1}
  HCF=$(mktemp -t "${0##*/}-XXXXXX")
  # get horizon config
  hzn_config > "${HCF}"
  # get service config
  SCF=$(mktemp -t "${0##*/}-XXXXXX")
  service_config > "${SCF}"
  # add configurations together
  jq -s add "${HCF}" "${SCF}" > "${OUTPUT}"
  # remove files
  rm -f "${HCF}" "${SCF}"
  # get service output
  SOF=$(mktemp -t "${0##*/}-XXXXXX")
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_output: ${SERVICE_LABEL}: checking $(service_output_file)" >> ${LOGTO} 2>&1; fi
  echo '{"'${SERVICE_LABEL}'":' > "${SOF}"
  if [ -s $(service_output_file) ]; then
    cat $(service_output_file) >> "${SOF}"
  else
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_output: ${SERVICE_LABEL}: $(service_output_file) EMPTY" >> ${LOGTO} 2>&1; fi
    echo 'null' >> "${SOF}"
  fi
  echo '}' >> "${SOF}"
  # get required services
  RSOF=$(mktemp -t "${0##*/}-XXXXXX")
  if [ $(service_otherServices_output ${RSOF}) != 0 ]; then
    if [ "${DEBUG}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- service_output: service_otherServices_update failed" >> ${LOGTO} 2>&1; fi
  else
    # add required services
    jq -s add "${RSOF}" "${SOF}" > "${SOF}.$$" && mv -f "${SOF}.$$" "${SOF}"
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_output: success:" $(wc -c ${SOF}) >> ${LOGTO} 2>&1; fi
  fi
  rm -f "${RSOF}"
  # add consolidated services
  jq -s add "${SOF}" "${OUTPUT}" > "${OUTPUT}.$$" && mv -f "${OUTPUT}.$$" "${OUTPUT}"
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_output: complete: ${OUTPUT}; size:" $(wc -c ${OUTPUT}) >> ${LOGTO} 2>&1; fi
  # remove
  rm -f "${SOF}"
}
