#!/bin/bash

user="$1"
org="${HZN_ORG_ID}"

echo curl -sS -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -X PATCH "${HZN_EXCHANGE_URL}/orgs/${org}/users/${user}" -H "accept: application/json" -H "Content-Type: application/json" -d '{"admin":true}'
echo " "

curl -sS -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -X PATCH "${HZN_EXCHANGE_URL}/orgs/${org}/users/${user}" -H "accept: application/json" -H "Content-Type: application/json" -d '{"admin":true}' | jq .
echo " "

curl -sS -u "${HZN_ORG_ID}/${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -X GET "${HZN_EXCHANGE_URL}/orgs/${org}/users/${user}" -H "accept: application/json" -H "Content-Type: application/json" | jq .
echo " "
