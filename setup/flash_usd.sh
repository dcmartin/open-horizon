#!/bin/bash

if [ ! -z $(command -v "apt-get") ]; then
  echo "This script is for macOS only" >&2
  exit 1
fi

## HORIZON CONFIG
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
    echo "*** ERROR configuration file empty: ${1}"
    exit 1
  fi
  CONFIG="${1}"
fi

## DISTRIBUTION
if [ -z "${DISTRIBUTION}" ]; then
  DM=$(jq -r '.default.machine' ${CONFIG})
  if [ -z "${DM}" ] || [ "${DM}" == 'null' ]; then
    echo "*** ERROR $0 $$ -- no default machine in ${CONFIG}; run mkconfig.sh"
    exit 1
  fi
  DD=$(jq -r '.machines[]|select(.id=="'$DM'").distribution' ${CONFIG})
  if [ -z "${DD}" ] || [ "${DD}" == 'null' ]; then
    echo "*** ERROR $0 $$ -- no distribution for machine ${DM}; run mkconfig.sh"
    exit 1
  fi
  DU=$(jq -r '.distributions[]|select(.id=="'$DD'").url' ${CONFIG})
  if [ -z "${DU}" ] || [ "${DU}" == 'null' ]; then
    echo "*** ERROR $0 $$ -- no URL for distribution ${DD}; edit ${CONFIG}"
    exit 1
  fi
  DZ="${DD}.zip"
  if [ ! -s "${DZ}" ]; then
    DISTRIBUTION=
    echo -n "PROMPT: $DZ not found; download ${DD} distribution? [no]: "
    read VALUE
    if [ -z "${VALUE}" ]; then VALUE='no'; fi
    if [ "${VALUE}" == 'yes' ]; then
      echo "$(date '+%T') INFO -- downloading ${DZ} from ${DU}"
      wget -qO "${DZ}" "${DU}"
      if [ ! -s "${DZ}" ]; then
        echo "+++ WARN $0 $$ -- failed to download ${DZ}; flash manually"
      else
        DISTRIBUTION="${DZ}"
        echo "$(date '+%T') INFO $0 $$ -- downloaded distribution ${DISTRIBUTION}"
      fi
    else
      echo "+++ WARN $0 $$ -- no distribution; flash manually"
    fi
  fi  
elif [ ! -s "${DISTRIBUTION}" ]; then
  echo "+++ WARN $0 $$ -- could not find ${DISTRIBUTION}"
  DISTRIBUTION=
else
  echo "$(date '+%T') INFO $0 $$ -- using distribution ${DISTRIBUTION}"
fi

## ETCHER
ETCHER_DIR="/opt/etcher-cli"
ETCHER_CMD="balena-etcher"
if [ "${VENDOR}" != "apple" ] && [ "${OSTYPE}" != "darwin" ]; then
  ETCHER_URL=
else
  ETCHER_URL="https://github.com/balena-io/etcher/releases/download/v1.4.8/balena-etcher-cli-1.4.8-darwin-x64.tar.gz"
fi

ETCHER=$(command -v "${ETCHER_CMD}")
if [ -z "${ETCHER}" ] && [ -n "${ETCHER_URL}" ]; then
  if [ ! -d "${ETCHER_DIR}" ]; then
    echo "+++ WARN $0 $$ -- etcher CLI not installed in ${ETCHER_DIR}; installing from ${ETCHER_URL}" &> /dev/stderr
    mkdir "${ETCHER_DIR}"
    wget -qO - "${ETCHER_URL}" | ( cd "${ETCHER_DIR}" ; tar xzf - ; mv */* . ; rmdir * ) &> /dev/null
  fi
  ETCHER="${ETCHER_DIR}/${ETCHER_CMD}"
fi
if [ -z "${ETCHER}" ] || [ ! -e "${ETCHER}" ]; then
  echo "+++ WARN $0 $$ -- ${ETCHER_CMD} not configured for this platform"
fi

## BOOT VOLUME MOUNT POINT
if [ -z "${VOLUME_BOOT:-}" ]; then
  VOLUME_BOOT="/Volumes/boot"
else
  echo "+++ WARN $0 $$ -- non-standard VOLUME_BOOT: ${VOLUME_BOOT}"
fi
if [ ! -d "${VOLUME_BOOT}" ]; then
  echo "*** ERROR $0 $$ -- did not find directory: ${VOLUME_BOOT}; flash the SD card manually"
  exit 1
fi

## WIFI

NETWORK_SSID=$(jq -r '.networks|first|.ssid' "${CONFIG}")
NETWORK_PASSWORD=$(jq -r '.networks|first|.password' "${CONFIG}")
if [ "${NETWORK_SSID}" == "null" ] || [ "${NETWORK_PASSWORD}" == "null" ]; then
  echo "*** ERROR $0 $$ -- NETWORK_SSID or NETWORK_PASSWORD undefined; run mkconfig.sh"
  exit 1
elif [ -z "${NETWORK_SSID}" ]; then
  echo "*** ERROR $0 $$ -- NETWORK_SSID blank; run mkconfig.sh"
  exit 1
elif [ -z "${NETWORK_PASSWORD}" ]; then
  echo "+++ WARN $0 $$ -- NETWORK_PASSWORD is blank"
fi

## WPA SUPPLICANT
if [ -z ${WPA_SUPPLICANT_FILE:-} ]; then
  WPA_SUPPLICANT_FILE="${VOLUME_BOOT}/wpa_supplicant.conf"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_SUPPLICANT_FILE: ${WPA_SUPPLICANT_FILE}"
fi

## SSH ACCESS
SSH_FILE="${VOLUME_BOOT}/ssh"
touch "${SSH_FILE}"
if [ ! -e "${SSH_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${SSH_FILE}"
  exit 1
else
  # write public keyfile
  echo $(jq -r '.key.public' "${CONFIG}" | base64 --decode) > "${VOLUME_BOOT}/ssh.pub"
fi
echo "$(date '+%T') INFO $0 $$ -- created ${SSH_FILE} for SSH access"

## WPA TEMPLATE
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
sed \
  -e 's|%%NETWORK_SSID%%|'"${NETWORK_SSID}"'|g' \
  -e 's|%%NETWORK_PASSWORD%%|'"${NETWORK_PASSWORD}"'|g' \
  "${WPA_TEMPLATE_FILE}" > "${WPA_SUPPLICANT_FILE}"
if [ ! -s "${WPA_SUPPLICANT_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${WPA_SUPPLICANT_FILE}"
  exit 1
fi

## SUCCESS
echo "$(date '+%T') INFO $0 $$ -- ${WPA_SUPPLICANT_FILE} created using SSID ${NETWORK_SSID}; password ${NETWORK_PASSWORD}"

if [ -n $(command -v diskutil) ]; then
  echo "$(date '+%T') INFO $0 $$ -- ejecting volume ${VOLUME_BOOT}"
  diskutil eject "${VOLUME_BOOT}"
else
  echo "+++ WARN $0 $$ -- you may now safely eject volume ${VOLUME_BOOT}"
fi
