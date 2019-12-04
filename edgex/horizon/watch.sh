#!/bin/bash
echo "Watching ..."
before=$(date +%s)
while true; do
  event=$(hzn eventlog list -a | jq -r '.[-1]' 2> /dev/null)
  when=$(echo "${event}" | awk -F": " '{ print $1 }')
  if [ "${when}" != "${prior:-}" ]; then
    what=$(echo "${event}" | sed 's/.*:   //')
    echo "$(($(date +%s)-before)): ${what}"
    if [ $(echo "${what}" | grep 'running' &> /dev/null && echo 'true' || echo 'false') = 'true' ]; then echo "*** UP AND RUNNING ***"; fi
    prior=${when}
  fi
  sleep 1
done
