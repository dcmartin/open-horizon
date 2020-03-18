#!/bin/bash

## hzn-tools.sh
source /usr/bin/hzn-tools.sh

###
### MAIN
###

# initialize horizon
if [ -z "$(hzn_init)" ]; then
  hzn.log.error "horizon initilization failure; exiting"
  exit 1
else
  export HZN=$(hzn_config)
fi

# label
if [ ! -z "${SERVICE_LABEL:-}" ]; then
  CMD=$(command -v "${SERVICE_LABEL:-}.sh")
  if [ ! -z "${CMD}" ]; then
    ${CMD} &
  fi
else
  hzn.log.warn "executable ${SERVICE_LABEL:-}.sh not found"
fi

# port
if [ -z "${SERVICE_PORT:-}" ]; then 
  SERVICE_PORT=80
else
  hzn.log.warn "using localhost port ${SERVICE_PORT}"
fi

# start listening
socat TCP4-LISTEN:${SERVICE_PORT},fork EXEC:service.sh
