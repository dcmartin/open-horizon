#!/bin/bash

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

user="$1"
org="${HZN_ORG_ID}"

echo curl -sS -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" -X PATCH "${HZN_EXCHANGE_URL}/orgs/${org}/users/${user}" -H "accept: application/json" -H "Content-Type: application/json" -d '{"admin":true}'
echo " "

curl -sS -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" -X PATCH "${HZN_EXCHANGE_URL}/orgs/${org}/users/${user}" -H "accept: application/json" -H "Content-Type: application/json" -d '{"admin":true}' | jq .
echo " "

curl -sS -u "${HZN_ORG_ID}/${HZN_USER_ID:-${USER}}:${HZN_EXCHANGE_APIKEY}" -X GET "${HZN_EXCHANGE_URL}/orgs/${org}/users/${user}" -H "accept: application/json" -H "Content-Type: application/json" | jq .
echo " "
