#!/bin/bash

if [ -z "${NMAP_PERIOD:-}" ]; then NMAP_PERIOD=180; fi

# don't update statistics more than once per (in seconds)
SECONDS=$(date "+%s")
DATE=$(echo ${SECONDS} \/ ${NMAP_PERIOD} \* ${NMAP_PERIOD} | bc)

# output target
OUTPUT="/tmp/${0##*/}.${DATE}.json"
# test if been-there-done-that
if [ ! -s "${OUTPUT}" ]; then
  if [ ! -e "${OUTPUT}" ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ INFO -- $0 $$ -- running ${0%/*}/nmap.sh ${OUTPUT}" &> /dev/stderr; fi
    touch ${OUTPUT}
    ${0%/*}/nmap.sh "${OUTPUT}" &
  fi
  LAST=($(echo "/tmp/${0##*/}".*.json))
  N=${#LAST[@]}
  if [ ${N} -gt 0 ]; then
    OUTPUT=${LAST[(${N}-1)]}
    # remove old output
    if [ ${N} -gt 1 ]; then
      OLD=$(echo ${LAST[@]} | tr ' ' '\n' | head -$((N-1)))
      rm -f ${OLD}
    fi
  fi
fi

echo "HTTP/1.1 200 OK"
echo
if [ -s "${OUTPUT}" ]; then
  cat ${OUTPUT}
else
  echo '{"nmap":[]}'
fi
