#!/bin/bash
arch=$(dpkg --print-architecture)
platform=$(lsb_release -a 2> /dev/null | egrep 'Distributor ID:' | awk '{ print $3 }' | tr '[:upper:]' '[:lower:]')
dist=$(lsb_release -a 2> /dev/null | egrep 'Codename:' | awk '{ print $2 }')
version=2.24.18

if [ ! -s bluehorizon.deb ]; then
  curl -sSL http://pkg.bluehorizon.network/linux/${platform}/pool/main/h/horizon/bluehorizon_${version}~ppa~${platform}.${dist}_all.deb -o bluehorizon.deb
fi

if [ ! -s horizon-cli.deb ]; then
  curl -sSL http://pkg.bluehorizon.network/linux/${platform}/pool/main/h/horizon/horizon-cli_${version}~ppa~${platform}.${dist}_${arch}.deb -o horizon-cli.deb
fi

if [ ! -s horizon.deb ]; then
  curl -sSL http://pkg.bluehorizon.network/linux/${platform}/pool/main/h/horizon/horizon_${version}~ppa~${platform}.${dist}_${arch}.deb -o horizon.deb
fi

if [ "${USER:-}" != 'root' ]; then
  echo "Run as root: sudo ${0} ${*}" &> /dev/stderr
  exit 1
fi

dpkg -i horizon-cli.deb
dpkg -i horizon.deb
dpkg -i bluehorizon.deb
