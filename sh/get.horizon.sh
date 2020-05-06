#!/bin/bash -x

## DEFAULTS

update_defaults()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  local result
  local url=${1:-${HZN_EXCHANGE_URL}}
  local fss=${2:-${HZN_FSS_CSSURL}}
  local ver=${3:-${HZN_AGENT_VERSION}}

  if [ ! -s "/etc/default/horizon" ]; then
    echo 'Creating /etc/default/horizon' &> /dev/stderr
    mkdir -p /etc/default 
    echo "HZN_EXCHANGE_URL=" > /etc/default/horizon
    echo "HZN_FSS_CSSURL=" >> /etc/default/horizon
    echo "HZN_DEVICE_ID=" >> /etc/default/horizon
    echo "HZN_MGMT_HUB_CERT_PATH=" >> /etc/default/horizon
    echo "HZN_AGENT_PORT=" >> /etc/default/horizon
  fi

  if [ "${url:-null}" != 'null' ]; then
    echo 'Updating /etc/default/horizon with HZN_EXCHANGE_URL='${url} &> /dev/stderr
    sed -i -e "s|^HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${url}|" /etc/default/horizon
    result=0
  else
    echo 'Edit /etc/default/horizon and specify HZN_EXCHANGE_URL; then restart horizon' &> /dev/stderr
  fi

  if [ "${fss:-null}" != 'null' ]; then
    echo 'Updating /etc/default/horizon with HZN_FSS_CSSURL='${fss} &> /dev/stderr
    sed -i -e "s|^HZN_FSS_CSSURL=.*|HZN_FSS_CSSURL=${fss}|" /etc/default/horizon
    result=0
  else
    echo 'Edit /etc/default/horizon and specify HZN_FSS_CSSURL; then restart horizon' &> /dev/stderr
  fi
  echo ${result:-1}
}

## LINUX

install_linux()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

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
      echo "Downloading ${p} ..." &> /dev/stderr
      if [ ! -s ${p}.deb ]; then
        if [ "${p}" = 'bluehorizon' ]; then dep=all; else dep=${arch}; fi
        package=${dir}/${p}
        curl -sSL ${repo}/${platform}/${package}_${version}~ppa~${platform}.${dist}_${dep}.deb -o ${p}.deb &> /dev/stderr
      fi
      echo "Installing ${p} ..." &> /dev/stderr
      dpkg --force-all -i ${p}.deb &> /dev/stderr
    done
  fi
  result=$(update_defaults)
  if [ "${result:-1}" -eq 0 ]; then 
    linux_start
  fi

  echo ${result:-0}
}

linux_start()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  systemctl restart horizon
}

## DARWIN

install_darwin()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  # which version
  local version=${1}
  local crt="http://pkg.bluehorizon.network/macos/certs/horizon-cli.crt"
  local pkg="http://pkg.bluehorizon.network/macos/horizon-cli-${version}.pkg"
  local result

  echo 'Downloading ...' &> /dev/stderr

  if [ ! -s "horizon-cli.crt" ]; then
    curl -sSL "${crt}" -o horizon-cli.crt
  fi
  if [ ! -s "horizon-cli.pkg" ]; then
    curl -sSL "${pkg}" -o horizon-cli.pkg
  fi

  echo 'Installing ...' &> /dev/stderr
  if [ -s "horizon-cli.crt" ]; then
    security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain horizon-cli.crt &> /dev/stderr
    result=$?
    if [ ${result} -eq 0 ]; then
      if [ -s "horizon-cli.pkg" ]; then
        installer -pkg "horizon-cli.pkg" -target / &> /dev/stderr
        result=$?
      else
        echo "Unable to download package; URL: ${pkg}" &> /dev/stderr
      fi
      if [ ${result} -ne 0 ]; then
        echo "Unable to install package; result: ${result}" &> /dev/stderr
      else
        result=$(update_defaults)
      fi
    else
      echo "Unable to add trusted certificate; result: ${result}" &> /dev/stderr
    fi
  else
    echo "Unable to download certificate; URL: ${crt}" &> /dev/stderr
  fi
  if [ "${result:-1}" -eq 0 ]; then
    darwin_start
  fi
  echo ${result:-1}
}

darwin_start()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  if [ ! -z "$(docker ps --format '{{.Names}}' | egrep '^horizon')" ]; then
    echo 'Running "horizon-container stop"' &> /dev/stderr
    horizon-container stop &> /dev/stderr
  fi
  if [ -z "$(command -v socat)" ]; then
    echo 'Install "socat"; then run "horizon-container start"' &> /dev/stderr
  else
    echo 'Running "horizon-container start"' &> /dev/stderr
    horizon-container start &> /dev/stderr
  fi
}

##

get_horizon()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "function: ${FUNCNAME[0]} ${*}" &> /dev/stderr; fi

  local url=${1}
  local fss=${2}
  local version=${3}
  local result

  if [ ! -z "${url:-}" ] && [ ! -z "${fss:-}" ] && [ ! -z "${version:-}" ]; then
    local uname=$(uname)

    if [ "${uname:-}" = 'Linux' ]; then
      result=$(install_linux ${version})
    elif [ "${uname:-}" = 'Darwin' ]; then
      result=$(install_darwin ${version})
    else
      echo 'Unknown system: ${uname}' &> /dev/stderr
    fi
  else
    echo "Invalid arguments; required: url, fss, version; provided: ${*}" &> /dev/stderr
  fi
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
  echo "Installing curl" &> /dev/stderr
  apt install -qq -y curl &> /dev/stderr
fi

if [ -z "$(command -v docker)" ]; then
  echo 'Installing Docker' &> /dev/stderr
  curl -sSL get.docker.com -o get.docker.sh &> /dev/stderr
  if [ -s get.docker.sh ]; then
    chmod 755 get.docker.sh
    ./get.docker.sh
  else
    echo 'Failed to get Docker installation script; download "http://get.docker.com"' &> /dev/stderr
    exit 1
  fi
fi

# if expressed
if [ -s HZN_EXCHANGE_URL ] && [ -z "${HZN_EXCHANGE_URL}" ]; then HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL:-$(cat HZN_EXCHANGE_URL)}; fi
if [ -s HZN_FSS_CSSURL ] && [ -z "${HZN_FSS_CSSURL:-}" ]; then HZN_FSS_CSSURL=${HZN_FSS_CSSURL:-$(cat HZN_FSS_CSSURL)}; fi
if [ -s HZN_AGENT_VERSION ] && [ -z "${HZN_AGENT_VERSION:-}" ]; then HZN_AGENT_VERSION=${HZN_AGENT_VERSION:-$(cat HZN_AGENT_VERSION)}; fi

# CONFIG
CONFIG=${0%/*}/../exchange/config.json

# test for defined
if [ -s "${CONFIG:-}" ]; then
  host=$(jq -r '.horizon.hostname' ${CONFIG})

  # exchange
  exchange_listen=$(jq -r '.services.exchange.listen' ${CONFIG})
  exchange_port=$(jq -r '.services.exchange.port' ${CONFIG})
  exchange_version=$(jq -r '.services.exchange.version' ${CONFIG})
  URL="${exchange_listen}://${host}:${exchange_port}/${exchange_version}/"
  if [ ! -z "${HZN_EXCHANGE_URL:-}" ] && [ "${HZN_EXCHANGE_URL:-}" != "${URL}" ]; then
    echo "WARNING: defined HZN_EXCHANGE_URL: ${HZN_EXCHANGE_URL}; does not match ${CONFIG}: ${URL}" &> /dev/stderr
  else
    HZN_EXCHANGE_URL="${URL}"
  fi

  # css
  css_listen=$(jq -r '.services.css.listen' ${CONFIG})
  css_port=$(jq -r '.services.css.port' ${CONFIG})
  FSS="${css_listen}://${host}:${css_port}/"
  if [ ! -z "${HZN_FSS_CSSURL:-}" ] && [ "${HZN_FSS_CSSURL:-}" != "${FSS}" ]; then
    echo "WARNING: defined HZN_FSS_CSSURL: ${HZN_FSS_CSSURL}; does not match ${CONFIG}: ${FSS}" &> /dev/stderr
  else
    HZN_FSS_CSSURL="${FSS}"
  fi

  # agbot
  agbot_tag=$(jq -r '.services.agbot.tag' ${CONFIG})
  VER="${agbot_tag}"
  if [ ! -z "${HZN_AGENT_VERSION:-}" ] && [ "${HZN_AGENT_VERSION:-}" != "${VER}" ]; then
    echo "WARNING: defined HZN_AGENT_VERSION: ${HZN_AGENT_VERSION}; does not match ${CONFIG}: ${VER}" &> /dev/stderr
  else
    HZN_AGENT_VERSION="${VER}"
  fi
fi

if [ ! -z "${HZN_EXCHANGE_URL:-}" ] && [ ! -z "${HZN_FSS_CSSURL:-}" ] && [ ! -z "${HZN_AGENT_VERSION:-}" ]; then
  echo 'STARTING..' 
  result=$(get_horizon ${HZN_EXCHANGE_URL} ${HZN_FSS_CSSURL} ${HZN_AGENT_VERSION})
  if [ -z "${result:-}" ] || [ ${#result} -gt 1 ] || [ ${result:-1} -gt 0 ]; then
    echo "Failed: result: ${result}"
  else
    echo 'Success'
  fi
else
  echo 'USAGE: '${0}' ${HZN_EXCHANGE_URL} ${HZN_FSS_CSSURL} ${HZN_AGENT_VERSION}; did you "make exchange" yet?'
fi
