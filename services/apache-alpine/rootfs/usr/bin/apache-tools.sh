#!/usr/bin/env bash

## START HTTPD
apache_start()
{
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
    # make /run/apache2 for PID file
    mkdir -p ${APACHE_RUN_DIR}
    # start HTTP daemon 
    httpd -E /dev/stderr -e ${LOG_LEVEL:-debug} -f "${APACHE_CONF}" &
    PID=$!
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no configuration: ${APACHE_CONF}" > /dev/stderr; fi
  fi
  echo "${PID:-0}"
}
