#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### noize-watchdog.sh
###

## 
source /usr/bin/noize-tools.sh

###
### MAIN
###

if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- starting: ${*}" >> ${LOGTO} 2>&1; fi

PID=${1}
BFP=${2}

if [ -z "${PID:-}" ]; then echo "*** ERROR -- $0 $$ -- no PID; exiting" >> ${LOGTO} 2>&1; fi
if [ -z "${BFP:-}" ]; then 
  echo "*** ERROR -- $0 $$ -- no base filepath; exiting" >> ${LOGTO} 2>&1
fi

# FOREVER
while true; do
  pid=$(ps | awk '{ print $1 }' | egrep '^'${PID})
  if [ -z "${pid:-}" ]; then
    if [ ${NOIZE_MOCK:-false} = true ]; then
      # available mock data in MOCK_DATADIR 
      MOCKS=( wren mixer_1 mixer_2 square )
      if [ -z "${ITERATION:-}" ]; then MOCK_INDEX=0 && ITERATION=1; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); ITERATION=$((ITERATION+1)); fi
      if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
      MOCK="${MOCKS[${MOCK_INDEX}]}"
      MOCK_WAVFILE="${NOIZE_MOCK_DATADIR}/${MOCK}.wav"
      if [ -s ${MOCK_WAVFILE}  ]; then
	DEST=${BFP%/*}/mock-${MOCK}.wav
	# DEST=${BFP}.wav
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- using mock data: ${MOCK}; size:" $(wc -c "${MOCK_WAVFILE}") >> ${LOGTO} 2>&1; fi
	cp -f ${MOCK_WAVFILE} ${DEST}
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- copied: ${MOCK_WAVFILE}; dest: ${DEST}" >> ${LOGTO} 2>&1; fi
      else
	if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- cannot locate mock: ${MOCK}; dir: ${NOIZE_MOCK_DATADIR}" >> ${LOGTO} 2>&1; fi
      fi
    else
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no process; no mock" >> ${LOGTO} 2>&1; fi
    fi
    if [ "${NOIZE_RESTART:-false}" = true ]; then
      PID=$(noize_detect_noise ${BFP})
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- restarted noize_detect_noise; dir: ${BFP}; PID: ${PID}" >> ${LOGTO} 2>&1; fi
    fi
  fi
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- sleeping" >> ${LOGTO} 2>&1; fi
  sleep ${NOIZE_PERIOD:-5}
done
