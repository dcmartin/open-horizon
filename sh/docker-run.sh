#!/bin/bash

###
### THIS SCRIPT PROVIDES EXECUTION OF SERVICE CONTAINERS LOCALLY
###
### IT SHOULD __NOT__ BE CALLED INTERACTIVELY
###

# name
if [ -n "${1}" ]; then 
  DOCKER_NAME="${1}"
else
  echo "*** ERROR -- -- $0 $$ -- DOCKER_NAME unspecified; exiting"
  exit 1
fi

# tag
if [ -n "${2}" ]; then
  DOCKER_TAG="${2}"
else
  echo "*** ERROR -- $0 $$ -- DOCKER_TAG unspecified; exiting"
  exit 1
fi

## configuration
if [ -z "${SERVICE:-}" ]; then SERVICE="service.json"; fi
if [ ! -s "${SERVICE}" ]; then echo "*** ERROR -- $0 $$ -- Cannot locate service configuration ${SERVICE}; exiting" &> /dev/stderr; exit 1; fi
SERVICE_LABEL=$(jq -r '.label' "${SERVICE}")

## privileged
if [ "$(jq '.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'").value.privileged?==true' "${SERVICE}" 2> /dev/null)" = true ]; then
  OPTIONS="${OPTIONS:-}"' --privileged'
fi

## host network
if [ "$(jq '.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'").value.hostnetwork?==true' "${SERVICE}" 2> /dev/null)" = true ]; then
  OPTIONS="${OPTIONS:-}"' --net=host'
fi

## environment
EVARS=$(jq '.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'").value.environment?' "${SERVICE}" 2> /dev/null)
if [ "${EVARS}" != 'null' ]; then
  OPTIONS="${OPTIONS:-} $(echo "${EVARS}" | jq -r '.[]' | while read -r; do T="-e ${REPLY}"; echo "${T}"; done)"
fi

## input
if [ -z "${USERINPUT:-}" ]; then USERINPUT="userinput.json"; fi
if [ ! -s "${USERINPUT}" ] && [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- cannot locate ${USERINPUT}; continuing" &> /dev/stderr; fi

# temporary file-system
if [ $(jq '.tmpfs!=null' "${SERVICE}") = true ]; then 
  # size
  TS=$(jq -r '.tmpfs.size' ${SERVICE})
  if [ -z "${TS}" ] || [ "${TS}" == 'null' ]; then 
    if [ "${DEBUG:-}" = true ];  then echo "--- INFO -- $0 $$ -- temporary filesystem; no size specified; defaulting to 8 Mbytes" &> /dev/stderr; fi
    TS=4096000
  fi
  # destination
  TD=$(jq -r '.tmpfs.destination' ${SERVICE})
  if [ -z "${TD}" ] || [ "${TD}" == 'null' ]; then 
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- temporary filesystem; no destination specified; defaulting to /tmpfs" &> /dev/stderr; fi
    TD="/tmpfs"
  fi
  # mode
  TM=$(jq -r '.tmpfs.mode' ${SERVICE})
  if [ -z "${TM}" ] || [ "${TM}" == 'null' ]; then 
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- temporary filesystem; no mode specified; defaulting to 1777" &> /dev/stderr; fi
    TM="1777"
  fi
  OPTIONS="${OPTIONS:-}"' --mount type=tmpfs,destination='"${TD}"',tmpfs-size='"${TS}"',tmpfs-mode='"${TM}"
else
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- no tmpfs" &> /dev/stderr; fi
fi

# inputs
if [ "$(jq '.userInput!=null' ${SERVICE})" = true ]; then
  URL=$(jq -r '.url' ${SERVICE})
  NAMES=$(jq -r '.userInput[].name' ${SERVICE})
  for NAME in ${NAMES}; do
    DV=$(jq -r '.userInput[]|select(.name=="'$NAME'").defaultValue' ${SERVICE})
    if [ -s "${USERINPUT}" ]; then
      VAL=$(jq -r '.services[]|select(.url=="'${URL}'").variables|to_entries[]|select(.key=="'${NAME}'").value' ${USERINPUT})
    fi
    if [ -s "${NAME}" ]; then
       VAL=$(sed 's/^"\(.*\)"$/\1/' "${NAME}")
    fi
    if [ -n "${VAL}" ] && [ "${VAL}" != 'null' ]; then 
      DV=${VAL};
    elif [ "${DV}" == 'null' ]; then
      echo "*** ERROR -- $0 $$ -- value NOT defined for required: ${NAME}; create file ${NAME} with JSON value; exiting"
      exit 1
    fi
    OPTIONS="${OPTIONS:-}"' -e '"${NAME}"'='"${DV}"
  done
else
  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no inputs" &> /dev/stderr; fi
fi

# ports
PORTS=$(jq -r '.deployment.services|to_entries[]|.value.specific_ports[].HostPort' ${SERVICE})
if [ ! -z "${PORTS}" ]; then
  for P in ${PORTS}; do
    HOST_PORT=$(echo "${P}" | sed 's/\([0-9]*\).*/\1/')
    if [ -z "${HOST_PORT}" ]; then
      echo "*** ERRROR: no port specified: ${P}; continuing" &> /dev/stderr
      continue
    fi
    CONTAINER_PORT=$(echo ${P} | sed 's/[0-9]*[:]*\([0-9]*\).*/\1/')
    if [ -z "${CONTAINER_PORT}" ]; then CONTAINER_PORT=${HOST_PORT}; fi
    if [ "${SERVICE_PORT}" -eq "${CONTAINER_PORT:-}" ]; then
      echo "+++ WARN -- $0 $$ -- service port: ${CONTAINER_PORT}; continuing" &> /dev/stderr
      continue
    fi
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- mapping service port: ${CONTAINER_PORT} to host port: ${HOST_PORT}" &> /dev/stderr; fi
    OPTIONS="${OPTIONS:-}"' --publish='"${HOST_PORT}"':'"${CONTAINER_PORT}"
  done
fi

if [ ! -z "${SERVICE_PORT:-}" ]; then
  if [ -z "${DOCKER_PORT}" ]; then DOCKER_PORT=${SERVICE_PORT}; fi
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- mapping service port: ${SERVICE_PORT} to host port: ${DOCKER_PORT}" &> /dev/stderr; fi
  OPTIONS="${OPTIONS:-}"' --publish='"${DOCKER_PORT}"':'"${SERVICE_PORT}"
else
 if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no ports mapped" &> /dev/stderr; fi
fi

if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- docker run -d --name ${DOCKER_NAME} ${OPTIONS} ${DOCKER_TAG}" &> /dev/stderr; fi
docker run --restart=unless-stopped -d --name "${DOCKER_NAME}" ${OPTIONS} "${DOCKER_TAG}"
