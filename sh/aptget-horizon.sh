#!/bin/bash

HZN_URL="http://pkg.bluehorizon.network"
HZN_ARCH="armhf,arm64,amd64,ppc64el"
  
## install on debian
install_debian()
{
  # set type
  TYPE=linux
  # set repo
  REPO=updates
  # get ARCH
  ARCH=$(dpkg --print-architecture)

  # check type
  url="${HZN_URL}/${TYPE}/"
  echo "checking: ${url}" &> /dev/stderr
  curl -fsSL "${url}" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "TYPE: ${TYPE}; exists"
  else
    echo "TYPE: ${TYPE}; does not exist"
    exit 1
  fi

  # get distribution
  DIST=$(lsb_release -a 2> /dev/null | egrep "Distributor ID" | sed 's/.*:[ \t]*\([^ ]*\)/\1/' | tr '[:upper:]' '[:lower:]')
  if [ -z "${DIST:-}" ]; then 
    DIST="ubuntu"
    echo "+++ WARN -- $0 $$ -- distribution undefined; does not exist; using default: ${DIST}" &> /dev/stderr
  fi
  # test DIST
  curl -fsSL "${HZN_URL}/${TYPE}/${DIST}/dists/" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "DIST: ${DIST}; exists"
  else
    echo "DIST: ${DIST}; does not exist"
    exit 1
  fi

  # get release
  RELEASE=$(lsb_release -cs 2> /dev/null)
  if [ -z "${RELEASE:-}" ]; then
    RELEASE=xenial
    echo "+++ WARN -- $0 $$ -- release unspecified; using default: ${RELEASE}" &> /dev/stderr
  fi

  # get release repository
  if [ ! -z "${REPO}" ]; then 
    RELEASE="${RELEASE}-${REPO}"
    echo "--- INFO -- $0 $$ -- using release: ${RELEASE}" &> /dev/stderr
  else 
    RELEASE="${RELEASE}"
  fi

  # check distribution, repository and release
  curl -fsSL "${HZN_URL}/${TYPE}/${DIST}/dists/${RELEASE}/" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "--- INFO -- $0 $$ -- exists: type: ${TYPE}; distribution: ${DIST}; release: ${RELEASE}" &> /dev/stderr
  else
    echo "*** ERROR -- $0 $$ -- does no exist: type: ${TYPE}; distribution: ${DIST}; release: ${RELEASE}" &> /dev/stderr
    exit 1
  fi

  # add key
  KEY=${HZN_URL}/bluehorizon.network-public.key
  wget -qO - ${KEY} | sudo apt-key add - &> /dev/stderr
  # add package
  echo "deb [arch=${ARCH}] ${HZN_URL}/${TYPE}/${DIST} ${RELEASE} main" > /etc/apt/sources.list.d/bluehorizon.list
  # install package
  sudo apt-get update -qq && sudo apt-get install -y -qq bluehorizon &> /dev/stderr
}

install_macos()
{
  VERSION=$(curl -fsSL 'http://pkg.bluehorizon.network/macos/' | egrep 'horizon-cli' | sed 's/.*-cli-\(.*\)\.pkg<.*/\1/' | sort | uniq | tail -1)

  if [ -z "${1}" ]; then echo "--- INFO -- $0 $$ -- no version specified; using latest: ${VERSION}" &> /dev/stderr; else VERSION="${1}"; fi

  curl -fsSL http://pkg.bluehorizon.network/macos/certs/horizon-cli.crt -o horizon-cli.crt
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain horizon-cli.crt

  HZN_PLATFORM="macos"
  if [ ! -z $(command -v 'hzn') ]; then
    if [ ! -z "$(hzn node list 2> /dev/null)" ]; then
      echo "--- INFO -- $0 $$ -- unregistering" &> /dev/stderr
      hzn unregister -f
    fi
    HZNCLI_PKG="horizon-cli-${VERSION}.pkg"
    URL="${HZN_URL}/${HZN_PLATFORM}/${HZNCLI_PKG}"
    echo "--- INFO -- $0 $$ -- getting macOS package from: ${URL}" &> /dev/stderr
    TEMPKG=$(mktemp).pkg
    curl -fsSL "${URL}" -o "${TEMPKG}"
    echo "--- INFO -- $0 $$ -- downloaded; size: " $(wc -c "${TEMPKG}") &> /dev/stderr
    if [ -s "${TEMPKG}" ]; then
      echo "--- INFO -- $0 $$ -- installing ..." &> /dev/stderr
      sudo installer -pkg "${TEMPKG}" -target /
      echo "--- INFO -- $0 $$ -- updating container ..." &> /dev/stderr
      horizon-container update &> /dev/null
    else
      echo "*** ERROR -- $0 $$ -- cannot download package from URL: ${URL}" &> /dev/stderr
      exit 1
    fi
    rm -f "${TEMPKG}"
  fi
}

if [ ! -z $(command -v "apt-get") ]; then
  install_debian
else
  install_macos
fi
