#!/bin/bash

source /usr/bin/service-tools.sh

###
### MAIN
###

RESPONSE_FILE=$(mktemp -t "${0##*/}-XXXXXX")
service_output ${RESPONSE_FILE}
SIZ=$(wc -c "${RESPONSE_FILE}" | awk '{ print $1 }')
hzn.log.trace "HTTP RESPONSE: ${RESPONSE_FILE}; size: ${SIZ}"

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo ""
cat "${RESPONSE_FILE}"
rm -f ${RESPONSE_FILE}
