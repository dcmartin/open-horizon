#!/bin/bash

# test if ready
if [ -z "$(command -v hzn)" ]; then
  echo "Install bluehorizon horizon horizon-cli"
  exit 1
fi

volumes="consul-config consul-data db-data log-data"
echo -n "Creating docker volumes:"
for volume in ${volumes}; do
  echo -n " $(docker volume create ${volume})"
done
echo "; done"

# do environment
export HZN_EXCHANGE_APIKEY=${HZN_EXCHANGE_APIKEY:-$(jq -r '.horizon.apikey' config.json 2> /dev/null || echo "UNSPECIFIED")}
if [ "${HZN_EXCHANGE_APIKEY}" = 'UNSPECIFIED' ]; then
  echo "Horizon exchange API key not specified; set HZN_EXCHANGE_APIKEY environment variable"
  exit 1
fi
export HZN_ORG_ID=${HZN_ORG_ID:-"$(whoami)@$(hostname -f)"}
export HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL:-"https://alpha.edge-fabric.com/v1"}

# do keys
if [ ! -s ${HZN_ORG_ID}.pem ] || [ ! -s ${HZN_ORG_ID}.key ]; then
  rm -f ${HZN_ORG_ID}.pem ${HZN_ORG_ID}.key
  hzn key create $(whoami) $(hostname) -d .
  mv -f *.pem ${HZN_ORG_ID}.pem
  mv -f *.key ${HZN_ORG_ID}.key
fi
export PRIVATE_KEY_FILE=${HZN_ORG_ID}.key
export PUBLIC_KEY_FILE=${HZN_ORG_ID}.pem

# publish service
hzn exchange service publish -I -O -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f service.json -o ${HZN_ORG_ID} -u ${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY} &> service.out && echo "Published service" || echo "Failed to publish service" $(cat service.out)

# Create a `pattern.json` file that contains the `edgex` service as published, for example:
cat > pattern.json << EOF
{
  "label": "edgex",
  "description": "edgex foundry as a pattern",
  "services": [
    { "serviceUrl": "com.github.dcmartin.open-horizon.edgex", "serviceOrgid": "${HZN_ORG_ID}", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1" } ] }
  ]
}
EOF

# Publish the _pattern_, for example:
hzn exchange pattern publish -o "${HZN_ORG_ID}" -u "${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -f pattern.json -p "edgex" -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} &> pattern.out && echo "Published pattern" || echo "Failed to publish pattern" $(cat pattern.out)

# create userinput
cat > useruserinput.json << EOF
{
  "global": [],
  "services": [
    {
      "org": "${HZN_ORG_ID}",
      "url": "com.github.dcmartin.open-horizon.edgex",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": {
        "EXPORT_DISTRO_CLIENT_HOST": "export-client",
        "EXPORT_DISTRO_DATA_HOST": "edgex-core-data",
        "EXPORT_DISTRO_CONSUL_HOST": "edgex-config-seed",
        "EXPORT_DISTRO_MQTTS_CERT_FILE": "none",
        "EXPORT_DISTRO_MQTTS_KEY_FILE": "none",
        "LOGTO": "",
        "LOG_LEVEL": "info"
      }
    }
  ]
}
EOF

# Stop and Start the Open Horizon container on the localhost, for example:
if [ $(uname) = 'Darwin' ]; then
  if [ "$(docker ps --format '{{.Names}}' | egrep '^horizon1')" != 'horizon1' ]; then
    horizon-container start &> /dev/null && echo "Started horizon container"
  else
    echo "Horizon container running"
  fi 
fi

# Create a `userinput.json` file from the `userinput.json.tmpl` file substituting the environment variables, for example:
envsubst < userinput.json.tmpl > userinput.json && echo "Created userinput.json $(jq -c . userinput.json)" || echo "Failed to create userinput.json"

# give it a name
export NODE_NAME="edgex-$(hostname)" && echo "Set node name to ${NODE_NAME}"
# Create a password for the device, for example:
export NODE_TOKEN="whocares" && echo "Set node token to ${NODE_TOKEN}"

# Create a `node.json` file from the `node.json.tmpl` file substituting the environment variables, for example:
envsubst < node.json.tmpl > node.json && echo "Created node.json: $(jq -c . node.json)" || echo "Failed to create node.json"

# loop trying to register
wait=15; while true; do
  # get current state
  state=$(hzn node list | jq -r '.configstate.state')
  if [ "${state:-}" != 'unconfigured' ]; then
    echo "Unregistering from state: ${state}"
    hzn unregister -fr &> unregister.out && echo "Unregistered ${machine}" || echo "Failed to unregister" $(cat unregister.out)
    # get new state
    state=$(hzn node list | jq -r '.configstate.state')
    # wait for state
    while [ "${state:-}" != 'unconfigured' ]; do
      echo -n "Still ${state}; waiting (5) ..."; sleep 5; echo " done"
      state=$(hzn node list | jq -r '.configstate.state')
    done
  fi
  echo "${NODE_NAME} state: ${state}"

  # update device
  if [ "${update_device:-true}" = true ]; then
    # update the device
    echo "Updating ${NODE_NAME}: " $(jq -c '.' node.json)
    result=$(curl -sL -H 'Content-Type: application/json' -X PUT "${HZN_EXCHANGE_URL}/orgs/${HZN_ORG_ID}/nodes/${NODE_NAME}" -d @node.json -u ${HZN_ORG_ID}/${HZN_ORG_ID}:${HZN_EXCHANGE_APIKEY})
    echo "Server response: " $(echo "${result:-null}" | jq -c '.')
    # wait for update
    result=
    while [ -z "${result-}" ]; do
      result=$(curl -sL "${HZN_EXCHANGE_URL}/orgs/${HZN_ORG_ID}/nodes/${NODE_NAME}" -u ${HZN_ORG_ID}/${HZN_ORG_ID}:${HZN_EXCHANGE_APIKEY})
      if [ -z "${result:-}" ]; then echo -n "Waiting (5) ..."; sleep 5; echo " done"; continue; fi
      break
    done
    echo "Update complete ${NODE_NAME}: " $(echo "${result:-null}" | jq -c '.')
  fi

  echo -n "Waiting (${wait}) ..."; sleep ${wait}; echo " done"

  # Register the device for the `edgex` pattern, for example:
  hzn register -v "${HZN_ORG_ID}" "edgex" -u "${HZN_USER_ID:-iamapikey}:${HZN_EXCHANGE_APIKEY}" -f userinput.json -n "${NODE_NAME}" &> register.out && echo "Registered ${machine} for pattern" || echo "Failed to register ${machine}" $(cat register.out | sed 's/\[verbose\]/\n[verbose]/g')
  state=$(hzn node list 2> /dev/null)
  if [ $(echo "${state}" | jq '.configstate.state=="configured"') = 'true' ]; then
    echo "Registered" $(echo "${state}" | jq '.')
    break
  fi
  wait=$((wait+5))
done

# wait for update
result=
while [ -z "${result-}" ]; do
  result=$(curl -sL "${HZN_EXCHANGE_URL}/orgs/${HZN_ORG_ID}/nodes/${NODE_NAME}/status" -u ${HZN_ORG_ID}/${HZN_ORG_ID}:${HZN_EXCHANGE_APIKEY})
  if [ -z "${result:-}" ]; then echo -n "Waiting (5) ..."; sleep 5; echo " done"; continue; fi
  break
done
echo "${result:-null}" | jq


# Wait for device to reach agreement and beginning running containers
echo "Watching ..."
before=$(date +%s)
while true; do 
  event=$(hzn eventlog list -a | jq -r '.[-1]' 2> /dev/null)
  when=$(echo "${event}" | awk -F": " '{ print $1 }')
  if [ "${when}" != "${prior:-}" ]; then
    what=$(echo "${event}" | sed 's/.*:   //')
    echo "$(($(date +%s)-before)): ${what}"
    if [ $(echo "${what}" | grep 'running' &> /dev/null && echo 'true' || echo 'false') = 'true' ]; then break; fi
    prior=${when}
  fi
  sleep 1
done
echo "${NODE_NAME}: up and running"

# list containers
docker ps

# Check for "ping" from each service port, for example:
machine="localhost"
ports="48060 48061 48070 48071 48075 48080 48081 48082 48085 49990"
for port in ${ports}; do pong=$(curl -sSL http://${machine}:${port}/api/v1/ping) && echo "port: $port; reply: ${pong}"; done
# When the device becomes a `"configured"` node, running all containers, enquire through the Consul UI, for example:
curl -sSL http://localhost:4000
