#!/bin/bash

if [ "${VENDOR}" == "apple" ] || [ "${OSTYPE}" == "darwin" ]; then
  echo "You're on a Macintosh; download from https://github.com/open-horizon/anax/releases; exiting" >&2
  exit 1
fi

if [ $(whoami) != "root" ]; then
  echo "!!! ERROR: Please run as root, e.g. sudo $0 $*" >&2
  exit 1
fi

# Specify the hardware architecture of this Edge Node

ARCH=$(arch)
if [ -z "${ARCH}" ]; then
  echo "!!! ERROR: No architecture detected; exiting" >&2
  exit 1
fi

if [ "${ARCH}" == "aarch64" ]; then
  ARCH="arm64"
elif [ "${ARCH}" == "x86_64" ]; then
  ARCH="amd64"
else
  ARCH=$(dpkg --print-architecture)
fi

if [ -z "${ARCH}" ]; then
  echo "Cannot automagically identify architecture; options are: arm, arm64, amd64, ppc64el" >&2
  exit 1
fi

echo "+++ INFO: Using architecture: ${ARCH}" >&2

# check apt
CMD=$(command -v apt)
if [ -z "${CMD}" ]; then
  echo "!!! ERROR: No apt(1) package installation; are you using Alpine; exiting" >&2
  exit 1
fi

# warn about DNS
if [ -e "/run/systemd/resolve/resolv.conf" ]; then
  echo "*** WARN: Check your /etc/resolv.conf for link to /run/systemd/resolve/resolv.conf under Ubuntu 18.04" >&2
fi

# check docker
CMD=$(command -v docker)
if [ -z "${CMD}" ]; then
  echo "+++ INFO: Installing docker" >&2
  wget -qO - get.docker.com | bash -s >&2
fi

# install pre-requisites
for CMD in jq curl ssh socat; do
  C=$(command -v $CMD)
  if [ -z "${C}" ]; then
    echo "+++ INFO: Installing ${CMD}" >&2
    apt install -y ${CMD} >&2
  fi
done

###
### HORIZON
###

if [ ! -n "${APT_REPO}" ]; then
  APT_REPO=updates
  echo "*** WARN: Using default APT_REPO = ${APT_REPO}" >&2
fi

# CLI
CMD=$(command -v hzn)
if [ ! -z "${CMD}" ]; then
  echo "*** WARN: Open Horizon already installed as ${CMD}; upgrading" >&2
  apt upgrade -y horizon bluehorizon horizon-cli >&2
else
  if [ ! -n "${APT_LIST}" ]; then
    APT_LIST=/etc/apt/sources.list.d/bluehorizon.list
    echo "*** WARN: Using default APT_LIST = ${APT_LIST}" >&2
  fi
  if [ ! -n "${PUBLICKEY_URL}" ]; then
    PUBLICKEY_URL=http://pkg.bluehorizon.network/bluehorizon.network-public.key
    echo "*** WARN: Using default PUBLICKEY_URL = ${PUBLICKEY_URL}" >&2
  fi
  if [ -e "${APT_LIST}" ]; then
    echo "*** WARN: Existing Open Horizon ${APT_LIST}; deleting" >&2
    rm -f "${APT_LIST}"
  fi
  # get public key and install
  echo "+++ INFO: Adding key for Open Horizon from ${PUBLICKEY_URL}" >&2
  curl -fsSL "${PUBLICKEY_URL}" | apt-key add - >&2
  echo "+++ INFO: Configuring Open Horizon repository ${APT_REPO} for ${ARCH}" >&2
  # create repository entry 
  echo "deb [arch=${ARCH}] http://pkg.bluehorizon.network/linux/ubuntu xenial-${APT_REPO} main" >> "${APT_LIST}"
  echo "deb-src [arch=${ARCH}] http://pkg.bluehorizon.network/linux/ubuntu xenial-${APT_REPO} main" >> "${APT_LIST}"
  echo "+++ INFO: Updating apt(1)" >&2
  apt update -y >&2
  echo "+++ INFO: Installing Open Horizon" >&2
  apt install -y horizon bluehorizon horizon-cli >&2
  # confirm installation
  if [ -z $(command -v hzn) ]; then
    echo "!!! ERROR: Failed to install horizon; exiting" >&2
    exit 1
  fi
fi

# LOGGING
if [ -z "${LOG_CONF}" ]; then
  LOG_CONF=/etc/rsyslog.d/10-horizon-docker.conf
  echo "*** WARN: Using default LOG_CONF = ${LOG_CONF}" >&2
fi
if [ -s "${LOG_CONF}" ]; then
  echo "*** WARN: Existing logging configuration: ${LOG_CONF}; skipping" >&2
else
  echo "+++ INFO: Configuring logging: ${LOG_CONF}" >&2
  rm -f "${LOG_CONF}"
  echo '$template DynamicWorkloadFile,"/var/log/workload/%syslogtag:R,ERE,1,DFLT:.*workload-([^\[]+)--end%.log"' >> "${LOG_CONF}"
  echo '' >> "${LOG_CONF}"
  echo ':syslogtag, startswith, "workload-" -?DynamicWorkloadFile' >> "${LOG_CONF}"
  echo '& stop' >> "${LOG_CONF}"
  echo ':syslogtag, startswith, "docker/" -/var/log/docker_containers.log' >> "${LOG_CONF}"
  echo '& stop' >> "${LOG_CONF}"
  echo ':syslogtag, startswith, "docker" -/var/log/docker.log' >> "${LOG_CONF}"
  echo '& stop' >> "${LOG_CONF}"
  echo "+++ INFO: Restarting rsyslog(8)" >&2
  service rsyslog restart >&2
fi

# SERVICE ACTIVATION
if [ $(systemctl is-active horizon.service) != "active" ]; then
  echo "+++ INFO: The horizon.service is not active; starting" >&2
  systemctl start horizon.service >&2
else
  echo "*** WARN: The horizon.service is already active; restarting" >&2
  systemctl restart horizon.service >&2
fi
# sleep to enable start or restart
sleep 5

hzn_version=$(hzn version | fmt)
hva=($(echo ${hzn_version}))
if [[ ${#hva[@]} == 8 ]]; then
  hzn_version=$(echo "$hzn_version" | awk '{printf("{\"cli\":\"%s\",\"agent\":\"%s\"}\n",$4,$8)}')
else
  hzn_version='{"cli":"'$hzn_version'","agent":"unknown"}'
fi

echo '{"repository":"'$APT_REPO'","horizon":'"$hzn_version"',"docker":"'`docker --version`'","command":"'`command -v hzn`'"}'

exit 0
