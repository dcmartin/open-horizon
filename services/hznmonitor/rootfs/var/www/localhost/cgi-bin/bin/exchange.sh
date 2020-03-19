#!/bin/bash
exchange=$(curl -fsSL "${HZNMONITOR_EXCHANGE_URL%/}/admin/status" -u ${HZNMONITOR_EXCHANGE_ORG}/${HZNMONITOR_EXCHANGE_USER:-iamapikey}:${HZNMONITOR_EXCHANGE_APIKEY} 2> /dev/null)
echo "${exchange:-null}" | jq '.org="'${HZNMONITOR_EXCHANGE_ORG}'"|.user="'${HZNMONITOR_EXCHANGE_USER}'"|.url="'${HZNMONITOR_EXCHANGE_URL}'"'

