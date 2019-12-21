#!/bin/bash

# Type
objectType='model'

# request all objects of objectType that have not been received
OBJECTS=$(/usr/bin/ess-objects-get.sh "${objectType}") 

echo "HTTP/1.1 200 OK"
echo
echo '{"count":'$(echo "${OBJECTS:-null}" | jq '.|length')',"'${objectType}'":'${OBJECTS:-null}'}'
