#!/bin/bash

source /usr/bin/hzn-tools.sh

scan4ble()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  T=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  S=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  echo 'scan on' | bluetoothctl 2> ${S} >> ${T}
  sleep ${1:-1} 
  echo 'scan off' | bluetoothctl 2> ${S} >> ${T}
  sleep ${1:-1} 
  U=$(egrep 'Device' ${T} | sed 's/^.*\(Device .*\)/\1/' | awk 'BEGIN { x=0; printf("[") } { if (x++ > 0) printf(","); printf("\"%s\"", $2) } END { printf("]\n") }')
  rm -f ${T} ${S}
  echo "${U}"
}

connect2macs()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  MACS=$(scan4ble ${1:-5})
  hzn.log.info "Found MACS: ${MACS}"
  macs=$(echo "${MACS:-null}" | jq -r '.[]')
  for mac in ${macs}; do
    echo "${mac}"
    S=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    T=$(mktemp -t "${FUNCNAME[0]}-XXXXXX") 
    echo "connect ${mac}" | bluetoothctl 2> ${S} >> ${T} 2> /dev/null
    sleep ${1:-5}
    echo "disconnect ${mac}" | bluetoothctl 2> ${S} >> ${T} 2> /dev/null
    sleep ${1:-5}
    U=$(cat ${T})
    rm -f ${T} ${S}
    hzn.log.info "MAC: ${mac}; result: ${U}"
  done
}

###
### MAIN
###

connect2macs ${*}
