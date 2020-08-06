#!/usr/bin/env bash

source /usr/bin/hzn-tools.sh

###
### HOST INSPECTION
###

host_key()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ -z "${STARTUP_HOST_KEY:-}" ]; then
    hzn::log.warn "no host key defined: STARTUP_HOST_KEY"
    if [ -s $(startup_config_file) ]; then
      STARTUP_HOST_KEY=$(jq -r '.hostkey' $(startup_config_file))  
    else
      hzn::log.warn "no configuration file: $(startup_config_file)"
    fi
  fi
  echo "${STARTUP_HOST_KEY:-}"
}

host_ssh()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${1:-}" ] && [ ! -z "${2}" ]; then
    if [ ! -s "${SERVICE_LABEL}.key" ]; then
      if [ ! -z "$(host_key)" ] && [ ! -z "${STARTUP_HOST_USER}" ]; then
        hzn::log.debug "found host key for user: ${STARTUP_HOST_USER}"
        echo $(host_key) | base64 --decode > ${SERVICE_LABEL}.key
        chmod 400 ${SERVICE_LABEL}.key
      else
        hzn::log.debug "no host key: $(host_key); or user: ${STARTUP_HOST_USER}"
      fi
    fi
    if [ -s "${SERVICE_LABEL}.key" ]; then
      hzn::log.debug "host_ssh(): host: ${1}; cmd: ${2}"
      DATA=$(ssh -i "${SERVICE_LABEL}.key" ${1} -l ${STARTUP_HOST_USER} -o 'CheckHostIP no' -o 'StrictHostKeyChecking no' "${2}" 2> /dev/null)
    else
      hzn::log.debug "no host private key file: ${SERVICE_LABEL}.key"
    fi
  else
    hzn::log.warn "host_ssh(): invalid arguments"
  fi
  echo "${DATA:-}"
}

hzn_node_list()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${1:-}" ]; then
    echo $(host_ssh ${1} 'hzn node list')
  fi
}

docker_ps()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${1:-}" ]; then
    DPS=$(host_ssh ${1} 'docker ps --format "{\"id\":\"{{.ID}}\",\"name\":\"{{.Names}}\",\"command\":{{.Command}},\"status\":\"{{.Status}}\",\"ports\":\"{{.Ports}}\"}"')
    if [ ! -z "${DPS}" ]; then
      TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
      echo "${DPS}" | jq -c '.' | while read; do 
	if [ ! -s ${TEMP} ]; then echo '['"${REPLY}" >> ${TEMP}; else echo ','"${REPLY}" >> ${TEMP}; fi
      done
      if [ -s ${TEMP} ]; then echo ']' >> ${TEMP}; DPS=$(jq -c '.' ${TEMP}); else DPS='null'; fi
      rm -f ${TEMP}
    else
      DPS='null'
    fi
    echo "${DPS}"
  fi
}

sudo_nmap()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${1:-}" ]; then
    NMAP=$(host_ssh ${1} "sudo nmap -sn -T5 ${1%.*}.0/24")
    if [ ! -z "${NMAP:-}" ]; then
      NMAP=$(echo "${NMAP}" \
       | awk 'BEGIN { x=0; printf("["); } /Nmap scan report for/ {ip=$5} /MAC Address:/ {if (ip) { if (x++ > 0) printf(","); printf("{\"ip\":\"%s\",\"mac\":\"%s\"}", ip, $3) }} END { printf("]")}')
      echo "${NMAP}"
    fi
  fi
}

host_ip()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  HOSTIP_FILE=${TMPDIR}/${0##*/}-host.ipv4
  if [ ! -s "${HOSTIP:-}" ]; then
    IPS=$(echo "${HZN_HOST_IPS}" | sed 's/,/ /g')
    hzn::log.debug "Host IPs: ${IPS}"
    for IP in ${IPS}; do
      if [ ${IP} != '127.0.0.1' ]; then
        hzn::log.debug "Host IP: ${IP}"
        P=$(ping -t 1 -W 1 -c 1 ${IP} 2> /dev/null) && P=$(echo "${P}" | head -1 | awk -F'(' '{ print $2 }' | awk -F')' '{ print $1 }') || P=
        if [ ! -z "${P:-}" ]; then
	  echo "${P}" > ${HOSTIP_FILE}
          HOSTIP=${P}
          break
        fi
      fi
    done
  else
    HOSTIP=$(cat ${HOSTIP_FILE})
  fi
  echo ${HOSTIP}
}

host_inspect()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ ! -z "${HZN_HOST_IPS:-}" ]; then
    IPS=$(echo "${HZN_HOST_IPS}" | sed 's/,/ /g')
    hzn::log.debug "Host IPs: ${IPS}"
    for IP in ${IPS}; do
      if [ ${IP} != '127.0.0.1' ]; then
	hzn::log.debug "Host IP: ${IP}"
	HOSTIP=${IP}
	break
      fi
    done
    if [ ! -z "${HOSTIP:-}" ]; then
      HNL=$(hzn_node_list "${HOSTIP}")
      hzn::log.debug "hzn: " $(echo "${HNL}" | jq '.!=null')
      NMAP=$(sudo_nmap "${HOSTIP}")
      hzn::log.debug "nmap: " $(echo "${DPS}" | jq '.!=null')
    fi
  else
    hzn::log.warn "no HZN_HOST_IPS"
  fi
  echo '{"horizon":'${HNL:-null}',"nmap":'${NMAP:-null}'}'
}

