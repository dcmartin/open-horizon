#!/usr/bin/with-contenv bashio

source /usr/bin/hzn-tools.sh

## utility functions

hzn::service.otherServices()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local OUTPUT=
  local CONFIG=$(hzn::service.config)

  if [ ! -z "${CONFIG}" ]; then OUTPUT=$(echo "${CONFIG}" | jq -c '.config.services'); fi
  if [ "${OUTPUT}" == 'null' ]; then OUTPUT=; fi
  echo "${OUTPUT}"
}

hzn::service.label()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  echo "${SERVICE_LABEL:-}"
}

hzn::service.version()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  echo "${SERVICE_VERSION:-}"
}

hzn::service.port()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  echo "${SERVICE_PORT:-80}"
}

## initialization

hzn::service.init()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config="${*}"
  local file=$(hzn::service.config.file)

  if [ -s "${file}" ]; then
    hzn::log.debug "${FUNCNAME[0]}: service re-initializing; file: ${file}"
  fi

  if [ ! -z "${config}" ]; then
    hzn::log.debug "${FUNCNAME[0]}: updating service configuration; file: ${file}; config: ${config}"
    echo "${config}" | jq -c '.' > ${file}

    if [ -s ${file} ]; then
      hzn::log.debug "${FUNCNAME[0]}: service initialized; file: ${file}; config: ${config}"
    else
      hzn::log.error "${FUNCNAME[0]}: invalid configuration; zero-length configuration file: ${file}; config: ${config}"
    fi
  else
    hzn::log.error "${FUNCNAME[0]}: zero-length configuration"
  fi
}

## configuration

hzn::service.config.file()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"
  echo "/var/run/horizon.$(hzn::service.label).config.json"
}

hzn::service.config()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local file=$(hzn::service.config.file)
  local config

  if [ ! -s ${file:-} ]; then
    hzn::log.error "${FUNCNAME[0]}: ${SERVICE_LABEL} has not been configured"
  else
    config=$(jq -c '.' ${file})
  fi
  echo '{"config":'${config:-null}',"service":{"label":"'$(hzn::service.label)'","version":"'$(hzn::service.version)'","port":'$(hzn::service.port)'}}'
}

## output
hzn::service.output.otherServices()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local os=$(hzn::service.otherServices)
  local result=${1}

  if [ ${os:-null} != 'null' ]; then
    local svcs=$(echo "${os:-null}" | jq -r '.[]|.name')

    if [ ${svcs:-null} != 'null' ]; then
      hzn::log.debug "${FUNCNAME[0]}: processing other services: ${svcs}"
      local file=$(mktemp)
      local output=$(mktemp)

      echo '{}' > "${result}"
      for S in ${svcs}; do
        hzn::log.debug "${FUNCNAME[0]}: processing service: ${S}"

        local url=$(echo "${os}" | jq -r '.[]|select(.name=="'${S}'").url')
  
        if [ ! -z "${url}" ]; then
	  curl -sSL "${url}" | jq -c '.'"${S}" > ${file} 2> /dev/null
          echo '{"'${S}'":' > ${output}
          if [ -s "${file:-}" ]; then
	    cat ${file} >> ${output}
          else
	    echo 'null' >> ${output}
          fi
          echo '}' >> ${output}
          jq -s add "${output}" "${result}" > "${result}.$$" && mv -f "${result}.$$" "${result}"
        else
          hzn::log.warning "${FUNCNAME[0]}: no url; service: ${S}"
        fi
      done
      # cleanup
      rm -f ${file}
      rm -f ${output}
    else
      hzn::log.info "${FUNCNAME[0]}: no other service names"
    fi
  else
    hzn::log.info "${FUNCNAME[0]}: no other services"
  fi
  if [ -s "${result}" ]; then echo 0; else echo 1; fi
}

## service output file
hzn::service.output.file()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  echo "/var/run/$(hzn::service.label).output.json"
}

## provide response in supplied file
hzn::service.output()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local OUTPUT=${1:-}
  local HCF=$(mktemp).hcf
  local SCF=$(mktemp).scf
  local SOF=$(mktemp).sof
  local RSOF=$(mktemp).rsof

  # get horizon config
  hzn::config > "${HCF}"
  hzn::log.debug "${FUNCNAME[0]}: horizon configuration: ${HCF}:" $(jq -c '.' ${HCF})
  # get service config
  hzn::service.config > "${SCF}"
  hzn::log.debug "${FUNCNAME[0]}: service configuration: ${SCF}:" $(jq -c '.' ${SCF})

  if [ -s "${HCF}" ] && [ -s "${SCF}" ]; then
    # add configurations together
    jq -s add "${HCF}" "${SCF}" > "${OUTPUT}"
    hzn::log.debug "${FUNCNAME[0]}: merged configurations:" $(jq -c '.' ${OUTPUT})
  else
    hzn::log.error "${FUNCNAME[0]}: missing configurations; horizon: $(jq -c '.' ${HCF}); service: $(jq -c '.' ${SCF})"
    echo '{}' > ${OUTPUT}
  fi
  rm -f ${HCF} ${SCF}

  local file=$(hzn::service.output.file)

  # get service output
  if [ -s ${file} ]; then
    echo '{"'${SERVICE_LABEL:-}'":' > "${SOF}"
    cat ${file} >> "${SOF}"
    echo '}' >> "${SOF}"
    hzn::log.debug "${FUNCNAME[0]}: ${SERVICE_LABEL}; output:" $(jq -c '.' ${SOF})
  else
    hzn::log.warning "${FUNCNAME[0]}: ${SERVICE_LABEL}; no output"
    echo '{}' > ${SOF}
  fi
 
  # get required services
  if [ $(hzn::service.output.otherServices ${RSOF}) != 0 ]; then
    hzn::log.warning "${FUNCNAME[0]}: required services; no output"
  else
    # add required services
    jq -s add "${RSOF}" "${SOF}" > "${SOF}.$$" \
      && \
      mv -f "${SOF}.$$" "${SOF}" \
      && \
      hzn::log.debug "${FUNCNAME[0]}: added required services" \
      || \
      hzn::log.error "${FUNCNAME[0]}: failed to add required services"
  fi

  if [ -s "${SOF:-}" ]; then
    # add consolidated services
    jq -s add "${SOF}" "${OUTPUT}" > "${OUTPUT}.$$" \
      && \
      mv -f "${OUTPUT}.$$" "${OUTPUT}" \
      && \
      hzn::log.debug "${FUNCNAME[0]}: consolidated service output" \
      || \
      hzn::log.error "${FUNCNAME[0]}: failed to consolidate services"
  else
    hzn::log.warning "${FUNCNAME[0]}: no service output"
  fi

  # cleanup
  rm -f ${HCF} ${SCF} ${RSOF} ${SOF}
}

## update service output
hzn::service.update()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local input="${1:-}"
  local update=$(mktemp)

  if [ -s "${input}" ]; then
    jq -c '.' ${input} > "${update}"
    if [ ! -s "${update}" ]; then
      hzn::log.error "${FUNCNAME[@]}: invalid JSON:" $(cat "${input}")
    else
      hzn::log.debug "${FUNCNAME[0]}: success" $(wc -c "${update}")
    fi
  fi
  if [ ! -s "${update}" ]; then
    hzn::log.warning "${FUNCNAME[0]}: no update; using timestamp and date only"
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)'}' > "${update}"
  fi
  mv -f ${update} $(hzn::service.output.file)
}
