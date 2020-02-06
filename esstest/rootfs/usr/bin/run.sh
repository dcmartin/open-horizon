#!/bin/bash

# set object type 
objectType='model'

# loop forever retrieving objects
while true; do
  ess-objects-get.sh "${objectType}" | jq '.'
  sleep 3
done

## alternative
# listen to port 8080 forever, fork a new process executing script /usr/bin/service.sh to return response
# socat TCP4-LISTEN:8080,fork EXEC:/usr/bin/service.sh
