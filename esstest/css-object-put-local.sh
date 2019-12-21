#!/bin/bash
# arguments that can be changed
objectID=${1:-test}
objectType=${2:-model}
# read data from stdin & put data
cat | \
  curl -sSL -X PUT \
    -u "${HZN_ORG_ID}/${HZN_ORG_ID}admin:${HZN_ORG_ID}adminpw" \
    -w '%{http_code}' \
    --header 'Content-Type:application/octet-stream' \
    --data-binary @- \
    "http://localhost:8580/api/v1/objects/${HZN_ORG_ID}/${objectType}/${objectID}/data"
