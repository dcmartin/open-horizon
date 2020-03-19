#!/bin/bash

source ${0%/*}/node-tools.sh

if [ -z "${1:-}" ]; then
  hzn.log.error "Usage: ${0##*/} <device> [ <output-file> [ <timeout> ]]" &> /dev/stderr
  exit 1
fi

# machine and outputfile
machine=${1}
out=${2:-/dev/stdout}

# seconds
timeout=${3:-1.0}

# booleans
alive=false
purged=false
rebooting=null
  
# array of bad nodes
BAD=

# start BAD
if [ -z "${BAD:-}" ]; then BAD='['; else BAD="${BAD},"; fi

# test this node
if [ $(node_alive ${machine}) = true ]; then
  alive=true
  if [ $(node_reboot ${machine}) != true ]; then
    result=$(node_unregister ${machine})
    result=$(node_purge ${machine})
    hzn.log.debug "machine: ${machine}; purged"
    purged=true
  else
    hzn.log.debug "machine: ${machine}; rebooting"
    BAD="${BAD}"'{"machine":"'${machine}'","error":"rebooting"}'
  fi
else
  hzn.log.debug "machine: ${machine}; offline"
  BAD="${BAD}"'{"machine":"'${machine}'","error":"offline"}'
fi

# finish BAD
if [ ! -z "${BAD:-}" ]; then BAD="${BAD}"']'; fi

echo '{"machine":"'${machine}'","alive":'${alive}',"purged":'${purged}',"rebooting":'${rebooting}',"bad":'"${BAD:-null}"'}' | jq -c '.' >> ${out}
