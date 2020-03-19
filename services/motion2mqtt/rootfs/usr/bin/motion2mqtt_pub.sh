#!/bin/bash

if [ -z "${MQTT_HOST:-}" ]; then echo "*** ERROR -- $0 $$ -- MQTT_HOST unspecified; exiting" &> /dev/stderr; exit 1; fi
if [ -z "${MQTT_PORT:-}" ]; then echo "*** ERROR -- $0 $$ -- MQTT_PORT unspecified; exiting" &> /dev/stderr; exit 1; fi
if [ -z "${MOTION_CLIENT:-}" ]; then echo "*** ERROR -- $0 $$ -- MOTION_CLIENT unspecified; exiting" &> /dev/stderr; exit 1; fi

if [ -z "${MQTT_USERNAME:-}" ]; then if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- MQTT_USERNAME unspecified" &> /dev/stderr; fi; fi
if [ -z "${MQTT_PASSWORD:-}" ]; then if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- MQTT_PASSWORD unspecified" &> /dev/stderr; fi; fi

ARGS=${*}
if [ ! -z "${ARGS}" ]; then
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- got arguments: ${ARGS}" &> /dev/stderr; fi
  if [ ! -z "${MQTT_USERNAME}" ]; then
    ARGS='-u '"${MQTT_USERNAME}"' '"${ARGS}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- set username: ${ARGS}" &> /dev/stderr; fi
  fi
  if [ ! -z "${MQTT_PASSWORD}" ]; then
    ARGS='-P '"${MQTT_PASSWORD}"' '"${ARGS}"
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- set password: ${ARGS}" &> /dev/stderr; fi
  fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- publishing as ${MOTION_CLIENT} to ${MQTT_HOST} port ${MQTT_PORT} using arguments: ${ARGS}" &> /dev/stderr; fi
  mosquitto_pub -i "${MOTION_CLIENT}" -h "${MQTT_HOST}" -p "${MQTT_PORT}" ${ARGS} &> /dev/stderr
  exit $?
else
  if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- nothing to send" &> /dev/stderr; fi
  exit 1
fi
