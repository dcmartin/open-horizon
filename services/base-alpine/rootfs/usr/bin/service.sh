#!/usr/bin/with-contenv bashio

source /usr/bin/service-tools.sh

service()
{
  bashio::log.trace "${FUNCNAME[0]} ${*}"

  local RESPONSE_FILE=$(mktemp)
  local SIZ

  hzn::service.output ${RESPONSE_FILE}
  SIZ=$(wc -c "${RESPONSE_FILE}" | awk '{ print $1 }')

  bashio::log.trace "${FUNCNAME[0]}: HTTP RESPONSE: ${RESPONSE_FILE}; size: ${SIZ}"

  echo "HTTP/1.1 200 OK"
  echo "Content-Type: application/json; charset=ISO-8859-1"
  echo "Content-length: ${SIZ}" 
  echo "Access-Control-Allow-Origin: *"
  echo ""
  cat "${RESPONSE_FILE}"
  rm -f ${RESPONSE_FILE}
}

###
### MAIN
###

bashio::log.notice "${0} ${*}"

# TMPDIR
if [ -d '/tmpfs' ]; then export TMPDIR=${TMPDIR:-/tmpfs}; else export TMPDIR=${TMPDIR:-/tmp}; fi

service ${*}
