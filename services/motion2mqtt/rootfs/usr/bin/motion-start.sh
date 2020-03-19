#!/usr/bin/env bash

###
### MOTION tools
### 

export MOTION_CONF_FILE="/etc/motion/motion.conf"
export MOTION_PID_FILE="/var/run/motion/motion.pid" 
export MOTION_CMD=$(command -v motion)

motion_pid()
{
  PID=
  if [ -s "${MOTION_PID_FILE}" ]; then
    PID=$(cat ${MOTION_PID_FILE})
  fi
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion PID: ${PID}" &> /dev/stderr; fi
  echo ${PID}
}

motion_start()
{
  PID=$(motion_pid)
  if [ -z "${PID}" ]; then
    rm -f ${MOTION_PID_FILE}
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- starting ${MOTION_CMD} with ${MOTION_CONF_FILE}" &> /dev/stderr; fi
    # config should be daemon
    ${MOTION_CMD} -c "${MOTION_CONF_FILE}" &
    while [ -z "$(motion_pid)" ]; do
      if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- waiting on motion" &> /dev/stderr; fi
      sleep 1
    done
    PID=$(motion_pid)
    # start watchdog
    motion_watchdog
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion started ${MOTION_CMD}; PID: ${PID}" &> /dev/stderr; fi
  else
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- motion running ${MOTION_CMD}; PID: ${PID}" &> /dev/stderr; fi
  fi
}

motion_watchdog()
{
  WATCHDOG_CMD=$(command -v motion-watchdog.sh)
  if [ -z "${WATCHDOG_CMD}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- no motion-watchdog.sh command found" &> /dev/stderr; fi
  else
    PID=$(ps | awk '{ print $1,$4 }' | egrep "${WATCHDOG_CMD}" | awk '{ print $1 }')
    if [ -z "${PID}" ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- starting ${WATCHDOG_CMD} on ${MOTION_CMD}" &> /dev/stderr; fi
      ${WATCHDOG_CMD} ${MOTION_CMD} $(motion_pid) &
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- started ${WATCHDOG_CMD} on ${MOTION_CMD}" &> /dev/stderr; fi
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- ${WATCHDOG_CMD} running; PID: ${PID}" &> /dev/stderr; fi
    fi
  fi
}
