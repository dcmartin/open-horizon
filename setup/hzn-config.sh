#!/bin/bash

if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

## MACOS is strange
if [[ "$OSTYPE" == "darwin" && "$VENDOR" == "apple" ]]; then
  BASE64_ENCODE='base64'
else
  BASE64_ENCODE='base64 -w 0'
fi

if [ "${0%/*}" != "${0}" ]; then
  CONFIG="${0%/*}/horizon.json"
  TEMPLATE="${0%/*}/template.json"
else
  CONFIG="horizon.json"
  TEMPLATE="template.json"
fi

if [ -z "${1}" ]; then
  if [ -s "${CONFIG_FILE}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG_FILE}"
  elif [ -s "${TEMPLATE}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; using template: ${TEMPLATE} for default ${CONFIG_FILE}"
    cp -f "${TEMPLATE}" "${CONFIG_FILE}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG_FILE}; no template: ${TEMPLATE}"
    exit 1
  fi
else
  CONFIG_FILE="${1}"
fi
if [ ! -s "${CONFIG_FILE}" ]; then
  echo "*** ERROR $0 $$ -- configuration file empty: ${1}"
  exit 1
else
  echo "??? DEBUG $0 $$ -- configuration file: ${CONFIG_FILE}"
fi

for svc in kafka stt nlu nosql; do
 json="apiKey-${svc}.json"
 if [ -s "${json}" ]; then 
   echo "+++ WARN $0 $$ -- found existing ${json} file; using for ${svc} API key"
   apikey=$(jq -r '.apikey' "${json}")
   if [ -z "${apikey}" ] || [ $apikey == 'null' ]; then
     echo "+++ WARN: no apikey in ${json} for ${svc}; checking for api_key"
     apikey=$(jq -r '.api_key' "${json}")
   fi
   if [ -z "${apikey}" ] || [ "$apikey" == 'null' ]; then
     echo "+++ WARN: no API key found in ${json} for ${svc}"
     apikey='null'
     apiname='null'
   else
     apiname=$(jq -r '.iam_apikey_name' "${json}")
     if [ -z "${apiname}" ] || [ "${apiname}" == 'null' ]; then
       echo "+++ WARN: no iam_apikey_name found in ${json} for ${svc}"
       apiname='null'
     fi
   fi
   password=$(jq -r '.password' "${json}")
   if [ -z "${password}" ] || [ "$password" == 'null' ]; then
     echo "+++ WARN: no password found in ${json} for ${svc}"
     password='null'
   fi
   username=$(jq -r '.username' "${json}")
   if [ -z "${username}" ] || [ "$username" == 'null' ]; then
     echo "+++ WARN: no username found in ${json} for ${svc}"
     username='null'
   fi
   url=$(jq -r '.url' "${json}")
   if [ -z "${url}" ] || [ "$url" == 'null' ]; then
     echo "+++ WARN: no url found in ${json} for ${svc}"
     url='null'
   fi
   if [ ! -z "$SVC_API_KEYS" ]; then SVC_API_KEYS="${SVC_API_KEYS}"','; else SVC_API_KEYS='{'; fi
   SVC_API_KEYS="${SVC_API_KEYS}"'"'${svc}'":{"url":"'$url'","name_key":"'${apiname}:${apikey}'","user_pass":"'${username}:${password}'"}'
 fi
done
SVC_API_KEYS="${SVC_API_KEYS}"'}'
echo ${SVC_API_KEYS} | jq 

exit

CONFIG_DB='hzn-config'
CONFIG_NAME=$(hostname)
CLOUDANT_URL=$(echo "${SVC_API_KEYS}" | jq -r '.nosql.url')

# find configuration entry
URL="${CLOUDANT_URL}/${CONFIG_DB}/${CONFIG_NAME}"

VALUE=$(curl -sL "${URL}")
if [ "$(echo "${VALUE}" | jq '._id?=="'${CONFIG_NAME}'"')" != "true" ]; then
  echo "Found no existing configuration ${CONFIG_NAME}"
else
  REV=$(echo "${VALUE}" | jq -r '._rev?')
  if [[ "${REV}" != "null" && ! -z "${REV}" ]]; then
    echo "Found prior configuration ${CONFIG_NAME}; revision ${REV}"
    URL="${URL}?rev=${REV}"
  fi
  echo $(date) "Existing configuration ${CONFIG_NAME} with ${REV}"
fi

RESULT=$(curl -sL "${URL}" -X PUT -d '@'"${CONFIG_FILE}")

if [ "$(echo "${RESULT}" | jq '.ok?')" != "true" ]; then
  echo $(date) "Update configuration ${CONFIG_NAME} failed; ${CONFIG_FILE}" $(echo "${RESULT}" | jq '.error?')
else
  echo $(date) "Update configuration ${CONFIG_NAME} succeeded:" $(echo "${RESULT}" | jq -c '.')
fi

