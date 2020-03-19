#!/bin/bash

# find all nodes in exchange
url="localhost:3094/cgi-bin/nodes"
NODES=$(curl -sSL ${url})

# find patterns
if [ ! -z "${1:-}" ]; then
  pattern="${1}"
  PATTERNS=$(echo "${NODES}" | jq -r '[.nodes[]|select(.id|contains("'${pattern}'")).pattern]|sort|unique[]')
else
  # get all patterns registered to nodes
  PATTERNS=$(echo "${NODES}" | jq -r '[.nodes[].pattern]|sort|unique[]')
fi

if [ -z "${PATTERNS:-}" ] || [ "${PATTERNS:-}" = 'null' ]; then
  echo '{"patterns":null}'
  exit
fi

echo '{"patterns":['
i=0; for P in ${PATTERNS}; do 

  if [ ${i} -gt 0 ]; then echo ','; fi
  echo '{"pattern":'
  p=$(curl -sSL localhost:3094/cgi-bin/patterns | jq '.patterns[]|select(.id=="'${P}'")')
  if [ ! -z "${p:-}" ]; then
    echo "${p}"
  else
    echo '"'${P}'"'
  fi

  nodes=$(echo "${NODES}" | jq '.nodes[]|select(.pattern=="'${P}'")')
  echo ',"nodes":['
  if [ ! -z  "${nodes:-}" ] && [ "${nodes:-}" != 'null' ]; then
    j=0; for nid in $(echo "${nodes}" | jq -r '.id'); do
      ips='null'
      timestamp=""
      name="notfound"

      # start record
      if [ ${j} -gt 0 ]; then echo ','; fi
      echo '{"id":"'${nid}'"'
      # find specific node
      n=$(echo "${nodes}" | jq '.|select(.id=="'${nid}'")')
      # test if found
      if [ ! -z  "${n:-}" ] && [ "${n:-}" != 'null' ]; then
        summary=null

	# get node lastHeartbeat
	lastHeartbeat=$(echo "${n}" | jq -r '.lastHeartbeat|split("Z")[0]|split(".")[0]|strptime("%Y-%m-%dT%H:%M:%S")|strftime("%FT%TZ")')
	# output lastHeartbeat into record
        echo ',"lastHeartbeat":"'${lastHeartbeat:-}'"'

	# get node name
	name=$(echo "${n}" | jq -r '.name')
	# output name into record
        echo ',"name":"'${name}'"'

	# lookup summary for node from `startup` service
	summary=$(curl -sSL "localhost:3094/cgi-bin/summary?node=${name}")
	# test summary
	if [ ! -z "${summary:-}" ] && [ "${summary:-}" != 'null' ]; then
	  if [ $(echo "${summary}" | jq '.error!=null') != true ]; then
	    # {"id":"startup-beta-test-vmc12","timestamp":"2019-06-18T16:01:53Z","count":7,"ips":["127.0.0.1","10.209.181.12","52.117.45.20","172.17.0.1"],"download":1987816615.0090988,"percent":0,"product":"HVM domU","date":1560374995,"containers":21,"last":1560374995,"first":1560374995,"average":3}
	    timestamp=$(echo "${summary}" | jq -r '.timestamp')
	    ips=$(echo "${summary}" | jq '.ips')
            echo ',"summary":'"${summary}"
	  else
            echo ',"error":"'$(echo "${summary}" | jq -r '.error')'","summary":null'
	  fi
	else
          echo ',"summary":null'
	fi
      else
	echo "ERROR: no node: ${nid}" &> /dev/stderr
      fi
      echo '}'
      j=$((j+1))
    done
  else
    echo "ERROR: no nodes: ${url}" &> /dev/stderr
  fi
  echo ']}'
  i=$((i+1))
done
echo ']}'
