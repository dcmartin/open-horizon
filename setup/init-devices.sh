#!/bin/bash

if [ -z ${DEBUG} ]; then DEBUG=; fi
if [ -z ${VERBOSE} ]; then VERBOSE=; fi

###
### default EXCHANGE URL
###

HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"

## check for necessary tooling
if [[ ! -e "/usr/local/bin/nmap" && ! -e "/usr/bin/nmap" ]]; then
  echo '*** ERROR $0 $$ -- No nmap(8); install using brew or apt' &> /dev/stderr
  exit 1
fi

## MACOS is strange
if [[ "$OSTYPE" == "darwin" && "$VENDOR" == "apple" ]]; then
  BASE64_ENCODE='base64'
else
  BASE64_ENCODE='base64 -w 0'
fi

###
### CONFIGURATION
###

if [ -n "${1}" ]; then
  CONFIG="${1}"
else
  if [ "${0%/*}" != "${0}" ]; then
    CONFIG="${0%/*}/horizon.json"
  else
    CONFIG="horizon.json"
  fi
fi
if [ ! -s "${CONFIG}" ]; then
  echo "Cannot find configuration file: ${CONFIG}" &> /dev/stderr
  exit 1
fi

DEFAULT_TOKEN=$(jq -r '.default.token' "${CONFIG}")
DEFAULT_MACHINE=$(jq -r '.default.machine' "${CONFIG}")

SETUP_ID=$(jq -r '.setup' "${CONFIG}")
if [ -n "${SETUP_ID}" ]; then
  HORIZON_SETUP_URL=$(jq -r '.setups[]|select(.id=="'$SETUP_ID'").url' "${CONFIG}")
  if [ -z "${HORIZON_SETUP_URL}" ]; then
    echo "*** ERROR $0 $$ -- cannot find URL for setup id ${SETUP_ID} in ${CONFIG}" &> /dev/stderr
    exit 1
  fi
else
  echo "*** ERROR $0 $$ -- no setup specified" &> /dev/stderr
  exit 1
fi

## VENDOR for auto-discovery
VENDOR_ID=$(jq -r '.vendor' "${CONFIG}")
if [ -n "${VENDOR_ID}" ]; then
  VENDOR_TAG=$(jq -r '.vendors[]|select(.id=="'"${VENDOR_ID}"'").tag' "${CONFIG}")
  if [ -z "${VENDOR_TAG}" ]; then
    echo "*** ERROR $0 $$ -- cannot find tag for vendor id ${VENDOR_ID} in configuration ${CONFIG}" &> /dev/stderr
    exit 1
  fi
else
  echo "+++ WARN $0 $$ -- no vendor specified for auto-discovery in ${CONFIG}" &> /dev/stderr
  VENDOR_TAG=
fi

# NETWORK
if [[ -n "${2}" ]]; then
  net="${2}"
else
  net="192.168.1.0/24"
fi
echo "--- INFO $0 $$ -- executing: $0 ${CONFIG} $net" &> /dev/stderr

TTL=300 # seconds
SECONDS=$(date "+%s")
DATE=$(echo $SECONDS \/ $TTL \* $TTL | bc)
TMP="/tmp/${0##*/}.$$"

# make temporary directory for working files
mkdir -p "$TMP"
if [[ ! -d "$TMP" ]]; then
  echo "FATAL: no $TMP" &> /dev/stderr
  exit 1
fi

out="${TMP%.*}.$DATE.txt"
if [[ ! -s "$out" ]]; then
  rm -f "${out%.*}".*.txt
  if [[ $(whoami) != "root" ]]; then
    echo "$(date '+%T') INFO $0 $$ -- scanning network ${net}" &> /dev/stderr
    sudo nmap -sn -T5 "$net" > "$out"
  else
    nmap -sn -T5 "$net" > "$out"
  fi
fi
if [[ ! -s "$out" ]]; then
  echo 'ERROR: no nmap(8) output for '"$net" &> /dev/stderr
  exit 1
fi

MACS=$(egrep MAC "$out" | awk '{ print $3 }' | sort | uniq)
MAC_ARRAY=($(echo ${MACS}))
MAC_COUNT=${#MAC_ARRAY[@]}
echo "$(date '+%T') INFO $0 $$ -- found ${MAC_COUNT} devices on LAN ${net}" &> /dev/stderr

# get nodes
NODES=$(jq -r '.nodes[]?.mac' "${CONFIG}")
if [ -z "${NODES}" ] || [ "${NODES}" == 'null' ]; then
  echo "+++ WARN $0 $$ -- no nodes in configuration" &> /dev/stderr
  NODE_COUNT=0
else
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: existing nodes:" $(echo ${NODES} | fmt -256) &> /dev/stderr; fi
  NODE_ARRAY=($(echo ${NODES}))
  NODE_COUNT=${#NODE_ARRAY[@]}
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found ${NODE_COUNT} nodes by MAC in configuration" &> /dev/stderr; fi
fi

# find all devices from specified vendor
if [ -n "${VENDOR_TAG}" ] && [ $(jq '.discover==true' "${CONFIG}") == 'true' ]; then
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: searching for all from ${VENDOR_TAG}" &> /dev/stderr; fi
  vmacs=$(egrep "${VENDOR_TAG}" "${out}" | awk '{ print $3 }' | sort | uniq)
fi

if [ -n "${vmacs}" ]; then
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${VENDOR_TAG} devices found:" $(echo ${vmacs} | fmt -256) &> /dev/stderr; fi
  JSON=; for vmac in ${vmacs}; do 
    FOUND=; for NODE in ${NODES}; do
      if [ "${vmac}" == "${NODE}" ]; then FOUND="true"; break; fi
    done
    if [ -z "${FOUND}" ]; then
      if [ -n "${JSON}" ]; then JSON="${JSON}"','; else JSON='['; i=$((NODE_COUNT)); fi
      i=$((i+1))
      JSON="${JSON}"'{"id":"'"${VENDOR_ID}-${i}"'","mac":"'"${vmac}"'"}'
    else
      if [ -n "${DEBUG}" ]; then echo echo "??? DEBUG: node ${vmac} in configuration ${CONFIG}" &> /dev/stderr; fi
    fi
  done
  if [ -n "${JSON}" ]; then 
    JSON="${JSON}"']'
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found" $(echo "${JSON}" | jq '.|length') "new ${VENDOR_TAG} nodes" &> /dev/stderr; fi
    jq '.nodes+='"${JSON}" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: updated configuration ${CONFIG}" &> /dev/stderr; fi
  fi
else
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: no ${VENDOR_TAG} devices found" &> /dev/stderr ; fi
fi

# update 
NODES=$(jq -r '.nodes[]?.mac' "${CONFIG}")
if [ -z "${NODES}" ]; then
  echo "+++ WARN $0 $$ -- no nodes (MACs) in configuration" &> /dev/stderr
  NODE_COUNT=0
else
  NODE_ARRAY=($(echo ${NODES}))
  NODE_COUNT=${#NODE_ARRAY[@]}
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found ${NODE_COUNT} nodes (MACs) in configuration" &> /dev/stderr; fi
fi

echo "$(date '+%T') INFO $0 $$ -- total of ${NODE_COUNT} nodes in configuration ${CONFIG}" &> /dev/stderr

###
### ITERATE OVER ALL MACS on LAN
###

for MAC in ${MACS}; do 
  # get ipaddr
  client_ipaddr=$(egrep -B 2 "$MAC" "$out" | egrep "Nmap scan" | head -1 | awk '{ print $5 }')
  # search for device by MAC
  id=$(jq -r '.nodes[]|select(.mac=="'$MAC'").id' "${CONFIG}")
  if [ -z "$id" ]; then
    if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: NOT FOUND; MAC: $MAC; IP: $client_ipaddr" &> /dev/stderr; fi
    continue
  else
    # get ip address from nmap output file
    echo '>>>' "$(date '+%T') INFO $0 $$ -- ${id}: FOUND at MAC: $MAC; IP $client_ipaddr" &> /dev/stderr
    # remove from known hosts
    if [ -s "${HOME}/.ssh/known_hosts" ]; then
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: removing $client_ipaddr from ${HOME}/.ssh/known_hosts" &> /dev/stderr; fi
      egrep -v "${client_ipaddr}" "${HOME}/.ssh/known_hosts" > $TMP/known_hosts
      mv -f $TMP/known_hosts ${HOME}/.ssh/known_hosts
    fi
  fi

  ## UPDATE CONFIGURATION
  node_state=$(jq '.nodes[]?|select(.id=="'${id}'")' "${CONFIG}" | jq '.ipv4="'"${client_ipaddr}"'"')
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: updating configuration ${CONFIG}" &> /dev/stderr; fi
  jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: searching for configuration" &> /dev/stderr; fi

  # find configuration which includes device
  conf=$(jq '.configurations[]|select(.nodes[]?.id=="'"${id}"'")' "${CONFIG}")
  if [ -z "${conf}" ] || [ "${conf}" == "null" ]; then
    echo "*** ERROR $0 $$ -- ${id}: Cannot find node configuration for device: $id" &> /dev/stderr
    continue
  else
    # identify configuration
    conf_id=$(echo "$conf" | jq -r '.id')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: found configuration $conf_id" &> /dev/stderr; fi
  fi

  # find node state (cannot fail)
  node_state=$(jq '.nodes[]|select(.id=="'$id'")' "${CONFIG}")
  if [ -z "${node_state}" ] || [ "${node_state}" == 'null' ]; then
    echo "*** ERROR ${id}: found no existing node state; continuing..." &> /dev/stderr
    continue
  fi

  ## TEST STATUS
  config_keys=$(echo "$conf" | jq '.public_key!=null and .private_key!=null')
  config_ssh=$(echo "$node_state" | jq '.ssh!=null')
  config_security=$(echo "$node_state" | jq '.ssh.device!=null')
  config_software=$(echo "$node_state" | jq '.software!=null')
  config_exchange=$(echo "$node_state" | jq '.exchange.node!=null')
  config_network=$(echo "$node_state" | jq '.network!=null')

  ## CONFIGURATION KEYS
  if [[ ${config_keys} != "true" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: configuring KEYS for $conf_id" &> /dev/stderr; fi
    # test for existing keys
    if [[ ! -s "$conf_id" && ! -s "${conf_id}.pub" ]]; then
      if [ $(jq -r '.default.keys!=null' "${CONFIG}") == "true" ]; then
        echo "+++ WARN $0 $$ -- no keys defined for configuration: $conf_id; using configured default"
        jq -r '.default.keys.private' "${CONFIG}" | base64 --decode > "${conf_id}"
        jq -r '.default.keys.public' "${CONFIG}" | base64 --decode > "${conf_id}.pub"
        chmod 400 "${conf_id}" "${conf_id}.pub"
      else
        # generate new key
        ssh-keygen -t rsa -f "$conf_id" -N "" &> /dev/null
        # test for success
        if [[ ! -s "$conf_id" || ! -s "$conf_id.pub" ]]; then
          echo "*** ERROR $0 $$ -- ${id}: failed to create key files for $conf_id" &> /dev/stderr
          exit 1
        fi
      fi
    else
      if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: ${id}: using existing keys $conf_id" &> /dev/stderr; fi
    fi
    # save into configuration
    public_key='{ "encoding": "base64", "value": "'$(${BASE64_ENCODE} "${conf_id}.pub")'" }'

    jq '(.configurations[]|select(.id=="'"$conf_id"'").public_key)|='"${public_key}" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    private_key='{ "encoding": "base64", "value": "'$(${BASE64_ENCODE} "$conf_id")'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"${private_key}" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    conf=$(jq '.configurations[]|select(.nodes[]?.id=="'$id'")' "${CONFIG}")
    # update status
    config_keys=$(echo "$conf" | jq '.public_key!=null')
  else
    if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: KEYS configured: ${config_keys}" &> /dev/stderr; fi
  fi
  # sanity
  if [[ "${config_keys}" != "true" ]]; then
    echo "FATAL: ${id}: failure to configure keys for $conf_id" &> /dev/stderr
    exit
  else
    public_key=$(echo "$conf" | jq '.public_key')
    private_key=$(echo "$conf" | jq '.private_key')
    if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: ${conf_id}: KEYS configured" &> /dev/stderr; fi
  fi

  # process public key for device
  pke=$(echo "$public_key" | jq -r '.encoding')
  if [[ -n $pke && "$pke" == "base64" ]]; then
    public_keyfile="$TMP/${conf_id}.pub"
    if [[  ! -e "$public_keyfile"  ]]; then
      echo "$public_key" | jq -r '.value' | base64 --decode > "$public_keyfile"
      chmod 400 "$public_keyfile"
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${conf_id}: found existing keyfile: $public_keyfile" &> /dev/stderr; fi
    fi
  else
    echo "FATAL: ${id}: invalid public key encoding" &> /dev/stderr
    exit 1
  fi

  # process private key for device
  pke=$(echo "$private_key" | jq -r '.encoding')
  if [[ -n $pke && "$pke" == "base64" ]]; then
    private_keyfile="$TMP/${conf_id}"
    if [[  ! -e "$private_keyfile"  ]]; then
      echo "$private_key" | jq -r '.value' | base64 --decode > "$private_keyfile"
      chmod 400 "$private_keyfile"
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${conf_id}: found existing keyfile: ${private_keyfile}" &> /dev/stderr; fi
    fi
  else
    echo "FATAL: ${id}: invalid private key encoding" &> /dev/stderr
    exit 1
  fi

  # get configuration for identified node
  node_conf=$(echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")')

  # get default username and password for distribution associated with machine assigned to node
  mid=$(echo "$node_conf" | jq -r '.machine')
  did=$(jq -r '.machines[]|select(.id=="'$mid'").distribution' "${CONFIG}") 
  dist=$(jq '.distributions[]|select(.id=="'$did'")' "${CONFIG}")
  client_username=$(echo "$dist" | jq -r '.client.username')
  client_password=$(echo "$dist" | jq -r '.client.password')
  client_sudo=$(echo "$dist" | jq '.sudo')
  client_distro=$(echo "$dist" | jq '{"id":.id}')

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: machine = $mid; distribution = $did" &> /dev/stderr; fi

  ## CONFIG SSH
  if [ "${config_ssh}" == "true" ]; then
    # test access
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: testing access with ${private_keyfile}" &> /dev/stderr; fi
    result=$(ssh -o "BatchMode=yes" -o "BatchMode yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'whoami' 2> /dev/null)
    if [[ -z "${result}" || "${result}" != "${client_username}" ]]; then
      echo "*** ERROR $0 $$ -- ${id} SSH ${client_username}$@{client_ipaddr} failed; cannot confirm identity ${client_username}; re-starting SSH configuration"
      config_ssh=false
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SSH access successful for ${client_username}; result= $result" &> /dev/stderr; fi
    fi
  fi
  if [ "${config_ssh}" != 'true' ]; then
    # edit template ssh-copy-id 
    ssh_copy_id="$TMP/ssh-copy-id.exp"
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${client_password}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      > "$ssh_copy_id"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SSH attempting ssh-copy-id ${ssh_copy_id} to ${client_ipaddr}" &> /dev/stderr; fi
    success=$(expect -f "$ssh_copy_id" 2> /dev/null | egrep "success")
    if [ "${success}" != "success"  ]; then
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id} SSH failed ssh-copy-id; checking private key: $private_keyfile" &> /dev/stderr ; fi
      result=$(ssh -o "BatchMode=yes" -o "BatchMode yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hostname 2> /dev/null')
      if [ -z "${result}" ]; then
	echo "*** ERROR $0 $$ -- ${id} SSH failed; not accessible; continuing..." &> /dev/stderr
	continue
      else
        if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: SSH hostname: ${result}" &> /dev/stderr; fi
      fi
    fi
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: SSH configured with $conf_id public key" &> /dev/stderr; fi
    ## UPDATE CONFIGURATION
    node_state=$(echo "$node_state" | jq '.ssh.id="'"${conf_id}"'"')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: updating configuration ${CONFIG}" &> /dev/stderr; fi
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    # get new status
    config_ssh=$(jq '.nodes[]|select(.id=="'$id'").ssh != null' "${CONFIG}")
  fi
  if [ "${config_ssh}" != "true" ]; then
    echo "*** ERROR $0 $$ -- ${id} SSH failed; not accessible; continuing..." &> /dev/stderr
    continue
  else
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SSH public key configured:" $(echo "$node_state" | jq -c '.ssh.id') &> /dev/stderr ; fi
  fi

  ## CONFIG SECURITY
  if [[ ${config_security} == "true" ]]; then
    # test access
    result=$(ssh -o "BatchMode=yes" -o "BatchMode yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hostname')
    if [[ -z $result || $(echo "$node_state" | jq -r '.ssh.device=="'"$result"'"') != "true" ]]; then
      echo "*** ERROR $0 $$ -- ${id} SECURITY failed; cannot confirm hostname: ${result}" $(echo "$node_state" | jq '.ssh') &> /dev/stderr
      config_security=false
    else
      echo "$(date '+%T') INFO $0 $$ -- ${id}: SECURITY configured" $(echo "$node_state" | jq -c '.ssh') &> /dev/stderr
    fi
  fi
  if [[ ${config_security} != "true" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SECURITY setting hostname and password" &> /dev/stderr ; fi
    # get node configuration specifics
    device=$(echo "$node_conf" | jq -r '.device')
    if [ -z "$device" ]; then
      echo "*** ERROR $0 $$ -- ${id}: node configuration device identifier unspecified: $node_conf" &> /dev/stderr
      continue
    fi
    token=$(echo "$node_conf" | jq -r '.token')
    if [ -z "${token}" ] || [ "${token}" == 'null' ]; then
      token=$(jq -r '.tokens[]|select(.id=="'${DEFAULT_TOKEN}'").token' "${CONFIG}")
      echo "+++ WARN : ${id} invalid token for $device; using default token: ${DEFAULT_TOKEN}" &> /dev/stderr
    fi
    # create device and token script
    config_script="$TMP/config-ssh.sh"
    cat "config-ssh.tmpl" \
      | sed 's|%%DEVICE_NAME%%|'"${device}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%DEVICE_TOKEN%%|'"${token}"'|g' \
      > "${config_script}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: copying SSH script ${config_script}" &> /dev/stderr; fi
    scp -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "${config_script}" "${client_username}@${client_ipaddr}:." &> /dev/null
    if [ "${client_sudo}" != 'silent' ]; then
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: cannot handle non-silent sudo (yet); continuing" &> /dev/stderr; fi
      continue
    fi
    cmd="sudo bash ./${config_script##*/}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: invoking ${cmd}" &> /dev/stderr; fi
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "${client_username}@${client_ipaddr}" "${cmd}")
    if [ "${result}" != "changed" ]; then
      echo "*** ERROR $0 $$ -- ${id}: SECURITY failed; result ($result) for command $cmd; continuing..." &> /dev/stderr
      continue
    fi
    ## UPDATE CONFIGURATION
    node_state=$(echo "$node_state" | jq '.ssh={"id":"'"$conf_id"'","token":"'"${token}"'","device":"'"${device}"'"}')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: updating configuration ${CONFIG}" &> /dev/stderr; fi
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    config_security=$(echo "$node_state" | jq '.ssh.device!=null')
  fi
  if [ "${config_security}" != "true" ]; then
    echo "*** ERROR $0 $$ -- ${id} SECURITY failed; consider reflashing; continuing..." &> /dev/stderr
    node_state=$(echo "$node_state" | jq -c '.ssh=null|.security=null')
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    continue
  else
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SECURITY configured:" $(echo "$node_state" | jq -c '.ssh') &> /dev/stderr ; fi
  fi

  ## COPY SOCAT
  if [ ! -z "${SOCAT_LISTENER:-}" ]; then
    for script in socat-node-id.sh node-id.sh; do
      if [ ! -s "${script}" ]; then 
	echo "*** ERROR $0 $$ -- ${id}: cannot locate ${script}" &> /dev/stderr
      else
        scp -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "${script}" "${client_username}@${client_ipaddr}:." &> /dev/null
      fi
    done
  fi

  ## CONFIG SOFTWARE
  if [ "${config_software}" == "true" ]; then
    # test access
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'command -v hzn')
    if [ -z "${result}" ] || [ "${result}" != $(echo "${node_state}" | jq -r '.software.command') ]; then
      echo "+++ WARN : ${id} SOFTWARE failed; cannot confirm command: ${result}" &> /dev/stderr
      node_state=$(echo "$node_state" | jq '.software=null')
      # update configuration file
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
      # update software configuration
      config_software=$(jq '.nodes[]?|select(.id=="'$id'").software != null' "${CONFIG}")
    else
      echo "$(date '+%T') INFO $0 $$ -- ${id}: SOFTWARE configured:" $(echo "$node_state" | jq -c '.software.command') &> /dev/stderr
    fi
  fi
  if [ "${config_software}" != "true" ]; then
    # install software
    echo "$(date '+%T') INFO $0 $$ -- ${id}: SOFTWARE installing ${HORIZON_SETUP_URL}" &> /dev/stderr
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'wget -qO - '"${HORIZON_SETUP_URL}"' | sudo bash 2> log')
    if [[ -z "${result}" ]]; then
      echo "*** ERROR $0 $$ -- ${id}: SOFTWARE failed; result = $result" &> /dev/stderr
      continue
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: installation result: $result" &> /dev/stderr; fi
    fi
    # add distribution information
    result=$(echo "$result" | jq '.distribution='"${client_distro}")
    # update node state
    node_state=$(echo "$node_state" | jq '.software='"$result")
    # update configuration file
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    # update software configuration
    config_software=$(jq '.nodes[]|select(.id=="'$id'").software != null' "${CONFIG}")
  fi
  # sanity
  if [ "${config_software}" != "true" ]; then
    echo "*** ERROR $0 $$ -- ${id}: SOFTWARE failed" &> /dev/stderr
    continue
  fi

  if [ ! -z "${SOCAT_LISTENER:-}" ]; then
    ## Start SOCAT
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'export SOCAT_LISTENER='${SOCAT_LISTENER}' && ./socat-node-id.sh')
  fi

  ## CONFIG EXCHANGE
  if [[ ${config_exchange} != "true" ]]; then
    echo "$(date '+%T') INFO $0 $$ -- ${id}: EXCHANGE configuring" &> /dev/stderr
    # get exchange
    ex_id=$(echo "$conf" | jq -r '.exchange')
    if [[ -z $ex_id || "$ex_id" == "null" ]]; then
      echo "*** ERROR $0 $$ -- ${id}: exchange not specified in configuration: $conf" &> /dev/stderr
      continue
    fi
    exchange=$(jq '.exchanges[]|select(.id=="'$ex_id'")' "${CONFIG}")
    if [[ -z "${exchange}" || "${exchange}" == null ]]; then
      echo "*** ERROR $0 $$ -- ${id}: exchange $ex_id not found in exchanges" &> /dev/stderr
      continue
    fi
    # check URL for exchange
    ex_url=$(echo "$exchange" | jq -r '.url')
    if [[ -z $ex_url || "$ex_url" == "null" ]]; then
      ex_url="$HZN_EXCHANGE_URL"
      echo "+++ WARN $0 $$ -- exchange $ex_id does not have URL specified; using default: $ex_url" &> /dev/stderr
    fi

    # update node state
    node_state=$(echo "$node_state" | jq '.exchange.id="'"$ex_id"'"|.exchange.url="'"$ex_url"'"')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "$node_state" | jq -c '.') &> /dev/stderr; fi

    # get exchange specifics
    ex_org=$(echo "$exchange" | jq -r '.org')
    ex_username=$(echo "$exchange" | jq -r '.username')
    ex_password=$(echo "$exchange" | jq -r '.password')
    ex_device=$(echo "$node_state" | jq -r '.ssh.device')
    ex_token=$(echo "$node_state" | jq -r '.ssh.token')

    # force specification of exchange URL
    cmd="sudo sed -i 's|HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${ex_url}|' /etc/default/horizon"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    cmd="sudo systemctl restart horizon || false"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    # test for failure status
    if [[ $? != 0 ]]; then
      echo "*** ERROR $0 $$ -- ${id}: EXCHANGE failed; $cmd" &> /dev/stderr
      continue
    else
      echo "$(date '+%T') INFO $0 $$ -- ${id}: EXCHANGE succeeded; $cmd" &> /dev/stderr
    fi

    # create node in exchange (always returns nothing)
    cmd="hzn exchange node create -o ${ex_org} -u ${ex_username}:${ex_password} -n ${ex_device}:${ex_token}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result=$?
    while [[ $result != 0 ]]; do
	if [ -n "${DEBUG}" ]; then echo "+++ WARN $0 $$ -- ${id}: failed command ${result}: $cmd" &> /dev/stderr; fi
        ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
        result=$?
    done

    # get exchange node information
    cmd="hzn exchange node list -o ${ex_org} -u ${ex_username}:${ex_password} ${ex_device}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/henl.json"
    result=$?
    while [[ $result != 0 || ! -s "$TMP/henl.json" ]]; do
      echo "+++ WARN $0 $$ -- ${id}: EXCHANGE retry; $cmd" &> /dev/stderr
      ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/henl.json"
      result=$?
    done
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: result $TMP/henl.json" $(jq -c '.' "$TMP/henl.json") &> /dev/stderr; fi
    # update node state
    result=$(sed 's/{}/null/g' "$TMP/henl.json" | jq '.')
    node_state=$(echo "$node_state" | jq '.exchange.node='"$result")
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "$node_state" | jq -c '.') &> /dev/stderr; fi

    # get exchange status
    cmd="hzn exchange status -o $ex_org -u ${ex_username}:${ex_password}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/hes.json"
    result=$?
    while [[ $result != 0 || ! -s "$TMP/hes.json" ]]; do
      echo "+++ WARN $0 $$ -- ${id}: EXCHANGE retry; $cmd" &> /dev/stderr
      ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/hes.json"
      result=$?
    done
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: result $TMP/hes.json" $(jq -c '.' "$TMP/hes.json") &> /dev/stderr; fi
    # update node state
    result=$(sed 's/{}/null/g' "$TMP/hes.json" | jq '.')
    node_state=$(echo "$node_state" | jq '.exchange.status='"$result")
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "$node_state" | jq -c '.') &> /dev/stderr; fi

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    config_exchange=$(jq '.nodes[]?|select(.id=="'$id'").exchange.node != null' "${CONFIG}")
  fi
  # sanity
  if [[ ${config_exchange} != "true" ]]; then
    echo "+++ WARN $0 $$ -- ${id}: EXCHANGE failed" &> /dev/stderr
    continue
  else
    echo "$(date '+%T') INFO $0 $$ -- ${id}: EXCHANGE configured:" $(echo "$node_state" | jq -c '.exchange.id') &> /dev/stderr
  fi

  ##
  ## CONFIG PATTERN (or reconfigure)
  ##

  # get pattern
  ptid=$(echo "$conf" | jq -r '.pattern?')
  if [[ -z $ptid || $ptid == 'null' ]]; then
    echo "*** ERROR $0 $$ -- ${id}: pattern not specified in configuration: $conf" &> /dev/stderr
    continue
  else
    echo "$(date '+%T') INFO $0 $$ -- ${id}: PATTERN: ${ptid}" &> /dev/stderr
  fi
  pattern=$(jq '.patterns[]|select(.id=="'$ptid'")' "${CONFIG}")
  if [[ -z "${pattern}" || "${pattern}" == "null" ]]; then
    echo "*** ERROR $0 $$ -- ${id}: pattern $ptid not found in patterns" &> /dev/stderr
    continue
  else
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: pattern found: ${pattern}" &> /dev/stderr; fi
  fi

  # pattern for registration
  pt_name=$(echo "$pattern" | jq -r '.name')
  pt_org=$(echo "$pattern" | jq -r '.org')
  pt_url=$(echo "$pattern" | jq -r '.url')
  pt_vars=$(echo "$conf" | jq '.variables')
  
  # get node specifics
  ex_id=$(echo "$node_state" | jq -r '.exchange.id')
  ex_device=$(echo "$node_state" | jq -r '.ssh.device')
  ex_token=$(echo "$node_state" | jq -r '.ssh.token')
  ex_org=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").org' "${CONFIG}")
  ex_username=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").username' "${CONFIG}")
  ex_password=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").password' "${CONFIG}")

  # get node status
  cmd='hzn node list'
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
  result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.')
  if [ -z "${result}" ]; then
    echo "*** ERROR $0 $$ -- remote command $cmd returned zero results; continuing..." &> /dev/stderr
    continue
  else
    node_state=$(echo "$node_state" | jq '.node='"$result")
  fi

  # test if node is configured with pattern
  node_id=$(echo "$node_state" | jq -r '.node.id')
  node_status=$(echo "$node_state" | jq -r '.node.configstate.state')
  node_pattern=$(echo "$node_state" | jq -r '.node.pattern')

  # unregister node iff
  if [[ ${node_id} == ${ex_device} && $node_pattern == ${pt_org}/${pt_name} && ( $node_status == "configured" ) ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: node ${node_id} is ${node_status} with pattern ${node_pattern}" &> /dev/stderr; fi
  elif [[ $node_status == "unconfiguring" ]]; then
    echo "*** ERROR $0 $$ -- ${id}: node ${node_id} aka ${ex_device} is unconfiguring; consider reflashing or remove, purge, update, prune, and reboot" &> /dev/stderr
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    continue
  elif [[ ${node_id} != ${ex_device} || $node_status != "unconfigured" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: unregistering node ${node_id}" &> /dev/stderr ; fi
    # unregister client
    cmd='hzn unregister -f'
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"

    # POLL client for node list information; wait until device identifier matches requested
    cmd='hzn node list'
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
    iteration=1; while [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="unconfigured"') != 'true' ]; do
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on unregistration [10]; iteration ${iteration}; result:" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
      iteration=$((iteration+1))
      if [ ${iteration} -le 10 ]; then 
        if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on unregistration [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
        sleep 10
      else
        if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: stopped waiting on unregistration at iteration ${iteration}; result:" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
        result=
        break
      fi
      result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
    done
    if [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="unconfigured"') == false ]; then
      echo "*** ERROR $0 $$ -- ${id}: command failed: $cmd; iteration ${iteration}; result:" $(echo "${result}" | jq -c '.') &> /dev/stderr
      continue
    fi
    node_state=$(echo "$node_state" | jq '.node='"$result")
  fi

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
    scp -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "${input}" "${client_username}@${client_ipaddr}:." &> /dev/null
    # perform registration
    cmd="hzn register ${ex_org} -u ${ex_username}:${ex_password} ${pt_org}/${pt_name} -f ${input##*/} -n ${ex_device}:${ex_token}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: registering with command: $cmd" &> /dev/stderr; fi
    #result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "${cmd} &> /dev/null")
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "${cmd}")
  fi

  # POLL client for node list information; wait for configured state
  cmd="hzn node list"
  result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  iteration=1; while [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="configured"') != 'true' ]; do
    iteration=$((iteration+1))
    if [ ${iteration} -le 10 ]; then
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on configuration [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
      sleep 10
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: stopped waiting on unregistration at iteration ${iteration}; result:" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
      result=
      break
    fi
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  done
  if [ -z "${result}" ] || [ "${result}" == "null" ]; then
    echo "*** ERROR $0 $$ -- ${id}: command $cmd failed; continuing..." &> /dev/stderr
    continue
  fi
  node_state=$(echo "$node_state" | jq '.node='"$result")
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node is configured" &> /dev/stderr; fi

  # POLL client for agreementlist information; wait until agreement exists
  cmd="hzn agreement list"
  result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  iteration=1
  while [ -z "${result}" ] || [ $(echo "$result" | jq '.==[]') == "true" ]; do
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on agreement [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
    sleep 10
    result=$(ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
    iteration=$((iteration+1))
    if [ ${iteration} -ge 10 ]; then
      break
    fi
  done
  if [ -z "${result}" ] || [ $(echo "$result" | jq '.==[]') == "true" ]; then
    echo "*** ERROR $0 $$ -- ${id}: agreement never established; consider re-flashing" &> /dev/stderr
    ################# UPDATE CONFIGURATION #######################
    continue
  fi
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: agreement complete:" $(echo "${result}" | jq -c '.') &> /dev/stderr; fi
  node_state=$(echo "$node_state" | jq '.pattern='"$result")

  # UPDATE CONFIGURATION
  jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"

  ## DONE w/ PATTERN
  echo "$(date '+%T') INFO $0 $$ -- ${id}: PATTERN configured" $(echo "$node_state" | jq -c '.pattern[]?.workload_to_run.url') &> /dev/stderr

  ##
  ## CONFIG NETWORK
  ##

  if [[ ${config_network} != "true" ]]; then
    echo "$(date '+%T') INFO $0 $$ -- ${id}: configuring NETWORK" &> /dev/stderr
    # get network
    nwid=$(echo "$conf" | jq -r '.network?')
    if [[ -z $nwid || $nwid == 'null' ]]; then
      echo "*** ERROR $0 $$ -- ${id}: network not specified in configuration: $conf" &> /dev/stderr
      continue
    fi
    network=$(jq '.networks[]|select(.id=="'$nwid'")' "${CONFIG}")
    if [[ -z "${network}" || "${network}" == "null" ]]; then
      echo "*** ERROR $0 $$ -- ${id}: network $nwid not found in network" &> /dev/stderr
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
    scp -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "${config_script}" "${client_username}@${client_ipaddr}:." &> /dev/null
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: invoking script ${config_script##*/}" &> /dev/stderr; fi
    cmd='sudo mv -f '"${config_script##*/}"' /etc/wpa_supplicant/wpa_supplicant.conf'
    ssh -o "BatchMode=yes" -o "CheckHostIP=no" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result='{ "ssid": "'"${nw_ssid}"'","password":"'"${nw_password}"'"}'
    node_state=$(echo "$node_state" | jq '.network='"$result")

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${CONFIG}" > "$TMP/${CONFIG##*/}"; mv -f "$TMP/${CONFIG##*/}" "${CONFIG}"
    config_network=$(jq '.nodes[]|select(.id=="'$id'").network != null' "${CONFIG}")
  fi
  # sanity
  if [[ ${config_network} != "true" ]]; then
    echo "+++ WARN $0 $$ -- ${id}: NETWORK failed" &> /dev/stderr
    continue
  else
    echo "$(date '+%T') INFO $0 $$ -- ${id}: NETWORK configured" $(echo "$node_state" | jq -c '.network') &> /dev/stderr
  fi

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "${node_state}" | jq -c '.') &> /dev/stderr; fi

done

echo $(jq -c '[.nodes[]?|{"id":.node.id,"ipv4":.ipv4,"mac":.mac,"exchange":.exchange?.id,"pattern":.pattern[]?.workload_to_run.url}]' "${CONFIG}")

if [ -z "${DEBUG}" ]; then rm -fr "$TMP"; fi
exit 0
