#!/bin/bash
T=$(mktemp -t "${0##*/}-XXXXXX") && U=$(echo 'scan on' | bluetoothctl 2> /dev/null >> ${T} && sleep 1 && echo 'scan off' | bluetoothctl 2> /dev/null >> ${T} &> /dev/null ; egrep 'Device' ${T} | sed 's/^.*\(Device .*\)/\1/' | awk 'BEGIN { x=0; printf("[") } { if (x++ > 0) printf(","); printf("\"%s\"", $2) } END { printf("]\n") }' | jq -c '.') && rm -f ${T} && echo "${U}"
