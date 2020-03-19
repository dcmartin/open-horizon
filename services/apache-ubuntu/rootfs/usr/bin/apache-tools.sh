#!/usr/bin/env bash

## START HTTPD
apache_start()
{
  hzn.log.trace "${FUNCNAME[0]} ${*}"

  local PID=0

  if [ -s "${APACHE_CONF}" ]; then
    # edit defaults
    sed -i 's|^Listen \(.*\)|Listen '${APACHE_PORT}'|' "${APACHE_CONF}"
    sed -i 's|^ServerName \(.*\)|ServerName '"${APACHE_HOST}:${APACHE_PORT}"'|' "${APACHE_CONF}"
    sed -i 's|^ServerAdmin \(.*\)|ServerAdmin '"${APACHE_ADMIN}"'|' "${APACHE_CONF}"
    # enable CGI
    sed -i 's|^\([^#]\)#LoadModule cgi|\1LoadModule cgi|' "${APACHE_CONF}"
    # set HZN
    echo "SetEnv HZN ${HZN:-none}" >> "${APACHE_CONF}"
    # set environment
    for evar in ${*:-}; do
      eval=$(eval "echo \$$evar") 
      echo "SetEnv ${evar} ${eval}"  >> "${APACHE_CONF}"
    done
    # make log directory
    mkdir -p ${APACHE_LOG_DIR:-/var/www/logs}
    # make /run/apache2 for PID file
    mkdir -p ${APACHE_RUN_DIR}

    hzn.log.notice "Starting HTTP daemon"

    # start HTTP daemon 
    apachectl -DFOREGROUND -E /dev/stderr -e ${APACHE_LOG_LEVEL:-info} -f ${APACHE_CONF} &
    PID=$!

    hzn.log.notice "Started HTTP daemon; PID: ${PID}"

    # store PID
    mkdir -p ${APACHE_PID_FILE%/*}
    echo "${PID}" > ${APACHE_PID_FILE}
  else
    hzn.log.error "No configuration file: ${APACHE_CONF}"
  fi
  echo "${PID:-0}"
}
