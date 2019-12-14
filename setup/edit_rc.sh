#!/bin/bash

## not for macintosh
if [ "${VENDOR}" == "apple" ] || [ "${OSTYPE}" == "darwin" ]; then
  echo "You're on a Macintosh; run in VirtualBox Ubuntu18 VM and use vmdk_sd.sh to enable SD card access" >&2
#  exit 1
fi

### DEFAULTS

DEFAULT_KEY_FILE=~/.ssh/id_rsa

## CONFIGURATION
if [ "${0%/*}" != "${0}" ]; then
  CONFIG="${0%/*}/horizon.json"
else
  CONFIG="horizon.json"
fi
if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}; run mkconfig.sh"
    exit 1
  fi
else
  if [ ! -s "${1}" ]; then
    echo "*** ERROR $0 $$ -- configuration file empty: ${1}"
    exit 1
  fi
  CONFIG="${1}"
fi

## SETUP
SETUP=$(jq -r '.setup' ${CONFIG})
if [ -z "${SETUP}" ] || [ "${SETUP}" == 'null' ]; then
  echo "*** ERROR $0 $$ -- no setup; edit ${CONFIG}"
  exit 1
fi
HORIZON_SETUP_URL=$(jq -r '.setups[]?|select(.id=="'${SETUP}'").url' "${CONFIG}")
if [ -z "${HORIZON_SETUP_URL}" ] || [ "${HORIZON_SETUP_URL}" == 'null' ]; then
  echo "*** ERROR $0 $$ -- cannot find setup ${SU}; edit ${CONFIG}"
  exit 1
fi

## NETWORK
NETWORK=$(jq -r '.default.network' "${CONFIG}")
if [ -z "${NETWORK}" ] || [ "${NETWORK}" == 'null' ]; then
  echo "*** ERROR $0 $$ -- no default network; run mkconfig.sh"
  exit 1
elif [ -n "$(jq '.networks[]?|select(.id=="'${NETWORK}'")' "${CONFIG}")" ]; then
  NETWORK_SSID=$(jq -r '.networks[]|select(.id=="'${NETWORK}'").ssid' "${CONFIG}")
  NETWORK_PASSWORD=$(jq -r '.networks[]|select(.id=="'${NETWORK}'").password' "${CONFIG}")
else
  echo "*** ERROR $0 $$ -- cannot find network ${NETWORK}; add to ${CONFIG}"
  exit 1
fi

## MACHINE
MACHINE=$(jq -r '.default.machine' "${CONFIG}")
if [ -z "${MACHINE}" ] || [ "${MACHINE}" == 'null' ]; then
  echo "*** ERROR $0 $$ -- no default machine; run mkconfig.sh"
  exit 1
elif [ -n "$(jq '.machines[]|select(.id=="'${MACHINE}'")' "${CONFIG}")" ]; then
  DID=$(jq -r '.machines[]|select(.id=="'$MACHINE'").distribution' "${CONFIG}")
  if [ -z "${DID}" ] || [ "${DID}" == 'null' ]; then
    echo "*** ERROR $0 $$ -- cannot find distribution ${DID}; add to ${CONFIG}"
    exit 1
  fi
  CLIENT_USERNAME=$(jq -r '.distributions[]|select(.id=="'$DID'").client.username' "${CONFIG}")
  CLIENT_PASSWORD=$(jq -r '.distributions[]|select(.id=="'$DID'").client.password' "${CONFIG}")
  CLIENT_HOSTNAME=$(jq -r '.distributions[]|select(.id=="'$DID'").client.hostname' "${CONFIG}")
  if [ -z "${CLIENT_USERNAME} ] || [ -z "${CLIENT_PASSWORD} ] || [ -z "${CLIENT_HOSTNAME}" ]; then
    echo "*** ERROR $0 $$ -- empty client hostname, username, or password; edit ${CONFIG}"
    exit 1
  elif [ "${CLIENT_USERNAME}" == 'null' ] || [ "${CLIENT_PASSWORD}" == 'null' ] || [ "${CLIENT_HOSTNAME}" == 'null' ]; then
    echo "*** ERROR $0 $$ -- null client hostname, username, or password; edit ${CONFIG}"
    exit 1
  else
    echo "$(date '+%T') INFO -- using client hostname: ${CLIENT_HOSTNAME}; username: ${CLIENT_USERNAME}; password: ${CLIENT_PASSWORD}"
  fi
else
  echo "*** ERROR $0 $$ -- cannot find machine ${MACHINE}; add to ${CONFIG}"
  exit 1
fi

## TOKEN
TOKEN=$(jq -r '.default.token' "${CONFIG}")
if [ -z "${TOKEN}" ] || [ "${TOKEN}" == 'null' ]; then
  echo "*** ERROR $0 $$ -- no default token; run mkconfig.sh"
  exit 1
elif [ "$(jq '.tokens[]|select(.id=="'"${TOKEN}"'").value' "${CONFIG}")" != "null" ]; then
  DEVICE_NAME=
  DEVICE_TOKEN=$(jq -r '.tokens[]|select(.id=="'"${TOKEN}"'").value' "${CONFIG}")
else
  echo "*** ERROR $0 $$ -- cannot find value for token ${TOKEN}; add to ${CONFIG}"
  exit 1
fi

## PARTITION
SDB="/dev/sdb"
if [ -z "${2}" ]; then
  if [ -e "${SDB}" ]; then
    echo "+++ WARN $0 $$ -- no device specified; found default ${SDB}"
  else
    echo "*** ERROR $0 $$ -- no device specified; no default (${SDB}) found"
    exit 1
  fi
else
  SDB="${2}"
fi
if [ ! -e "${SDB}" ]; then
  echo "*** ERROR $0 $$ -- device not found: ${SDB}"
  exit 1
fi
BOOT_PART=${SDB}1
if [ ! -e "${BOOT_PART}" ]; then
  echo "*** ERROR $0 $$ -- boot partition not found: ${BOOT_PART}"
  exit 1
fi
LINUX_PART=${SDB}2
if [ ! -e "${LINUX_PART}" ]; then
  echo "*** ERROR $0 $$ -- LINUX partition not found: ${LINUX_PART}"
  exit 1
fi

## MOUNT POINT
VOL=/mnt
if [ -z "${3}" ]; then
  if [ -d "${VOL}" ]; then
    echo "+++ WARN $0 $$ -- no mount point specified; found default directory: ${VOL}"
  else
    echo "*** ERROR $0 $$ -- no device specified; no default directory (${VOL}) found"
    exit 1
  fi
else
  VOL="${3}"
fi
if [ ! -d "${VOL}" ]; then
  echo "+++ WARN $0 $$ -- no mount point specified; found default directory: ${VOL}"
  sudo mkdir -p "${VOL}"
fi
BOOT_VOL="${VOL}/boot"
LINUX_VOL="${VOL}/linux"
# make directories
sudo mkdir -p "${BOOT_VOL}" "${LINUX_VOL}"
# test
if [ ! -d "${BOOT_VOL}" ] || [ ! -d "${LINUX_VOL}" ]; then
  echo "*** ERROR $0 $$ -- invalid mount directories: ${BOOT_VOL} & ${LINUX_VOL}"
  exit 1
fi

### BOOT

sudo mount "${BOOT_PART}" "${BOOT_VOL}"
if [ ! -d "${BOOT_VOL}" ]; then
  echo "*** ERROR $0 $$ -- failed to mount partition ${BOOT_PART} on ${BOOT_VOL}"
  exit 1
fi

## SSH ACCESS
SSH_FILE="${BOOT_VOL}/ssh"
sudo touch "${SSH_FILE}"
if [ ! -e "${SSH_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${SSH_FILE}"
  exit 1
fi
echo "$(date '+%T') INFO $0 $$ -- created ${SSH_FILE} for SSH access"
# public key setup
PUBLIC_KEY=$(jq -r '.default.keys.public' "${CONFIG}")
if [ -z "${PUBLIC_KEY}" ] || [ "${PUBLIC_KEY}" == "null" ]; then
  if [ -s "${DEFAULT_KEY_FILE}.pub" ] && [ -s "${DEFAULT_KEY_FILE}" ]; then
    echo "+++ WARN $0 $$ -- no configured keys; found default ${DEFAULT_KEY_FILE}"
    PRIVATE_KEY=$(base64 -w 0 "${DEFAULT_KEY_FILE}")
    PUBLIC_KEY=$(base64 -w 0 "${DEFAULT_KEY_FILE}.pub")
    jq '.keys={"public":"'"${PUBLIC_KEY}"'","private":"'"${PRIVATE_KEY}"'"}' "${CONFIG}" > "/tmp/$$.json"
    if [ -s "/tmp/$$.json" ]; then
      mv -f "/tmp/$$.json" "${CONFIG}"
    else
      echo "*** ERROR $0 $$ -- cannot update ${CONFIG}" &> /dev/stderr
      exit 1
    fi
  else
    echo "*** ERROR $0 $$ -- no public key; no default ${DEFAULT_KEY_FILE}.pub; run ssh-keygen" &> /dev/stderr
    exit 1
  fi
fi

## WPA
# SUPPLICANT
if [ -z "${WPA_SUPPLICANT_FILE:-}" ]; then
  WPA_SUPPLICANT_FILE="${BOOT_VOL}/wpa_supplicant.conf"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_SUPPLICANT_FILE: ${WPA_SUPPLICANT_FILE}"
fi
# WPA TEMPLATE
if [ -z "${WPA_TEMPLATE_FILE:-}" ]; then
    WPA_TEMPLATE_FILE="wpa_supplicant.tmpl"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_TEMPLATE_FILE: ${WPA_TEMPLATE_FILE}"
fi
if [ ! -s "${WPA_TEMPLATE_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not find: ${WPA_TEMPLATE_FILE}"
  exit 1
fi
# change template
sudo cp -f "${WPA_TEMPLATE_FILE}" "${WPA_SUPPLICANT_FILE}"
sudo sed -i \
  -e 's|%%NETWORK_SSID%%|'"${NETWORK_SSID}"'|g' \
  -e 's|%%NETWORK_PASSWORD%%|'"${NETWORK_PASSWORD}"'|g' \
  "${WPA_SUPPLICANT_FILE}"
if [ ! -s "${WPA_SUPPLICANT_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${WPA_SUPPLICANT_FILE}"
  exit 1
else
  echo "$(date '+%T') INFO -- created ${WPA_SUPPLICANT_FILE}:" $(cat "${WPA_SUPPLICANT_FILE}")
fi
# SUCCESS
echo "$(date '+%T') INFO $0 $$ -- ${WPA_SUPPLICANT_FILE} created"
# unmount & remove mount point directory
sudo umount "${BOOT_VOL}"
sudo rmdir "${BOOT_VOL}"

### LINUX

sudo mount "${LINUX_PART}" "${LINUX_VOL}"
if [ ! -d "${LINUX_VOL}" ]; then
  echo "*** ERROR $0 $$ -- failed to mount partition ${LINUX_PART} on ${LINUX_VOL}"
  exit 1
fi

# write public keyfile
if [ -n "${PUBLIC_KEY}" ]; then
  echo "${PUBLIC_KEY}" | base64 --decode | sudo tee "${LINUX_VOL}/ssh.pub" &> /dev/null
  if [ -s "${LINUX_VOL}/ssh.pub" ]; then
    echo "$(date '+%T') INFO $0 $$ -- created ${LINUX_VOL}/ssh.pub for authorized_hosts"
  else
    echo "*** ERROR $0 $$ -- failed to create ${LINUX_VOL}/ssh.pub for authorized_hosts"
    exit 1
  fi
else
  echo "*** ERROR $0 $$ -- no public key"
  exit 1
fi

## hzn-setup.sh
if [ -z "${HORIZON_SCRIPT:-}" ]; then
  HORIZON_SCRIPT="hzn-setup.sh"
else
  echo "+++ WARN $0 $$ -- non-standard HORIZON_SCRIPT: ${HORIZON_SCRIPT}"
fi
HORIZON_SCRIPT_FILE="${LINUX_VOL}/${HORIZON_SCRIPT}"
# get setup script
wget -qO "${HORIZON_SCRIPT_FILE}" "${HORIZON_SETUP_URL}"
# test
if [ ! -s "${HORIZON_SCRIPT_FILE}" ]; then
  echo "+++ WARN $0 $$ -- could not create: ${HORIZON_SCRIPT_FILE}; will attempt at boot"
else
  chmod 755 "${HORIZON_SCRIPT_FILE}"
fi

## RC.LOCAL
if [ -z "${RC_LOCAL_FILE:-}" ]; then
  RC_LOCAL_FILE="${LINUX_VOL}/etc/rc.local"
else
  echo "+++ WARN $0 $$ -- non-standard RC_LOCAL_FILE: ${RC_LOCAL_FILE}"
fi
# RC TEMPLATE
if [ -z "${RC_TEMPLATE_FILE:-}" ]; then
    RC_TEMPLATE_FILE="rc_local.tmpl"
else
  echo "+++ WARN $0 $$ -- non-standard RC_TEMPLATE_FILE: ${RC_TEMPLATE_FILE}"
fi
if [ ! -s "${RC_TEMPLATE_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not find: ${RC_TEMPLATE_FILE}"
  exit 1
fi
# change template
sudo cp -f "${RC_TEMPLATE_FILE}" "${RC_LOCAL_FILE}"
sudo sed -i \
  -e 's|%%CLIENT_USERNAME%%|'"${CLIENT_USERNAME}"'|g' \
  -e 's|%%CLIENT_HOSTNAME%%|'"${CLIENT_HOSTNAME}"'|g' \
  -e 's|%%DEVICE_TOKEN%%|'"${DEVICE_TOKEN}"'|g' \
  -e 's|%%HORIZON_SCRIPT%%|'"${HORIZON_SCRIPT}"'|g' \
  -e 's|%%HORIZON_SETUP_URL%%|'"${HORIZON_SETUP_URL}"'|g' \
  "${RC_LOCAL_FILE}"
# test
if [ ! -s "${RC_LOCAL_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${RC_LOCAL_FILE}"
  exit 1
fi
# SUCCESS
echo "$(date '+%T') INFO $0 $$ -- ${RC_LOCAL_FILE} created"

## SOCAT & NODE-ID
sudo cp -f "socat-node-id.sh" "/socat-node-id.sh"
sudo cp -f "node-id.sh" "/node-id.sh"
if [ ! -s "/socat-node-id.sh" ] || [ ! -s "/node-id.sh" ];; then
  echo "*** ERROR $0 $$ -- could not create /socat-node-id.sh or /node-id.sh"
  exit 1
fi
# SUCCESS
echo "$(date '+%T') INFO $0 $$ -- /socat-node-id.sh and /node-id.sh created"

# unmount & remove mount point directory
sudo umount "${LINUX_VOL}"
sudo rmdir "${LINUX_VOL}"

echo "$(date '+%T') INFO $0 $$ -- you may now safely eject disk ${SDB}"
