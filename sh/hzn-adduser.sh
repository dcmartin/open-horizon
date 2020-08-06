#!/bin/bash

user="${1}"
email="${2}"
password="${3:-password}"


if [ -z "${HZN_EXCHANGE_URL:-}" ]; then
  HZN_EXCHANGE_URL="http://exchange:3090/v1"
  if [ -s HZN_EXCHANGE_URL ]; then
    HZN_EXCHANGE_URL=$(cat HZN_EXCHANGE_URL)
  fi
fi

if [ -z "${HZN_EXCHANGE_APIKEY:-}" ]; then
  HZN_EXCHANGE_APIKEY="whocares"
  if [ -s HZN_EXCHANGE_APIKEY ]; then
    HZN_EXCHANGE_APIKEY=$(cat HZN_EXCHANGE_APIKEY)
  fi
fi

if [ -z "${HZN_ORG_ID:-}" ]; then
  HZN_ORG_ID="${USER}"
  if [ -s HZN_ORG_ID ]; then
    HZN_ORG_ID=$(cat HZN_ORG_ID)
  fi
fi

REQUEST='{ "password": "'${password}'", "admin": false, "email": "'${email}'" }'
URL="${HZN_EXCHANGE_URL%/}/orgs/${HZN_ORG_ID}/users/${user}"

echo "DOING..."
curl -sSL -X POST -w '%{http_code}' -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" -H 'Content-type: application/json' -d "${REQUEST}" "${URL}"

echo "CONFIRMING..."
curl -sSL -X GET -w '%{http_code}' -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" -H 'Content-type: application/json' "${URL}"
