#!/usr/bin/with-contenv bashio

## hzn-tools.sh
source /usr/bin/hzn-tools.sh

###
### run.sh
###

function run::main()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local init=$(hzn::init)

  # initialize horizon
  if [ -z "${init:-}" ]; then
    hzn::log.error "${FUNCNAME[0]}: horizon initialization failed"
  else
    local config=$(hzn::config)

    if [ -z "${config:-}" ]; then
      hzn::log.error "${FUNCNAME[0]}: no horizon configuration"
    else
      hzn::log.debug "${FUNCNAME[0]}: init: ${init:-}; config: ${config:-}"

      # label
      if [ ! -z "${SERVICE_LABEL:-}" ]; then
        local CMD=$(command -v "${SERVICE_LABEL:-}.sh")
  
        if [ ! -z "${CMD}" ]; then
          hzn::log.info "${FUNCNAME[0]}: starting command: ${CMD}"
          ${CMD} &
        fi

        # port
        if [ -z "${SERVICE_PORT:-}" ]; then
          SERVICE_PORT=80
          hzn::log.warning "${FUNCNAME[0]}: service port not specified; using localhost port ${SERVICE_PORT}"
        fi

        # start listening
        hzn::log.info "${FUNCNAME[0]}: service listening on http://localhost:${SERVICE_PORT}"
        socat TCP4-LISTEN:${SERVICE_PORT},fork EXEC:service.sh
      else
        hzn::log.warning "${FUNCNAME[0]}: executable ${SERVICE_LABEL:-}.sh not found"
      fi
    fi
  fi
}

###
### main
###

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

hzn::log.notice "${0} ${*}; TMPDIR: ${TMPDIR:-null}; LOG_LEVEL: ${LOG_LEVEL:-null}"

run::main ${*}
