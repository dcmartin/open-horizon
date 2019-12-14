#!/bin/bash

DEBUG=

## temporary directory
TMP="/tmp/${0##*/}.$$"
# make temporary directory for working files
mkdir -p "$TMP"
if [ ! -d "$TMP" ]; then
  echo "FATAL: no $TMP" &> /dev/stderr
  exit 1
fi

## pre-requisite commands
for cmd in hzn nmap; do
  if [ -z $(command -v ${cmd}) ]; then
    echo "*** ERROR: command ${cmd} missing; please install" 2> /dev/stderr
    exit 1
  fi
done

## default EXCHANGE URL
HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"

## configuration file
if [ ! -z "${1}" ]; then
  CONFIG="${1}"
else
  if [ "${0%/*}" != "${0}" ]; then
    CONFIG="${0%/*}/horizon.json"
  else
    CONFIG="horizon.json"
  fi
fi
if [ ! -s "${CONFIG}" ]; then
  echo "*** ERROR: Cannot find configuration file: ${CONFIG}; run mkconfig.sh" &> /dev/stderr
  exit 1
fi

# node
if [ ! -z "${2}" ]; then
  node_id="${2}"
else
  node_id=$(hostname)
fi

node=$(jq -r '.nodes[]|select(.id=="'${node_id}'")' ${CONFIG})
if [ -z "${node}" ] || [ "${node}" == 'null' ]; then
  ipv4=$(hostname -I | awk '{ print $1 }')
  mac=$(ifconfig -a | egrep -A2 $(hostname -I | awk '{ print $1 }') | tail -1 | awk '{ print $2 }')
  node=$(jq -r '.nodes[]|select(.mac=="'$mac'")' "${CONFIG}")
  if [ -z "${node}" ] || [ "${node}" == 'null' ]; then
    echo "+++ WARN: Cannot find node : ${node_id}; creating" &> /dev/stderr
    node='{"id":"'${node_id}'","ipv4":"'$ipv4'","mac":"'$mac'"}'
  fi
fi
if [ -z "${node_mac}" ]; then
  echo "ERROR: no MAC address for node: ${node_id}" &> /dev/stderr
  exit 1
else
  node_state=$(jq -r '.nodes[]|select(.mac=="'$MAC'")' "${CONFIG}")

fi

# configuration
if [ ! -z "${3}" ]; then
  conf_id="${3}"
else
  conf_id=$(jq -r '.configurations|first|.id' "${CONFIG}"
  echo "+++ WARN: using default configuration ${conf}" &> /dev/stderr
fi 

# get nodes
NODES=$(jq -r '.nodes[]?.mac' "${CONFIG}")
if [ -z "${NODES}" ] || [ "${NODES}" == 'null' ]; then
  echo "+++ WARN: no nodes in configuration" &> /dev/stderr
  NODE_COUNT=0
else
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: existing nodes:" $(echo ${NODES} | fmt -256) &> /dev/stderr; fi
  NODE_ARRAY=($(echo ${NODES}))
  NODE_COUNT=${#NODE_ARRAY[@]}
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found ${NODE_COUNT} nodes by MAC in configuration" &> /dev/stderr; fi
fi


## NODE

  client_ipaddr=$(egrep -B 2 "$MAC" "$out" | egrep "Nmap scan" | head -1 | awk '{ print $5 }')
  # search for device by MAC
  id=$(jq -r '.nodes[]|select(.mac=="'$MAC'").id' "${CONFIG}")

  node_state=$(jq '.nodes[]?|select(.id=="'${id}'")' "${CONFIG}" | jq '.ipv4="'"${client_ipaddr}"'"')

## CONFIGURATION

echo "$(date '+%T') INFO: ${id}: checking CONFIGURATION ${conf_id}" &> /dev/stderr

conf=$(jq '.configurations[]|select(.id=="'${conf_id}'")')
if [[ -z "${conf}" || "${conf}" == null ]]; then
  echo "*** ERROR: ${id}: $conf_id not found in configurations" &> /dev/stderr
  exit 1
fi

echo "$(date '+%T') INFO: ${id}: checking EXCHANGE" &> /dev/stderr

# get exchange
ex_id=$(echo "$conf" | jq -r '.exchange')
if [[ -z $ex_id || "$ex_id" == "null" ]]; then
  echo "*** ERROR: ${id}: exchange not specified in configuration: $conf" &> /dev/stderr
  exit 1
fi
exchange=$(jq '.exchanges[]|select(.id=="'$ex_id'")' "${CONFIG}")
if [[ -z "${exchange}" || "${exchange}" == null ]]; then
  echo "*** ERROR: ${id}: exchange $ex_id not found in exchanges" &> /dev/stderr
  exit 1
fi
# check URL for exchange
ex_url=$(echo "$exchange" | jq -r '.url')
if [[ -z $ex_url || "$ex_url" == "null" ]]; then
  ex_url="$HZN_EXCHANGE_URL"
  echo "+++ WARN: exchange $ex_id does not have URL specified; using default: $ex_url" &> /dev/stderr
fi

# get exchange specifics
ex_org=$(echo "$exchange" | jq -r '.org')
ex_username=$(echo "$exchange" | jq -r '.username')
ex_password=$(echo "$exchange" | jq -r '.password')

echo "$(date '+%T') INFO: ${id}: PATTERN configuring" &> /dev/stderr
# get pattern
ptid=$(echo "$conf" | jq -r '.pattern?')
if [[ -z $ptid || $ptid == 'null' ]]; then
    echo "*** ERROR: ${id}: pattern not specified in configuration: $conf" &> /dev/stderr
    exit 1
fi
pattern=$(jq '.patterns[]|select(.id=="'$ptid'")' "${CONFIG}")
if [[ -z "${pattern}" || "${pattern}" == "null" ]]; then
    echo "*** ERROR: ${id}: pattern $ptid not found in patterns" &> /dev/stderr
    exit 1
fi

# pattern for registration
pt_name=$(echo "$pattern" | jq -r '.name')
pt_org=$(echo "$pattern" | jq -r '.org')
pt_url=$(echo "$pattern" | jq -r '.url')
pt_vars=$(echo "$conf" | jq '.variables')
  
  ex_device=$(echo "$node_state" | jq -r '.ssh.device')
  ex_token=$(echo "$node_state" | jq -r '.ssh.token')


# unregister node iff
if [[ ${node_id} == ${ex_device} && $node_pattern == ${pt_org}/${pt_name} && ( $node_status == "configured" || $node_status == "configuring" ) ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: node ${node_id} is ${node_status} with pattern ${node_pattern}" &> /dev/stderr; fi
elif [[ $node_status == "unconfiguring" ]]; then
    echo "*** ERROR: ${id}: node ${node_id} aka ${ex_device} is unconfiguring; consider reflashing or remove, purge, update, prune, and reboot" &> /dev/stderr
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    exit 1
elif [[ ${node_id} != ${ex_device} || $node_status != "unconfigured" ]]; then
    hzn unregister -f
fi

# POLL client for node list information; wait until device identifier matches requested
result=$(hzn node list)
iteration=1; while [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="unconfigured"') == false ]; do
    iteration=$((iteration+1))
    if [ ${iteration} -le 5 ]; then 
        sleep 10
    else
        break
    fi
    result=$(hzn node list)
done
if [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="unconfigured"') == false ]; then
    echo "*** ERROR: ${id}: command failed: $cmd; iteration ${iteration}; result:" $(echo "${result}" | jq -c '.') &> /dev/stderr
    exit 1
fi

#
node_state=$(echo "$node_state" | jq '.node='"$result")

  # register node iff
  if [[ $(echo "$node_state" | jq '.node.configstate.state=="unconfigured"') == "true" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: registering node" $(echo "$node_state" | jq -c '.') &> /dev/stderr ; fi
    # create pattern registration file
    input="$TMP/input.json"
    echo '{"services": [{"org": "'"${pt_org}"'","url": "'"${pt_url}"'","versionRange": "[0.0.0,INFINITY)","variables": {' > "${input}"
    # process all variables 
    pvs=$(echo "${pt_vars}" | jq -r '.[].key')
    i=0; for pv in ${pvs}; do
      value=$(echo "${pt_vars}" | jq -r '.[]|select(.key=="'"${pv}"'").value')
      if [[ $i > 0 ]]; then echo ',' >> "${input}"; fi
      echo '"'"${pv}"'":"'"${value}"'"' >> "${input}"
      i=$((i+1))
    done
    echo '}}]}' >> "${input}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node ${ex_device}; pattern ${pt_org}/${pt_name}; input" $(cat "${input}") &> /dev/stderr; fi

    # copy pattern registration file to client
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${input}" "${client_username}@${client_ipaddr}:." &> /dev/null
    # perform registration
    cmd="hzn register ${ex_org} -u ${ex_username}:${ex_password} ${pt_org}/${pt_name} -f ${input##*/} -n ${ex_device}:${ex_token}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: registering with command: $cmd" &> /dev/stderr; fi
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "${cmd} &> /dev/null")
  fi

  # POLL client for node list information; wait for configured state
  cmd="hzn node list"
  result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  while [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="configured"') == false ]; do
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on configuration [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
    sleep 10
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  done
  if [ -z "${result}" ] || [ "${results}" == "null" ]; then
    echo "*** ERROR: ${id}: command $cmd failed; continuing..." &> /dev/stderr
    continue
  fi
  node_state=$(echo "$node_state" | jq '.node='"$result")
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node is configured" &> /dev/stderr; fi

  # POLL client for agreementlist information; wait until agreement exists
  cmd="hzn agreement list"
  result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  i=1
  while [ -z "${result}" ] || [ $(echo "$result" | jq '.==[]') == "true" ]; do
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on agreement [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
    sleep 10
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
    i=$((i+1))
    if [[ i > 10 ]]; then
      break
    fi
  done
  if [[ i > 10 ]]; then
    echo "*** ERROR: ${id}: agreement never established; consider re-flashing" &> /dev/stderr
    ################# UPDATE CONFIGURATION #######################
    continue
  fi
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: agreement complete:" $(echo "${result}" | jq -c '.') &> /dev/stderr; fi
  node_state=$(echo "$node_state" | jq '.pattern='"$result")

  # UPDATE CONFIGURATION
  jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"

  ## DONE w/ PATTERN
  echo "$(date '+%T') INFO: ${id}: PATTERN configured" $(echo "$node_state" | jq -c '.pattern[]?.workload_to_run.url') &> /dev/stderr

  ##
  ## CONFIG NETWORK
  ##

  if [[ ${config_network} != "true" ]]; then
    echo "$(date '+%T') INFO: ${id}: configuring NETWORK" &> /dev/stderr
    # get network
    nwid=$(echo "$conf" | jq -r '.network?')
    if [[ -z $nwid || $nwid == 'null' ]]; then
      echo "*** ERROR: ${id}: network not specified in configuration: $conf" &> /dev/stderr
      continue
    fi
    network=$(jq '.networks[]|select(.id=="'$nwid'")' "${CONFIG}")
    if [[ -z "${network}" || "${network}" == "null" ]]; then
      echo "*** ERROR: ${id}: network $nwid not found in network" &> /dev/stderr
      continue
    fi
    # network for deployment
    nw_id=$(echo "$network" | jq -r '.id')
    nw_dhcp=$(echo "$network" | jq -r '.dhcp')
    nw_ssid=$(echo "$network" | jq -r '.ssid')
    nw_password=$(echo "$network" | jq -r '.password')
    # create wpa_supplicant.conf
    config_script="$TMP/wpa_supplicant.conf"
    cat "wpa_supplicant.tmpl" \
      | sed 's|%%NETWORK_SSID%%|'"${nw_ssid}"'|g' \
      | sed 's|%%NETWORK_PASSWORD%%|'"${nw_password}"'|g' \
      > "${config_script}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: copying script ${config_script}" &> /dev/stderr; fi
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${config_script}" "${client_username}@${client_ipaddr}:." &> /dev/null
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: invoking script ${config_script##*/}" &> /dev/stderr; fi
    cmd='sudo mv -f '"${config_script##*/}"' /etc/wpa_supplicant/wpa_supplicant.conf'
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result='{ "ssid": "'"${nw_ssid}"'","password":"'"${nw_password}"'"}'
    node_state=$(echo "$node_state" | jq '.network='"$result")

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    config_network=$(jq '.nodes[]|select(.id=="'$id'").network != null' "${CONFIG}")
  fi
  # sanity
  if [[ ${config_network} != "true" ]]; then
    echo "+++ WARN: ${id}: NETWORK failed" &> /dev/stderr
    continue
  else
    echo "$(date '+%T') INFO: ${id}: NETWORK configured" $(echo "$node_state" | jq -c '.network') &> /dev/stderr
  fi

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "${node_state}" | jq -c '.') &> /dev/stderr; fi

done

echo $(jq -c '[.nodes[]?|{"id":.node.id,"ipv4":.ipv4,"mac":.mac,"exchange":.exchange?.id,"pattern":.pattern[]?.workload_to_run.url}]' "${CONFIG}")

if [ -z "${DEBUG}" ]; then rm -fr "$TMP"; fi
exit 0
