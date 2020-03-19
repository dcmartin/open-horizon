#!/bin/bash

###
### THIS SCRIPT CHECKS FOR ENVIRONMENT VARIABLE SPECIFIED AS FILES
###
### IT SHOULD __NOT__ BE CALLED INTERACTIVELY
###

# args
if [ ! -z "${1}" ]; then 
  DIR="${1}"
else
  DIR="horizon"
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- directory unspecified; default: ${DIR}" &> /dev/stderr; fi
fi

if [ ! -z "${2}" ]; then 
  SERVICE_TEMPLATE="${2}"
else
  SERVICE_TEMPLATE="service.json"
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- service template unspecified; default: ${SERVICE_TEMPLATE}" &> /dev/stderr; fi
fi

# dependencies
if [ ! -d "${DIR}" ]; then echo "*** ERROR -- $0 $$ -- cannot locate directory ${DIR}; exiting"; exit 1; fi
if [ ! -s "${SERVICE_TEMPLATE}" ]; then echo "*** ERROR -- $0 $$ -- cannot locate service template JSON ${SERVICE_TEMPLATE}; exiting"; exit 1; fi

# service definition 
SERVICE_DEFINITION="${DIR}/service.definition.json"
if [ ! -s "${SERVICE_DEFINITION}" ]; then echo "*** ERROR -- $0 $$ -- cannot locate service JSON ${SERVICE_DEFINITION}; exiting"; exit 1; fi
SERVICE_URL=$(jq -r '.url' ${SERVICE_DEFINITION})

# user input
USERINPUT="${DIR}/userinput.json"
if [ ! -s "${USERINPUT}" ]; then echo "*** ERROR -- $0 $$ -- cannot locate userinput JSON ${USERINPUT}; exiting"; exit 1; fi

if [ ! -z "${DEBUG:-}" ]; then echo "--- INFO -- $0 $$ -- SERVICE_TEMPLATE: ${SERVICE_TEMPLATE}; SERVICE_URL=${SERVICE_URL}" &> /dev/stderr; fi

# check mandatory variables (i.e. those whose value is null in template)
user_input=$(jq '.userInput|length' ${SERVICE_TEMPLATE})
if [ ${user_input} -gt 0 ]; then
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- found ${user_input} userInput variables" &> /dev/stderr; fi
  for evar in $(jq -r '.userInput?[].name' "${SERVICE_TEMPLATE}"); do 
    VAL=$(jq -r '.services[]?|select(.url=="'${SERVICE_URL}'").variables|to_entries[]?|select(.key=="'${evar}'").value' ${USERINPUT}) 
    if [ ! -z "${DEBUG:-}" ]; then echo "--- INFO -- $0 $$ -- ${evar}: ${VAL}" &> /dev/stderr; fi
    if [ -s "${evar}" ]; then 
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- found file: ${evar}" &> /dev/stderr; fi
      VAL=$(cat "${evar}")
      UI=$(jq -c '(.services[]?|select(.url=="'${SERVICE_URL}'").variables.'${evar}')|='${VAL} "${USERINPUT}")
      echo "${UI}" > "${USERINPUT}"
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${evar}=${VAL}" &> /dev/stderr; fi
    fi
  done
fi

# check userinput
service_urls=$(jq -r '.services[]?.url' ${USERINPUT})
if [ ! -z "${service_urls}" ]; then
  for service_url in ${service_urls}; do
    variables=$(jq -r '.services[]|select(.url=="'${service_url}'")|.variables|to_entries[].key' ${USERINPUT})
    if [ ! -z "${variables}" ]; then
      for evar in ${variables}; do
        if [ -s "${evar}" ]; then 
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- found file: ${evar}" &> /dev/stderr; fi
          VAL=$(cat "${evar}")
          UI=$(jq -c '(.services[]|select(.url=="'${service_url}'").variables.'${evar}')|='${VAL} "${USERINPUT}")
          echo "${UI}" > "${USERINPUT}"
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- URL: ${service_url}; ${evar}=${VAL}" &> /dev/stderr; fi
        fi
      done
    else
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- URL: ${service_url}; no variables" &> /dev/stderr; fi
    fi
  done
fi
