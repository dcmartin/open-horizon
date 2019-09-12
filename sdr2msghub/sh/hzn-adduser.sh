#!/bin/bash

user="${1}"
email="${2}"
password="${3:-password}"

HZN_ORG_ID="${HZN_ORG_ID:-dcmartin}"
HZN_EXCHANGE_APIKEY="${HZN_EXCHANGE_APIKEY:-HZN_EXCHANGE_APIKEY}"
HZN_EXCHANGE_URL="${HZN_EXCHANGE_URL:-http://exchange.dcmartin.com:3090/v1}"

REQUEST='{ "password": "'${password}'", "admin": false, "email": "'${email}'" }'
URL="${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/users/${user}"

echo "DOING..."
curl -sSL -X POST -w '%{http_code}' -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -H 'Content-type: application/json' -d "${REQUEST}" "${URL}"

echo "CONFIRMING..."
curl -sSL -X GET -w '%{http_code}' -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -H 'Content-type: application/json' "${URL}"
