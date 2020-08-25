#!/usr/bin/with-contenv bashio

apache::start()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local PID=0

  if [ -s "${APACHE_CONF:-}" ]; then
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

    # start HTTP daemon 
    if [ ! -z "$(command -v apachectl)" ]; then
      apachectl -DFOREGROUND -E /dev/stderr -e ${APACHE_LOG_LEVEL:-info} -f ${APACHE_CONF} &
      PID=$!
    else
      httpd -E /dev/stderr -E /dev/stderr -e ${APACHE_LOG_LEVEL:-info} -f "${APACHE_CONF}" &
      PID=$!
    fi
    hzn::log.debug "${FUNCNAME[0]}: started HTTP daemon; PID: ${PID}"

    # store PID
    mkdir -p ${APACHE_PID_FILE%/*}
    echo "${PID}" > ${APACHE_PID_FILE}

    # wait for apache
    hzn::log.info "${FUNCNAME[0]}: waiting for Apache server; 5 seconds..."
    sleep 5

  else
    hzn::log.error "${FUNCNAME[0]}: no configuration file: ${APACHE_CONF:-}"
  fi

  echo "${PID:-0}"
}

apache::service.update()
{ 
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local output=${1:-}"

  if [ -z "${output}" ] || [ ! -e "${output}" ]; then
    hzn::log.error "${FUNCNAME[0]}: no file; output: ${output}"
  else
    local PID

    # test for PID file
    if [ ! -z "${APACHE_PID_FILE:-}" ]; then
      if [ -s "${APACHE_PID_FILE}" ]; then
        PID=$(cat ${APACHE_PID_FILE})
      else
        hzn::log.warning "${FUNCNAME[0]}: Apache failed to start"
      fi
    else
      hzn::log.error "${FUNCNAME[0]}: APACHE_PID_FILE is undefined"
    fi
  
    # create output
    echo -n '{"pid":'${PID:-0}',"status":"' > ${output}
  
    # get status
    if [ ${PID:-0} -ne 0 ]; then
      local tmp=$(mktemp)
      local err=$(mktemp)
  
      # request server status
      hzn::log.notice "${FUNCNAME[0]}: Apache PID: ${PID:-};requesting Apache server status: http://localhost:${APACHE_PORT:-}/server-status"
      curl -fkqsSL "http://localhost:${APACHE_PORT:-}/server-status" -o ${tmp} 2> ${err}
      # test server output
      if [ -s "${tmp}" ]; then
        hzn::log.debug "${FUNCNAME[0]}: RECEIVED: server status:" $(cat ${tmp})
        cat "${tmp}" | base64 -w 0 >> ${output}
      else
        hzn::log.warning "${FUNCNAME[0]}: FAILED: no server status; error:" $(cat ${err})
      fi
    else
      hzn::log.error "${FUNCNAME[0]}: No Apache PID"
    fi
  
    # terminate output
    echo '"}' >> ${output}
  fi
}
