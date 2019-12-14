#!/bin/bash

DEBUG=true

MAX=${1:-0}
START=${2:-1}
PAYLOAD=$(mktemp -t "${0##*/}-XXXXXX")
NODE=$(mktemp -t "${0##*/}-XXXXXX")

TIME=0
i=${START}; while [ ${i} -le ${MAX} ]; do
  SUBNET=$((i/256))
  IP=$((i%256))

  # generate serial #, MAC address, and IPv4 address
  SERIAL=$(echo "${i}" | awk '{ printf("%020d", $1) }')
  MAC=$(echo "${i}" | awk '{ x=($1 / 256); y=($1 % 256); printf("%02x:%02x:%02x:%02x", 192, 168, y, x) }')
  IP=$(echo "${i}" | awk '{ x=($1 / 256); y=($1 % 256); printf("192.168.%d.%d", x, y) }')

  REQUEST='{"product":"Raspberry Pi 3 Model B Plus Rev 1.3","serial":"'${SERIAL}'","mac":"'${MAC}'","inet":"'${IP}'"}'
  echo "${REQUEST}" | jq -c '.' > ${PAYLOAD}

  RESPONSE=$(curl -sSL -w '%{time_total}' -o ${NODE} -sSL "${HZNSETUP_ENDPOINT:-localhost:3093}" -X POST -H "Content-Type: application/json" --data-binary @"${PAYLOAD}")

  if [ ! -s "${NODE}" ]; then
    echo "*** FAILURE -- no node" &> /dev/stderr
  elif [ $(jq '.node.exchange!=null' ${NODE}) = false ]; then
    echo "*** FAILURE -- exchange create node" &> /dev/stderr
    jq '.' ${NODE}
  else
    echo "+++ SUCCESS -- node: " $(jq -c '.node' "${NODE}") &> /dev/stderr
  fi

  TIME=$(echo "${TIME} + ${RESPONSE}" | bc)
  if [ ${i} -gt ${START} ]; then
    AVERAGE=$(echo "${TIME} / (${i} - ${START})" | bc -l)
  fi
  OUTPUT='{"item":'${i}',"total":'${TIME}',"average":'${AVERAGE:-0}'}'
  echo "--- OUTPUT -- ${OUTPUT}" &> /dev/stderr
  
  i=$((i+1))
done

rm -f ${PAYLOAD} ${NODE}

echo "${OUTPUT}"
