#!/usr/bin/env bash

## source
source ${0%/*}/log-tools.sh

## SSH
do_ssh()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local args=(${*}) 
  local machine="${args[0]}"
  local cmd=$(echo "${*}" | sed 's|^'${machine}' ||')

  local out=$(ssh -o "ConnectTimeout=${SSH_CONNECT_TIMEOUT:-5}" -o "CheckHostIP=no" -o "LogLevel=QUIET" -o "UserKnownHostsFile=/dev/null" -o "PasswordAuthentication=no" -o "NumberOfPasswordPrompts=0" -o "StrictHostKeyChecking=no" "${machine}" "LANG=en_US.UTF-8 ${cmd}")

  if [ $? != 0 ]; then
    hzn.log.error "machine: ${machine}; ssh failed"
  fi
  echo "${out:-}"
}

