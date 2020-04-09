#!/bin/bash

##
install_defaults()
{
  local result

  if [ -s HZN_EXCHANGE_URL ]; then HZN_EXCHANGE_URL=$(cat HZN_EXCHANGE_URL); fi
  if [ "${HZN_EXCHANGE_URL:-null}" != 'null' ]; then
    echo 'Updating /etc/default/horizon with HZN_EXCHANGE_URL="'${HZN_EXCHANGE_URL}'"' &> /dev/stderr
    sed -i -e "s|^HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL}|" /etc/default/horizon
    result=0
  else
    echo 'Edit /etc/default/horizon and specify HZN_EXCHANGE_URL; then "sudo systemctl restart horizon"' &> /dev/stderr
  fi

  if [ -s HZN_FSS_CSSURL ]; then HZN_FSS_CSSURL=$(cat HZN_FSS_CSSURL); fi
  if [ "${HZN_FSS_CSSURL:-null}" != 'null' ]; then
    echo 'Updating /etc/default/horizon with HZN_FSS_CSSURL="'${HZN_FSS_CSSURL}'"' &> /dev/stderr
    sed -i -e "s|^HZN_FSS_CSSURL=.*|HZN_FSS_CSSURL=${HZN_FSS_CSSURL}|" /etc/default/horizon
    result=0
  else
    echo 'Edit /etc/default/horizon and specify HZN_FSS_CSSURL; then "sudo systemctl restart horizon"' &> /dev/stderr
  fi
  if [ "${result:-1}" -eq 0 ]; then systemctl restart horizon; fi
  echo ${result:-1}
}

##
install_linux()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "${FUNCNAME[0} ${*}" &> /dev/stderr; fi

  # which version
  local version=${1}
  local result

  # LINUX specifics
  local arch=$(dpkg --print-architecture)
  local platform=$(lsb_release -a 2> /dev/null | egrep 'Distributor ID:' | awk '{ print $3 }' | tr '[:upper:]' '[:lower:]')
  local dist=$(lsb_release -a 2> /dev/null | egrep 'Codename:' | awk '{ print $2 }')
  local repo=http://pkg.bluehorizon.network/linux
  local dir=pool/main/h/horizon
  
  if [ ! -z "$(command -v hzn)" ]; then
    echo 'The "hzn" command is already installed; remove with "sudo dpkg --purge bluehorizon horizon horizon-cli"' &> /dev/stderr
  else
    # download packages
    for p in horizon-cli horizon bluehorizon; do
      if [ ! -s ${p}.deb ]; then
        if [ "${p}" = 'bluehorizon' ]; then dep=all; else dep=${arch}; fi
        package=${dir}/${p}
        curl -sSL ${repo}/${platform}/${package}_${version}~ppa~${platform}.${dist}_${dep}.deb -o ${p}.deb
      fi
      dpkg -i ${p}.deb
    done
  fi
  
  install_defaults
  
  echo ${result:-0}
}

install_darwin()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "${FUNCNAME[0} ${*}" &> /dev/stderr; fi

  # which version
  local version=${1}
  local crt="http://pkg.bluehorizon.network/macos/certs/horizon-cli.crt"
  local pkg="http://pkg.bluehorizon.network/macos/horizon-cli-${version}.pkg"
  local result

  if [ ! -s "horizon-cli.crt" ]; then
    curl -sSL "${crt}" -o horizon-cli.crt
  fi
  if [ ! -s "horizon-cli.pkg" ]; then
    curl -sSL "${pkg}" -o horizon-cli.pkg
  fi

  if [ -s "horizon-cli.crt" ]; then
    result=$(security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain horizon-cli.crt)
    if [ ${result} -eq 0 ]; then
      if [ -s "horizon-cli.pkg" ]; then
        result=$(installer -pkg "horizon-cli-2.24.18.pkg" -target /)
      else
        echo 'Unable to download package; URL: ${pkg}' &> /dev/stderr
      fi
      if [ ${result} -ne 0 ]; then
        echo 'Unable to install package; result: ${result}' &> /dev/stderr
      fi
    else
      echo 'Unable to add trusted certificate; result: ${result}' &> /dev/stderr
    fi
  else
    echo 'Unable to download certificate; URL: ${crt}' &> /dev/stderr
  fi
  echo ${result:-1}
}

##

get_horizon()
{
  local version=${1}
  local result

  case $(uname) in 
    Linux)
      result=$(install_linux ${version})
      ;;
    Darwin)
      result=$(install_darwin ${version})
      ;;
  esac
  echo ${result:-1}
}

###
### MAIN
###

STABLE_VERSION=2.24.18

if [ "${USER:-}" != 'root' ]; then
  echo "Run as root: sudo ${0} ${*}" &> /dev/stderr
  exit 1
else
  exit $(get_horizon ${1:-${STABLE_VERSION}})
fi
