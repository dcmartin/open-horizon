#!/usr/bin/env bash

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### noize-tools.sh
###
##
## noize_detect_noise()
## noize_detect_watchdog()
##

## source SOX
source /usr/bin/sox-tools.sh

## mock data
NOIZE_MOCK_DATADIR=/etc/noize/samples

## noize_detect_watchdog()
#
noize_detect_watchdog()
{
  if [ ! -z "${1:-}" ] && [ ! -z "${2:-}" ]; then
    pid=${1}
    filepath=${2}
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- noize_detect_watchdog: pid: ${pid}; filepath: ${filepath}" >> ${LOGTO} 2>&1; fi
    ${0%/*}/noize-watchdog.sh ${pid} ${filepath} >> ${LOGTO} 2>&1 &
    PID=$!
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- noize_detect_watchdog: started watchdog; PID: ${PID}" >> ${LOGTO} 2>&1; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- noize_detect_watchdog: no PID or filepath" >> ${LOGTO} 2>&1; fi
  fi
  echo ${PID:-0}
}

## noize_detect_noise()
#
noize_detect_noise()
{
  if [ ! -z "${1:-}" ]; then
    FILEPATH="${1}"
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- noize_detect_noise: filepath: ${FILEPATH}" >> ${LOGTO} 2>&1; fi
    ## start listener
    pid=$(sox_detect_noise ${FILEPATH} ${NOIZE_START_LEVEL} ${NOIZE_START_SECONDS} ${NOIZE_TRIM_DURATION} ${NOIZE_THRESHOLD})
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- started sox; PID: ${pid}" >> ${LOGTO} 2>&1; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- noize_detect_noise: no filepath" >> ${LOGTO} 2>&1; fi
  fi
  echo ${pid:-0}
}
