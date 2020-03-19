#!/bin/bash

# set -o nounset  # Exit script on use of an undefined variable
# set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells

## parent functions
source /usr/bin/service-tools.sh
source /usr/bin/apache-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## configuration
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","LOGTO":"'${LOGTO:-}'","LOG_LEVEL":"'${LOG_LEVEL:-}'","DEBUG":'${DEBUG:-false}'}'

## initialize service
service_init ${CONFIG}

hzn.log.notice "Service initialized"

# create output file
OUTPUT_FILE=$(mktemp -t "${0##*/}-XXXXXX")

# loop while node is alive
while [ true ]; do
  # create output
  echo '{"pid":'$$',"timestamp":"'$(date -u +%FT%TZ)'"}' > ${OUTPUT_FILE}
  service_update ${OUTPUT_FILE}
  sleep ${BASE_PERIOD:-30}
done
