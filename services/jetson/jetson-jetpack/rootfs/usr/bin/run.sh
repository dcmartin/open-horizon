#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

## hzn-tools.sh
source /usr/bin/hzn-tools.sh

###
### MAIN
###

# initialize horizon
if [ -z "$(hzn_init)" ]; then
  echo "*** ERROR$0 $$ -- horizon initilization failure; exiting" &> /dev/stderr
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
  echo "+++ WARN $0 $$ -- executable ${SERVICE_LABEL:-}.sh not found" &> /dev/stderr
fi

# port
if [ -z "${SERVICE_PORT:-}" ]; then 
  SERVICE_PORT=80
else
  echo "+++ WARN: using localhost port ${SERVICE_PORT}" &> /dev/stderr
fi

# start listening
socat TCP4-LISTEN:${SERVICE_PORT},fork EXEC:service.sh
