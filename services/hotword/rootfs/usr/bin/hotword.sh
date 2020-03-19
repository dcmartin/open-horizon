#!/bin/bash

source /usr/bin/service-tools.sh

hzn_init

CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'"}'
service_init "${CONFIG}"

while true; do
done
