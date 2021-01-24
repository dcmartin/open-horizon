#!/usr/bin/env bash

source /usr/bin/hzn-tools.sh

##
## functions
##

## lookup pattern by name
hzn_setup_pattern_lookup()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  echo $(curl -fsSL -u "${HZN_SETUP_ORG}/${HZN_USER_ID:-iamapikey}:${HZN_SETUP_APIKEY}" "${HZN_SETUP_EXCHANGE%/}/orgs/${HZN_SETUP_ORG}/patterns" | jq '[.patterns|to_entries[]|.value.id=.key|.value][]|select(.id=="'${1}'")' 2> /dev/null)
}

## lookup service by identifier
hzn_setup_service_lookup()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  echo $(curl -fsSL -u "${HZN_SETUP_ORG}/${HZN_USER_ID:-iamapikey}:${HZN_SETUP_APIKEY}" "${HZN_SETUP_EXCHANGE%/}/orgs/${HZN_SETUP_ORG}/services" | jq '[.services|to_entries[]|.value.id=.key|.value][]|select(.id=="'${1}'")' 2> /dev/null)
}

## build userinput JSON based on pattern
hzn_setup_userinput()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  pattern=$(hzn_setup_pattern_lookup "${1}")
  surls=
  sids=($(echo "${pattern:-null}" | jq -j '.services[]|.serviceOrgid,"/",.serviceUrl,"_",(.serviceVersions|first|.version),"_",.serviceArch,"\n"'))
  output='{"global":[],"services":['

  i=0; for sid in ${sids}; do 
    hzn::log.debug "looking up ${sid}"
    if [ ${i} -gt 0 ]; then output="${output}"','; fi
    svc=$(hzn_setup_service_lookup ${sid})
    url=$(echo "${svc:-null}" | jq -r '.url')
    if [ -z "${surls}" ]; then 
      surls="${url}"
    else 
      found=
      for surl in ${surls}; do
        if [ "${surl}" != "${url}" ]; then 
          found="${url}"
          surls="${surls} ${found}"
          break
        fi
      done
    fi
    if [ -z "${found:-}" ]; then
      # this is a hack
      org="${sid%%/*}"
      output="${output}"'{"org":"'${org:-none}'", "url": "'${url:-none}'", "versionRange": "[0.0.0,INFINITY)", "variables": {'
      j=0; for var in $(echo "${svc:-null}" | jq -r '.userInput[].name'); do
	if [ ${j} -gt 0 ]; then output="${output}"','; fi
	ui=$(echo "${svc:-null}" | jq '.userInput[]|select(.name=="'${var}'")')
	var_type=$(echo "${ui}" | jq -r '.type')
	var_default=$(echo "${ui}" | jq -r '.defaultValue')
	# var_value=$(hzn_setup_userinput_lookup ${sids} ${var})
	output="${output}"'"'${var}'":'
	case ${var_type} in
	  int|boolean|float)
	    output="${output}"${var_value:-${var_default}}
	    ;;
	  string|*)
	    output="${output}"'"'${var_value:-${var_default}}'"'
	    ;;
	esac
	j=$((j+1))
      done
    else
      hzn::log.debug "already found: ${found}"
    fi
    i=$((i+1))
    output="${output}"'}}'
  done
  output="${output}"']}'
  echo "${output:-null}"
}

hzn_setup_exchange_nodes()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  ALL=$(curl -fsSL -u ${HZN_SETUP_ORG}/${HZN_USER_ID:-iamapikey}:${HZN_SETUP_APIKEY} ${HZN_SETUP_EXCHANGE}/orgs/${HZN_SETUP_ORG}/nodes 2> /dev/null)
  ENTITYS=$(echo "${ALL}" | jq '{"nodes":[.nodes | objects | keys[]] | unique}' | jq -r '.nodes[]')
  OUTPUT='{"nodes":['
  i=0; for ENTITY in ${ENTITYS}; do
    if [[ $i > 0 ]]; then OUTPUT="${OUTPUT}"','; fi
    OUTPUT="${OUTPUT}"$(echo "${ALL}" | jq '.nodes."'"${ENTITY}"'"' | jq -c '.id="'"${ENTITY}"'"')
    i=$((i+1))
  done
  OUTPUT="${OUTPUT}"']}'
  echo "${OUTPUT}" | jq -c '.'
}

hzn_setup_node_lookup()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  id="${1}"
  if [ ! -z "${id:-}" ]; then
    nodes=$(curl -fsSL -u ${HZN_SETUP_ORG}/${HZN_USER_ID:-iamapikey}:${HZN_SETUP_APIKEY} ${HZN_SETUP_EXCHANGE}/orgs/${HZN_SETUP_ORG}/nodes/${id})
    if [ ! -z "${nodes:-}" ]; then
      node=$(echo "${nodes}" | jq '.nodes|to_entries|first|.value.id=.key|.value')
    fi
  fi
  echo "${node:-}"
}

## create node in exchange
hzn_setup_node_create()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${1}" ]; then
    node="${1}"
    # setup command
    id=$(echo "${node}" | jq -r '.device')
    token=$(echo "${node}" | jq -r '.token')
    org=${HZN_SETUP_ORG}
    heu=${org}/${HZN_USER_ID:-iamapikey}:${HZN_SETUP_APIKEY}
    # test args
    if [ ! -z "${id:-}" ] && [ ! -z "${token:-}" ] && [ ! -z "${org:-}" ] && [ ! -z "${heu:-}" ]; then
      # setup command
      cmd="hzn exchange node create -o ${org} -u ${heu} -n ${id}:${token}"
      # run command
      out=$(HZN_EXCHANGE_URL=${HZN_SETUP_EXCHANGE} && ${cmd} 2>&1)
      # test output
      if [ !? != 0 ] && [ ! -z "${out}" ]; then
        hzn::log.debug "failure: ${cmd}; failed: ${out}"
      else
	# sleep 1
        node=$(hzn_setup_node_lookup "${id}")
        if [ ! -z "${node:-}" ] && [ $(echo "${node:-null}" | jq '.nodes|length') -gt 0 ]; then
          node=$(echo "${node}" | jq -c '.nodes|to_entries|first|.value.id=.key|.value')
        else
          hzn::log.warn "could not find device: ${id}"
        fi
      fi
    fi
  fi
  echo "${node:-}"
}

hzn_setup_node_valid()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  echo true
}

## approve (or not)
hzn_setup_approve()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  node="${1}"
  if [ ! -z "${node:-}" ] && [ "${node}" != 'null' ]; then
    id=$(echo "${node}" | jq -r '.device')
    if [ ! -z "${id}" ]; then
      hzn::log.debug "testing node: ${id}"
      case ${HZN_SETUP_APPROVE} in
        auto)
          hzn::log.debug "auto-approving node: ${id}"
	  token=$(echo "${node}" | jq -r '.serial' | sha1sum | awk '{ print $1 }')
          node=$(echo "${node}" | jq '.token="'"${token}"'"')
	  exchange=$(hzn_setup_node_create "${node}")
	  node=$(echo "${node}" | jq '.exchange='"${exchange:-null}")
	  ;;
        *)
	  ;;
      esac
    else
      hzn::log.debug "invalid id: ${node}"
    fi
  else
    hzn::log.debug "invalid node"
  fi
  echo "${node:-}"
}

## lookup node
hzn_setup_lookup()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  # should search the DB or the exchange
  if [ ! -z "${1:-}" ] && [ ! -z "${2:-}" ]; then
    serial="${1}"
    mac=$(echo "${2}" | sed 's/://g')
    device="${HZN_SETUP_BASENAME:-}${mac}"
    node=$(hzn_setup_node_lookup "${device}")
    if [ ! -z "${node:-}" ]; then
      hzn::log.debug "hzn_setup_lookup: found in exchange: ${device}"
    else
      hzn::log.debug "hzn_setup_lookup: not found in exchange: ${device}"
      node='null'
    fi
  fi
  echo '{"serial":"'${serial:-}'","device":"'${device:-}'","exchange":'${node:-}'}'
}

hzn_setup_process()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${1}" ]; then
    input="${1}"
    ## process input
    serial=$(echo "${input}" | jq -r '.serial')
    mac=($(echo "${input}" | jq -r '.mac'))

    hzn::log.debug "hzn_setup_process: serial: ${serial}; mac: ${mac}"

    ## lookup device
    node=$(hzn_setup_lookup ${serial} ${mac})

    if [ -z "${node:-}" ]; then
      hzn::log.debug "hzn_setup_process: no device found; serial: ${serial}; mac: ${mac}"
    elif [ $(echo "${node}" | jq '.exchange!=null') = true ]; then
      hzn::log.debug "hzn_setup_process: node already in exchange: ${node}"
    fi
    hzn::log.debug "hzn_setup_process: device found; not in exchange"
    node=$(hzn_setup_approve "${node}")
  fi
  echo "${node:-null}"
}

