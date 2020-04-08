#!/bin/bash

if [ "${USER:-}" != 'root' ]; then
  echo "Run as root: sudo ${0} ${*}" &> /dev/stderr
  exit 1
fi

# get particulars
arch=$(dpkg --print-architecture)
platform=$(lsb_release -a 2> /dev/null | egrep 'Distributor ID:' | awk '{ print $3 }' | tr '[:upper:]' '[:lower:]')
dist=$(lsb_release -a 2> /dev/null | egrep 'Codename:' | awk '{ print $2 }')

# only working version
repo=http://pkg.bluehorizon.network/linux
dir=pool/main/h/horizon
version=2.24.18

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

if [ -s HZN_EXCHANGE_URL ]; then HZN_EXCHANGE_URL=$(cat HZN_EXCHANGE_URL); fi
if [ "${HZN_EXCHANGE_URL:-null}" != 'null' ]; then
  echo 'Updating /etc/default/horizon with HZN_EXCHANGE_URL="'${HZN_EXCHANGE_URL}'"' &> /dev/stderr
  sed -i -e "s|^HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL}|" /etc/default/horizon
  restart=true
else
  echo 'Edit /etc/default/horizon and specify HZN_EXCHANGE_URL; then "sudo systemctl restart horizon"' &> /dev/stderr
fi

if [ -s HZN_FSS_CSSURL ]; then HZN_FSS_CSSURL=$(cat HZN_FSS_CSSURL); fi
if [ "${HZN_FSS_CSSURL:-null}" != 'null' ]; then
  echo 'Updating /etc/default/horizon with HZN_FSS_CSSURL="'${HZN_FSS_CSSURL}'"' &> /dev/stderr
  sed -i -e "s|^HZN_FSS_CSSURL=.*|HZN_FSS_CSSURL=${HZN_FSS_CSSURL}|" /etc/default/horizon
  restart=true
else
  echo 'Edit /etc/default/horizon and specify HZN_FSS_CSSURL; then "sudo systemctl restart horizon"' &> /dev/stderr
fi

if [ "${restart:-false}" = 'true' ]; then systemctl restart horizon; fi
