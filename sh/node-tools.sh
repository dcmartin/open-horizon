#!/usr/bin/env bash

## source
source ${0%/*}/ssh-tools.sh
source ${0%/*}/log-tools.sh

## NODE
node_reboot()
{
  local rebooting=false
  local machine=${1}
  local REBOOT=$(do_ssh ${machine} 'if [ -e /var/run/reboot-required ]; then echo true; else echo false; fi' 2> /dev/null)

  hzn.log.trace "${FUNCNAME[0]} ${*}"

  if [ "${REBOOT:-false}" = true ]; then
    rebooting=true
    hzn.log.debug "machine: ${machine} rebooting (required)"
    do_ssh ${machine} 'sudo shutdown -r now &' &> /dev/null
  fi
  echo "${rebooting}"
}

node_upgrades()
{
  local machine=${1}
  local upgrades=0

  hzn.log.trace "${FUNCNAME[0]} ${*}"

  do_ssh ${machine} 'sudo apt update -y &> update.log' &> /dev/null
  upgrades=$(do_ssh ${machine} 'apt list --upgradeable 2> /dev/null | wc -l')
  if [ ${upgrades:-0} -gt 1 ]; then
    upgrades=$((upgrades-1))
    hzn.log.debug "machine: ${machine} has ${upgrades} upgrades pending"
  fi
  echo "${upgrades:-0}"
}

node_timezone()
{
  local machine=${1}
  local new=${2:-}

  hzn.log.trace "${FUNCNAME[0]} ${*}"

  # /etc/localtime should be symbolic link to zoneinfo file
  if [ -z "${new:-}" ]; then new=$(file -h /etc/localtime | awk '{ print $5 }') && ZONE=${ZONE##*zoneinfo/}; fi
  hzn.log.debug "machine: ${machine}; timezone: ${new}"
  # change /etc/localtime on device to be symbolic link to zoneinfo file
  timezone=$(do_ssh ${machine} 'sudo rm -f /etc/localtime && sudo ln -s /usr/share/zoneinfo/'${new}' /etc/localtime && date +"%Z %z" 2>/dev/null')
  echo "${timezone:-}"
}

node_exchange()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local new=${2:-}
  local fss=${3:-}
  local result=

  if [ "${new:-null}" != 'null' ]; then
    local ns=$(node_list ${machine}) 
    local old=$(echo "${ns:-null}" | jq -r '.configuration.exchange_api')

    new="${new%%/${HZN_VERSION:-v1}*}/${HZN_VERSION:-v1}/"
    if [ "${new:-}" != "${old:-null}" ]; then
      local exchange

      hzn.log.debug "machine: ${machine}; old: ${old}; new: ${new}"
      do_ssh ${machine} 'sudo sed -i -e "s|HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL='${new}'|" /etc/default/horizon' &> /dev/null
      do_ssh ${machine} 'sudo sed -i -e "s|HZN_FSS_CSSURL=.*|HZN_FSS_CSSURL='${fss:-${new%/${HZN_VERSION:-v1}}/css}'|" /etc/default/horizon' &> /dev/null
      do_ssh ${machine} 'sudo service horizon restart' &> /dev/null
      # wait for new exchange
      hzn.log.debug "machine: ${machine}; waiting for horizon service to restart ..."
      i=0; while [ ${i} -lt 10 ]; do
	sleep 5
	hzn.log.debug "machine: ${machine} getting status"
	ns=$(node_list ${machine})
	if [ ! -z "${ns:-}" ]; then
	  exchange=$(echo ${ns} | jq -r '.configuration.exchange_api')
	  if [ "${exchange:-null}" = "${new}" ]; then
	    break
	  fi
	fi
	i=$((i+1))
	hzn.log.debug "machine: ${machine}; exchange: ${exchange}; requested: ${new}; iteration: ${i}"
      done
      if [ "${exchange}" != "${new}" ]; then
	exchange=$(node_list ${machine} | jq -r '.configuration.exchange_api') 
	hzn.log.warn "machine: ${machine}; timeout waiting; exchange: ${exchange}; old ${old}; requested: ${new}"
      else
	hzn.log.debug "machine: ${machine}; exchange: ${exchange}"
      fi
    else
      hzn.log.debug "machine: ${machine}; exchange unchanged; old: ${old}; new: ${new}"
      exchange=${old}
    fi
  else
    hzn.log.warn "machine: ${machine}; invalid exchange requested: ${new}"
    result=
  fi
  echo "${result:-}"
}

node_alive()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local timeout=${2:-10}
  local result=false
  local temp=$(mktemp)

  if [ ! -z "${machine}" ]; then
    local attempt=0
    local ping=false

    while [ ${attempt} -lt 5 ] && [ ${ping} = 'false' ]; do
      ping=$(ping -W ${timeout} -c 1 ${machine} &> ${temp} && echo 'true' || echo 'false')
      attempt=$((attempt+1))
      sleep 1
    done

    if [ "${ping:-false}" = 'true' ]; then 
      hzn.log.debug "machine: ${machine}; timeout: ${timeout}; ping success: ${ping}"
      result=true
    else
      hzn.log.debug "machine: ${machine}; timeout: ${timeout}; ping failure; output: $(cat ${temp})"
      result=false
    fi
  else
    hzn.log.error "${FUNCNAME[0]}: machine unspecified"
  fi
  rm -f ${temp}
  echo ${result}
}

node_list()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1:-}
  local result=null

  if [ ! -z "${machine:-}" ]; then
    result=$(do_ssh ${machine} 'hzn node list 2> /dev/null' 2> /dev/null)
    if [ -z "${result:-}" ]; then result='null'; fi
  fi
  echo "${result:-null}"
}

node_state()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local result=null
  local ns=$(node_list ${machine})

  result=$(echo "${ns:-}" | jq -r '.configstate.state')
  echo ${result:-null}
}

node_purge()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}

  if [ $(node_is_debian ${machine}) = true ]; then
    hzn.log.debug "machine: ${machine}; purging ..."
    #do_ssh ${machine} 'sudo DEBIAN_FRONTEND=noninteractive apt install -f -y &> /dev/null' &> /dev/null
    do_ssh ${machine} 'sudo DEBIAN_FRONTEND=noninteractive apt purge -y bluehorizon horizon horizon-cli &> purge.out' &> /dev/null
    do_ssh ${machine} 'sudo DEBIAN_FRONTEND=noninteractive apt autoremove -qq -y &> /dev/null' &> /dev/null
    do_ssh ${machine} 'sudo apt update -qq -y &> /dev/null' &> /dev/null
    do_ssh ${machine} 'docker system prune -fa &> /dev/null' &> /dev/null
    do_ssh ${machine} 'sudo rm -f /etc/apt/sources.list.d/bluehorizon.list &> /dev/null' &> /dev/null
  else
    hzn.log.debug "machine: ${machine}; unable to purge; not debian"
  fi
}

node_is_debian()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine="${1}"
  local result=false

  if [ ! -z "${machine:-}" ]; then
    debian=$(do_ssh ${1} 'lsb_release &> /dev/null && echo $?' 2> /dev/null)
    if [ ! -z "${debian}" ] && [ "${debian}" == '0' ]; then 
      result='true'
    elif [ -z "${debian}" ]; then
      result='null'
      hzn.log.warn "machine: ${machine}; unable to determine if debian; probable ssh failed"
    else
      hzn.log.debug "machine: ${machine}; not a debian platform"
    fi
  fi
  echo "${result:-false}"
}

node_install()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local url=${2:-}
  local fss=${3:-}
  local result=false

  if [ ! -z "${machine:-}" ]; then
    if [ $(node_is_debian ${1}) = true ]; then
      hzn.log.debug "machine: ${machine}; installing using apt(1)"
      result=$(node_install_apt ${1})
      if [ "${result:-false}" = 'true' ]; then
	# configure exchange
        hzn.log.debug "machine: ${machine}; configuring exchange; HZN_EXCHANGE_URL: ${url}; HZN_FSS_CSSURL: ${fss}"
        if [ ! -z $(node_exchange ${machine} ${url} ${fss:-}) ]; then
          hzn.log.warn "machine: ${machine}; unable to validate exchange: ${url}"
          result=false
	fi
      else
        hzn.log.warn "machine: ${machine}; install failed"
      fi
    else
      hzn.log.warn "machine: ${machine}; install failed"
    fi
  fi
  echo "${result:-false}"
}

## DEBIAN PACKAGE
HZNPKG_URL=${HZNPKG_URL:-"http://pkg.bluehorizon.network"}
HZNPKG_KEY=${HZNPKG_KEY:-${HZNPKG_URL}/bluehorizon.network-public.key}
HZNPKG_TYPE=${HZNPKG_TYPE:-linux}
HZNPKG_DIST=${HZNPKG_DIST:-ubuntu}
HZNPKG_RELEASE=${HZNPKG_RELEASE:-xenial}
HZNPKG_REPO=${HZNPKG_REPO:-updates}
HZNPKG_ARCH=arch="armhf,arm64,amd64,ppc64el"
HZNPKG_REPOSITORY="deb [${HZNPKG_ARCH}] ${HZNPKG_URL}/${HZNPKG_TYPE}/${HZNPKG_DIST} ${HZNPKG_RELEASE}-${HZNPKG_REPO} main"

node_install_apt()
{
  hzn.log.trace "${FUNCNAME[0]}" "${*}"

  local machine=${1}
  local result=false

  if [ ! -z "${machine:-}" ]; then
    local cmd

    hzn.log.debug "machine: ${machine}; using repository: ${HZNPKG_REPOSITORY}"

    # build command to setup package
    cmd='APT=/etc/apt/sources.list.d/bluehorizon.list'
    cmd="${cmd}"' && wget -qO - "'${HZNPKG_KEY}'" | sudo apt-key add - &> /dev/null'
    cmd="${cmd}"' && echo "'"${HZNPKG_REPOSITORY}"'" | sudo tee ${APT} &> /dev/null'
    # run package setup command
    hzn.log.trace "machine: ${machine}; updating sources: ${cmd}"
    do_ssh ${machine} "${cmd}" &> /dev/stderr

    # apt update
    result=$(do_ssh ${machine} 'sudo apt update -y &> update.log && echo "true" || cat update.log')
    if [ "${result:-}" = 'true' ]; then
      # install
      hzn.log.debug "machine: ${machine}; installing bluehorizon"
      result=$(do_ssh ${machine} 'sudo DEBIAN_FRONTEND=noninteractive apt install -y bluehorizon &> install.log && echo "true" || cat install.log')
      if [ "${result:-}" = 'true' ]; then
        # clean
        hzn.log.debug "machine: ${machine}; installation successful; cleaning up"
        do_ssh ${machine} 'sudo apt autoremove -qq -y &> /dev/null' &> /dev/null
      else
        hzn.log.warn "machine: ${machine}; failed to install bluehorizon; result: ${result}"
      fi
    else
      hzn.log.warn "machine: ${machine}; failed to apt update; result: ${result}"
    fi
  fi
  echo "${result:-false}"
}

node_unregister()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local result=

  if [ ! -z "${machine:-}" ]; then
    result=$(do_ssh ${machine} 'hzn unregister -f -r &> unregister.log && echo "true" || echo "false"' 2> /dev/null)
    if [ "${result:-false}" = false ]; then
      hzn.log.debug "machine: ${machine}; unregistration failed"
    fi
  fi
  echo "${result:-false}"
}

node_register()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local url=${2:-}
  local org=${3:-}
  local apikey=${4:-}
  local pattern=${5:-}
  local input=${6:-}
  local result=false

  if [ -z "${input:-}" ] || [ -z "${pattern:-}" ] || [ -z "${apikey:-}" ] || [ -z "${org:-}" ] || [ -z "${url}" ] || [ -z "${machine}" ]; then
    hzn.log.error "invalid arguments"
  else
    # check (and enforce) proper exchange
    hzn.log.debug "copying ${input} to ${machine}"
    # copy input.json
    result=$(cat ${input} | do_ssh ${machine} 'cat > input.json && echo "true" || echo "false"' 2> /dev/null)
    if [ "${result:-}" = true ]; then
      hzn.log.debug "copied ${input} to ${machine}"
      # register
      result=$(do_ssh ${machine} 'HZN_EXCHANGE_URL='${url}' hzn register '${org}' '${pattern}' -u '${org}/${HZN_USER_ID:-iamapikey}:${apikey}' -f input.json -n '${pattern}'-$(hostname):whocares &> register.log && echo "true" || cat register.log' 2> /dev/null)
      if [ "${result:-}" = true ]; then
        hzn.log.debug "machine: ${machine}; registration successful: ${url} ${org} ${pattern}"
      else
        hzn.log.debug "machine: ${machine}; registration failed: ${result}"
        result='false'
      fi
    else
      hzn.log.debug "machine: ${machine}; userinput copy failed"
    fi
  fi
  echo "${result:-}"
}

node_update()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local url=${2:-}
  local org=${3:-}
  local apikey=${4:-}
  local pattern=${5:-}
  local input=${6:-}
  local result
  local state=$(node_state ${machine})

  case ${state} in
    unconfigured)
      hzn.log.debug "machine: ${machine}; state: ${state}; registering ..."
      result=$(node_register ${machine} ${url} ${org} ${apikey} ${pattern} ${input}) 
      if [ "${result:-}" = true ]; then
        result=
        state=$(node_state ${machine})
        hzn.log.debug "machine: ${machine}; registration succeeded; new state: ${state}"
      else
	result=false
        hzn.log.debug "machine: ${machine}; registration failed"
      fi
      ;;
    configuring)
      hzn.log.debug "machine: ${machine}; state: ${state}; unregistering ..."
      result=$(node_unregister ${machine})
      if [ "${result}" = true ]; then
        hzn.log.debug "machine: ${machine}; ... unregistering successful"
        state=$(node_state ${machine})
        hzn.log.debug "machine: ${machine}; post-unregistration; state: ${state}"
      else
        hzn.log.debug "machine: ${machine}; ... unregistering failed; result: ${result}"
      fi
      ;;
    unconfiguring)
      hzn.log.debug "machine: ${machine}; state: ${state}; purging ..."
      node_purge ${machine}
      result=
      state=$(node_state ${machine})
      ;;
    configured)
      local current=$(node_list ${machine} | jq -r '.pattern')

      if [ "${pattern}" = "${current}" ]; then
        URL=$(do_ssh ${machine} hzn service list | jq -r '.[]?.url' | while read; do if [ "${REPLY##*.}" == "${current##*/}" ]; then echo "${REPLY}"; fi; done)
        VER=$(do_ssh ${machine} hzn service list | jq -r '.[]?|select(.url=="'${URL}'").version' 2> /dev/null)
        hzn.log.debug "machine: ${machine}; state: ${state}; pattern: ${current}; version: ${VER}; url: ${URL}"
      else
        hzn.log.debug "machine: ${machine}; state: ${state}; pattern: ${current}; non-matching: ${SERVICE_PATTERN}; unregistering ..."
        result=node_unregister ${machine}
        state=$(node_state ${machine})
      fi
      ;;
    null)
      # we shouldn't have to purge before installing, but we do
      hzn.log.debug "machine: ${machine}; purging before installing..."
      node_purge ${machine}
      hzn.log.debug "machine: ${machine}; installing..."
      result=$(node_install ${machine} ${url} ${HZN_FSS_CSSURL}) 
      if [ "${result:-}" != 'true' ]; then
        hzn.log.debug "machine: ${machine}; install failure; result=${result}"
      else
        hzn.log.debug "machine: ${machine}; install success"
        result=
        state=$(node_state ${machine})
      fi
      ;;
    *)
      hzn.log.warn "machine: ${machine}; state: ${state}; ignoring"
      ;;
  esac
  echo ${result:-${state:-null}}
}

## node TCP/IPv4 address
node_ip()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local timeout=${2:-10}
  local ping=$(ping -W ${timeout}  -c 1 ${machine} 2> /dev/null)

  ping=$(echo "${ping}" | head -1 | awk -F'(' '{ print $2 }' | awk -F')' '{ print $1 }') || ping=
  hzn.log.trace "machine: ${machine}; ip: ${ping}"
  echo "${ping:-}"
}

## hzn version
node_horizon_status()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local hzn=$(do_ssh ${machine} 'hzn version 2> /dev/null | fmt' 2> /dev/null)

  if [ -z "${hzn:-}" ]; then
    hzn.log.debug "machine: ${machine} does not have Horizon installed"
    hzn='{"horizon":{"cli":"notfound","agent":"notfound"}}'
  else
    hzn.log.trace "machine: ${machine}; horizon: ${hzn}"
    cli_version=$(echo "${hzn}" | sed 's/.*CLI version: \([^ ]*\).*/\1/')
    hzn.log.trace "machine: ${machine}; cli_version: ${cli_version}"
    agent_version=$(echo "${hzn}" | sed 's/.*Agent version: \([^ ]*\).*/\1/')
    hzn.log.trace "machine: ${machine}; agent_version: ${agent_version}"
    hzn='{"horizon":{"cli":"'${cli_version}'","agent":"'${agent_version}'"}}'
  fi
  echo "${hzn:-}"
}

## docker version
node_docker_status()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local result='{"docker":{"version":"notfound","build":"notfound"}}'
  local out=$(do_ssh ${machine} 'command -v docker 2> /dev/null')

  if [ ! -z "${out:-}" ]; then
    out=$(do_ssh ${machine} 'docker --version 2> /dev/null' 2> /dev/null)

    if [ -z "${out:-}" ]; then
      hzn.log.warn "machine: ${machine}; docker command failed"
    else
      hzn.log.debug "machine: ${machine}; docker output: ${out}"
      result=$(echo "${out}" | sed 's/Docker version \(.*\), build \(.*\)/{"docker":{"version":"\1","build":"\2"}}/')
      hzn.log.debug "machine: ${machine}; docker: ${result}"
    fi
  fi
  echo "${result}"
}

## node's Docker containers
node_containers()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local dockerps=$(do_ssh ${nodeip} 'docker ps --format "{{.Names}},{{.Image}}"' 2> /dev/null)
  local containers

  if [ -z "${dockerps}" ]; then
    hzn.log.debug "machine: ${machine}; empty response from docker ps"
    containers='{"containers": []}'
  else
    containers=$(echo "${dockerps}" | awk -F, 'BEGIN { printf("{\"containers\":["); x=0 } { if (x++>0) printf(","); printf("{\"name\":\"%s\",\"image\":\"%s\"}\n", $1, $2) } END { printf("]}")}')
  fi
  hzn.log.debug "machine: ${machine}; containers: ${containers}"
  echo "${containers}"
}


## agreements and workloads
node_agreements()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local agreements=$(do_ssh ${machine} 'hzn agreement list 2> /dev/null' 2> /dev/null)
  echo "${agreements}"
}

node_workloads()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local agreements=$(node_agreements ${machine})
  local workloads

  if [ ! -z "${agreements}" ]; then
    workloads=$(echo "${agreements}" | jq -c '{"workloads":[.[].workload_to_run]}')
  else
    workloads='{"workloads": []}'
  fi
  echo "${workloads}"
}

## services and urls
node_services()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local services=$(do_ssh ${machine} 'hzn service list 2> /dev/null' 2> /dev/null)
  echo "${services}"
}

node_services_urls()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local services=$(node_services ${machine})

  if [ -z "${services:-}" ]; then
    services='{"services_urls": []}'
  else
    services=$(echo "${services}" | jq -c '{"services_urls":[.[].url]}')
  fi
  echo "${services}"
}

## eventlog and errors
node_eventlog()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local eventlog=$(do_ssh ${nodeip} 'hzn eventlog list 2> /dev/null' 2> /dev/null)
  echo "${eventlog:-}"
}

node_errors()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local eventlog=$(node_eventlog ${machine})
  local errors

  if [ -z "${eventlog}" ]; then
    hzn.log.debug "machine: ${machine}; no eventlog"
    errors='{"errors": []}'
  else
    errors=$(echo "${eventlog}" | jq -r '.[]' | egrep "Error" | head "-${errors:-1}" | awk -F':   ' 'BEGIN { printf("{\"errors\":["); x=0 } { if(x++>0) printf(","); s1=sprintf("%s",$1); gsub("\"","",s1); s2=sprintf("%s",$2); gsub("\"","",s2); printf("{\"time\":\"%s\",\"message\":\"%s\"}",s1,s2); } END { printf("]}") }')
  fi
  hzn.log.trace "machine: ${machine}; errors: ${errors}"
  echo "${errors}"
}

# setup docker
node_docker_install()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local user=${2:-${USER}}
  local result=false
  local docker=$(node_docker_status ${machine})

  # {"docker":{"version":"notfound","build":"notfound"}}
  if [ $(echo "${docker:-null}" | jq -r '.docker.version') != 'notfound' ]; then
    hzn.log.debug "machine: ${machine}; docker installed: ${docker}"
    result=true
  else
    hzn.log.debug "machine: ${machine}; installing docker"
    local success=$(do_ssh ${machine} 'curl -sSL get.docker.com | sudo bash &> docker.log && echo "true" || cat docker.log')
    if [ "${success:-}" != true ]; then
      hzn.log.debug "machine: ${machine}; docker installation failed; result: ${success}"
      result=false
    else
      hzn.log.debug "machine: ${machine}; docker installed"
      result=true
    fi
  fi
  # ensure socket is readable
  if [ "${result:-}" = true ]; then
    # add user to docker group
    hzn.log.debug "machine: ${machine}; adding user: ${user} to group: docker"  
    do_ssh ${machine} 'sudo addgroup '${user}' docker' &> /dev/null
    # set permissions on Docker socket
    if [ $(do_ssh ${machine} 'sudo chmod o+rw /var/run/docker.sock 2> /dev/null && echo "true" || echo "false"') != true ]; then
      hzn.log.debug "machine: ${machine}; unable to change mode on docker socket"  
      result=false
    else
      hzn.log.debug "machine: ${machine}; changed mode on docker socket"  
      result=true
    fi
  fi
  echo "${result}"
}

node_access()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local user=${2:-${USER}}
  local account=$(do_ssh ${user}@${machine} 'whoami' 2> /dev/null)

  if [ -z "${account:-}" ]; then
    hzn.log.debug "machine: ${machine}; user: ${user}; no ssh access"
    user='root'
    account=$(do_ssh ${user}@${machine} 'whoami' 2> /dev/null)
    if [ -z "${account:-}" ]; then
      hzn.log.debug "machine: ${machine}; user: ${user}; no ssh access"
    else
      hzn.log.debug "machine: ${machine}; user: ${user}; account: ${account}"
    fi
  else
    hzn.log.debug "machine: ${machine}; user: ${user}; account: ${account}"
  fi
  echo "${account:-null}"
}

# setup development account
node_adduser()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local machine=${1}
  local user=${2}
  local pubkey=${3:-}
  local force=${4:-false}
  local result=false

  if [ -z "${machine:-}" ]; then
    hzn.log.error "machine: ${machine}; no machine specified"
  elif [ -z "${user:-}" ]; then
    hzn.log.error "machine: ${machine}; no user specified"
  elif [ -z "${pubkey:-}" ]; then
    hzn.log.error "machine: ${machine}; no public key specified; set HZNSETUP_PUBLIC_KEY"
  else
    local account=$(node_access ${machine} ${user})

    if [ "${force}" = true ] || [ "${account}" != "${user}" ] && [ "${account}" != 'null' ]; then
      hzn.log.debug "machine: ${machine}; account: ${account}; adding user ${user}; force: ${force}"
      do_ssh ${account}@${machine} 'adduser --disabled-password --gecos "" '${user} &> /dev/null
      do_ssh ${account}@${machine} 'addgroup '${user}' sudo' &> /dev/null
      do_ssh ${account}@${machine} 'addgroup '${user}' root' &> /dev/null
      do_ssh ${account}@${machine} 'mkdir -p ~'${user}'/.ssh' &> /dev/null
      do_ssh ${account}@${machine} 'chmod 700 ~'${user}'/.ssh' &> /dev/null
      do_ssh ${account}@${machine} 'echo "'${pubkey}'" >> ~'${user}'/.ssh/authorized_keys' &> /dev/null
      do_ssh ${account}@${machine} 'chmod 600 ~'${user}'/.ssh/authorized_keys' &> /dev/null
      do_ssh ${account}@${machine} 'chown -R '${user}' ~'${user}'/.ssh' &> /dev/null
      do_ssh ${account}@${machine} 'chgrp -R '${user}' ~'${user}'/.ssh' &> /dev/null
      do_ssh ${account}@${machine} 'echo "'${user}' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_'${user}'-nopasswd' &> /dev/null
      do_ssh ${account}@${machine} 'chmod 400 /etc/sudoers.d/010_'${user}'-nopasswd' &> /dev/null
      result=true
    elif [ "${account}" = 'null' ]; then
      hzn.log.error "machine: ${machine}; user ${user}; account: ${account}"
    else
      hzn.log.debug "machine: ${machine}; user ${user} exists; force: ${force}"
      result=true
    fi
  fi
  echo "${result:-false}"
}
