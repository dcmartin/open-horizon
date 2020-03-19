#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

if [ -z "${MQTT_HOST:-}" ]; then echo "*** ERROR -- $0 $$ -- MQTT_HOST unspecified; exiting" >> ${LOGTO} 2>&1; exit 1; fi
if [ -z "${MQTT_PORT:-}" ]; then echo "*** ERROR -- $0 $$ -- MQTT_PORT unspecified; exiting" >> ${LOGTO} 2>&1; exit 1; fi
if [ -z "${FFT_DEVICE:-}" ]; then FFT_DEVICE=$(hostname) && echo "+++ WARN -- $0 $$ -- FFT_DEVICE unspecified; using: ${FFT_DEVICE}" >> ${LOGTO} 2>&1; fi

if [ -z "${MQTT_USERNAME:-}" ]; then if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- MQTT_USERNAME unspecified" >> ${LOGTO} 2>&1; fi; fi
if [ -z "${MQTT_PASSWORD:-}" ]; then if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- MQTT_PASSWORD unspecified" >> ${LOGTO} 2>&1; fi; fi
ARGS=${*}
if [ ! -z "${ARGS}" ]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- got arguments: ${ARGS}" >> ${LOGTO} 2>&1; fi
  if [ ! -z "${MQTT_USERNAME}" ]; then
    ARGS='-u '"${MQTT_USERNAME}"' '"${ARGS}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- set username: ${ARGS}" >> ${LOGTO} 2>&1; fi
  fi
  if [ ! -z "${MQTT_PASSWORD}" ]; then
    ARGS='-P '"${MQTT_PASSWORD}"' '"${ARGS}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- set password: ${ARGS}" >> ${LOGTO} 2>&1; fi
  fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- publishing as ${FFT_DEVICE} to ${MQTT_HOST} port ${MQTT_PORT} using arguments: ${ARGS}" >> ${LOGTO} 2>&1; fi
  mosquitto_pub -i "${FFT_DEVICE}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" ${ARGS} >> ${LOGTO} 2>&1
  exit $?
else
  if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- nothing to send" >> ${LOGTO} 2>&1; fi
  exit 1
fi
