#!/bin/bash
# arguments that can be changed
objectID=${1:-test}
objectType=${2:-model}
version='0.0.1'
destinationID=
destinationType=
# object metadata
META='{"meta":{"objectID":"'${objectID}'","objectType":"'${objectType}'","destinationID":"'${destinationID}'","destinationType":"'${destinationType}'","version":"'${version}'","description":"'$(date -u +%FT%TZ)'"}}'
# create object
echo "${META}" | \
  curl -sSL -X PUT \
    -u "${HZN_ORG_ID}/${HZN_ORG_ID}admin:${HZN_ORG_ID}adminpw" \
    -w '%{http_code}' \
    --header 'Content-Type:application/octet-stream' \
    --data-binary @- \
    "http://localhost:8580/api/v1/objects/${HZN_ORG_ID}/${objectType}/${objectID}"
