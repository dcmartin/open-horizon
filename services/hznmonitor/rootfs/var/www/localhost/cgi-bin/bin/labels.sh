#!/bin/bash

if [ -d "/tmpfs" ]; then TMPDIR="/tmpfs"; else TMPDIR="/tmp"; fi

###
### MAIN
###

PIDFILE="${TMPDIR}/${0##*/}.pid"
if [ -e ${PIDFILE} ]; then
  echo "IN-PROGRESS; PID: " $(cat ${PIDFILE}) &> /dev/stderr
else
  exec 0>&- # close stdin
  exec 1>&- # close stdout
  exec 2>&- # close stderr
  ./bin/mklabels.sh ${1} &
  PID=$!
  echo "${PID}" | tee ${PIDFILE}
  wait ${PID}
  rm -f ${PIDFILE}
fi
