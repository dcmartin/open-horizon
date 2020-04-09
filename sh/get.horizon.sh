#!/bin/bash

##
update_defaults()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: enter: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  local result

  if [ "${HZN_EXCHANGE_URL:-null}" != 'null' ]; then
    echo 'Updating /etc/default/horizon with HZN_EXCHANGE_URL="'${HZN_EXCHANGE_URL}'"' &> /dev/stderr
    sed -i -e "s|^HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL}|" /etc/default/horizon
    result=0
  else
    echo 'Edit /etc/default/horizon and specify HZN_EXCHANGE_URL; then "sudo systemctl restart horizon"' &> /dev/stderr
  fi

  if [ "${HZN_FSS_CSSURL:-null}" != 'null' ]; then
    echo 'Updating /etc/default/horizon with HZN_FSS_CSSURL="'${HZN_FSS_CSSURL}'"' &> /dev/stderr
    sed -i -e "s|^HZN_FSS_CSSURL=.*|HZN_FSS_CSSURL=${HZN_FSS_CSSURL}|" /etc/default/horizon
    result=0
  else
    echo 'Edit /etc/default/horizon and specify HZN_FSS_CSSURL; then "sudo systemctl restart horizon"' &> /dev/stderr
  fi
  echo ${result:-1}
}

##
install_linux()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: enter: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

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
  
  result=$(update_defaults)
  if [ "${result:-1}" -eq 0 ]; then systemctl restart horizon; fi
  
  echo ${result:-0}
}

install_darwin()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: enter: enter: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

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
    security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain horizon-cli.crt
    result=$?
    if [ ${result} -eq 0 ]; then
      if [ -s "horizon-cli.pkg" ]; then
        installer -pkg "horizon-cli.pkg" -target /
        result=$?
      else
        echo "Unable to download package; URL: ${pkg}" &> /dev/stderr
      fi
      if [ ${result} -ne 0 ]; then
        echo "Unable to install package; result: ${result}" &> /dev/stderr
      else
        echo 'Creating /etc/default/horizon' &> /dev/stderr
        mkdir -p /etc/default
        echo "HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL}" > /etc/default/horizon
        echo "HZN_FSS_CSSURL=${HZN_FSS_CSS_URL}" >> /etc/default/horizon
        if [ ! -z "$(docker ps --format '{{.Names}}' | egrep '^horizon')" ]; then
          echo 'Stopping horizon container' &> /dev/stderr
          horizon-container stop
        fi
        echo 'Starting horizon container' &> /dev/stderr
        horizon-container start
        result=$?
      fi
    else
      echo "Unable to add trusted certificate; result: ${result}" &> /dev/stderr
    fi
  else
    echo "Unable to download certificate; URL: ${crt}" &> /dev/stderr
  fi
  echo ${result:-1}
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: exit: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi
}

##

get_horizon()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: enter: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  local version=${1}
  local result
  local uname=$(uname)

  if [ "${uname:-}" = 'Linux' ]; then
    result=$(install_linux ${version})
  elif [ "${uname:-}" = 'Darwin' ]; then
    result=$(install_darwin ${version})
    echo 'DEBUG' &> /dev/stderr
  else
    echo 'Unknown system: ${uname}' &> /dev/stderr
  fi
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: exit: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi
  echo ${result:-1}
}

###
### MAIN
###

if [ "${USER:-}" != 'root' ]; then
  echo "Run as root: sudo ${0} ${*}" &> /dev/stderr
  exit 1
fi

if [ -z "$(command -v curl)" ]; then
  echo 'Please install curl; sudo apt install -qq -y curl' &> /dev/stderr
  exit 1
fi

if [ -z "$(command -v docker)" ]; then
  echo 'Installing Docker' &> /dev/stderr
  curl -sSL get.docker.com -o get.docker.sh 
  if [ -s get.docker.sh ]; then
    chmod 755 get.docker.sh
    ./get.docker.sh
  else
    echo 'Failed to get Docker installation script; download "http://get.docker.com"' &> /dev/stderr
    exit 1
  fi
fi

STABLE_VERSION=2.24.18

if [ -s HZN_EXCHANGE_URL ]; then HZN_EXCHANGE_URL=$(cat HZN_EXCHANGE_URL); fi
if [ -s HZN_FSS_CSSURL ]; then HZN_FSS_CSSURL=$(cat HZN_FSS_CSSURL); fi

get_horizon ${1:-${STABLE_VERSION}}
echo 'COMPLETE' &> /dev/stderr
