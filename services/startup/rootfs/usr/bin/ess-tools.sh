#!/usr/bin/env bash

## validate environment
ess_verify()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=false
  if [ ! -z "${1:-}" ]; then
    VAR="${1:-}"
    if [ -z "${!VAR}" ]; then 
      RESULT=false
    else
      RESULT=true
    fi
  fi
  echo "${RESULT}"
}

## initialize ESS
ess_init()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ ! -z "${HZN_AGREEMENTID:-}" ] \
    && [ $(ess_verify 'HZN_RAM') ] \
    && [ $(ess_verify 'HZN_CPUS' ) ] \
    && [ $(ess_verify 'HZN_ARCH' ) ] \
    && [ $(ess_verify 'HZN_DEVICE_ID' ) ] \
    && [ $(ess_verify 'HZN_ORGANIZATION' ) ] \
    && [ $(ess_verify 'HZN_EXCHANGE_URL' ) ] \
    && [ $(ess_verify 'HZN_ESS_API_PROTOCOL' ) ] \
    && [ $(ess_verify 'HZN_ESS_API_ADDRESS' ) ] \
    && [ $(ess_verify 'HZN_ESS_API_PORT' ) ] \
    && [ $(ess_verify 'HZN_ESS_AUTH' ) ] \
    && [ $(ess_verify 'HZN_ESS_CERT' ) ]
  then
    hzn.log.debug all environment variables specified"
    if [ ! -z "${1}" ]; then
      org="${1}"
      ess_org "${org}" &> /dev/null
    fi
  else
    hzn.log.warn "no HZN_AGREEMENTID; not running as a service"
  fi
}

ess_org()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ ! -z "${1}" ]; then
    if [ -z "${ESS_SYNC_ORG}" ]; then
      export ESS_SYNC_ORG="${1}"
    else 
      export ESS_SYNC_ORG="${1}"
      hzn.log.debug "changing ESS_SYNC_ORG: ${ESS_SYNC_ORG}"
    fi
  fi
  echo "${ESS_SYNC_ORG:-${HZN_ORGANIZATION}}"
}

ess_url()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ ! -z "${HZN_ESS_API_ADDRESS:-}" ]; then
    hzn.log.warn "ess_url(): HZN_ESS_API_ADDRESS: ${HZN_ESS_API_ADDRESS}"
  else
    hzn.log.warn "ess_url(): HZN_ESS_API_ADDRESS: undefined"
  fi
  echo "https://localhost/api/v1"
}

ess_get()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=false
  if [ ! -z "${HZN_ESS_AUTH:-}" ] && [ ! -z "${1}" ]; then
    item="${1}"
    args="${2:-}"

    hzn.log.debug "ess_get(): item: ${item}; args: ${args}"

    if [ ! -z "${args}" ]; then
      url="$(ess_url)/${item}/${args}"
    else
      url="$(ess_url)/${item}"
    fi 

    USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
    PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")
    TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")

    HTTP_CODE=$(curl \
      -sSL \
      -X GET \
      -w '%{http_code}' \
      -o ${TEMP} \
      -u "${USER}:${PSWD}" \
      --cacert ${HZN_ESS_CERT} \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      "${url}")
    case ${HTTP_CODE} in
      200)
        if [ -s ${TEMP} ]; then
          hzn.log.debug "ess_get(): received response; size: " $(wc -c ${TEMP})
          RESULT="$(cat ${TEMP})"
        else
          hzn.log.debug "ess_get(): no response"
	  RESULT=
        fi
	;;
      404)
        hzn.log.warn "ess_get(): not found: ${url}"
	RESULT=
	;;
      500)
        hzn.log.warn "ess_get(): failure: ${url}; HTTP: ${HTTP_CODE}"
	RESULT=
	;;
      *)
        hzn.log.warn "ess_get(): failure: ${url}; unexpected HTTP code: ${HTTP_CODE}"
	RESULT=
	;;
    esac
    rm -f ${TEMP}
  else
    hzn.log.debug "ess_get(): invalid environment or arguments: ${*}"
    RESULT=
  fi
  echo "${RESULT}"
}

ess_health()
{
  hzn.log.trace "${FUNCNAME[0]}"

  echo $(ess_get 'health')
}

ess_object_list()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ -z "${1:-}" ]; then type='model'; else type="${1}"; fi
  if [ "${2:-}" = true ]; then 
    DATA=$(ess_get "objects" "${type}?received=true")
  else
    DATA=$(ess_get "objects" "${type}")
  fi
  hzn.log.debug "ess_objects(): type: ${type}; received: ${2:-false}"
  echo "${DATA}"
}

ess_object_about()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ -z "${1:-}" ]; then objectType='model'; else type="${1}"; fi
  if [ ! -z "${2:-}" ]; then 
    objectID="${2}"
    DATA=$(ess_get "objects" "${objectType}/${objectID}")
  fi
  echo "${DATA}"
}

ess_object_delete()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ -z "${1:-}" ]; then objectType='model'; else type="${1}"; fi
  if [ ! -z "${2:-}" ]; then 
    objectID="${2}"
    HTTP_CODE=$(ess_delete "objects" "${objectType}/${objectID}")
    case ${HTTP_CODE} in
      204)
	RESULT=true
	;;
      500)
	RESULT=false
	;;
      *)
	RESULT=false
	;;
    esac
  fi
  echo "${RESULT}"
}

ess_object_receipt()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=
  if [ "${HZN_ESS_AUTH:-null}" != 'null' ]; then
    if [ -z "${2:-}" ]; then objectType='model'; else objectType="${2}"; fi
    if [ ! -z "${1}" ]; then
      objectID="${1}"
      url="$(ess_url)/objects/${objectType}/${objectID}/received"

      USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
      PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")
      TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")

      HTTP_CODE=$(curl \
	-sSL \
	-X PUT \
	-o ${TEMP} \
	-w '%{http_code}' \
	-u "${USER}:${PSWD}" \
	--cacert ${HZN_ESS_CERT} \
	--unix-socket ${HZN_ESS_API_ADDRESS} \
	"${url}")
      case ${HTTP_CODE} in
	204)
	  hzn.log.debug "ess_object_receipt(): success; output: " $(cat ${TEMP})
          RESULT=true
	  ;;
	500)
	  hzn.log.warn "ess_object_receipt(): failed; output: " $(cat ${TEMP})
	  ;;
	*)
	  hzn.log.warn "ess_object_receipt(): failed; code: ${HTTP_CODE}; output: " $(cat ${TEMP})
	  ;;
      esac
      rm -f ${TEMP}
    fi
  fi
  echo "${RESULT}"
}

ess_object_data_get()
{
  hzn.log.trace "${FUNCNAME[0]}"

  TEMP=
  if [ ! -z "${1}" ]; then
    objectID="${1}"
    if [ -z "${2:-}" ]; then objectType='model'; else objectType="${2}"; fi
    hzn.log.debug "ess_object_data_get(): ID: ${objectID}; type: ${objectType}"
    if [ "${HZN_ESS_AUTH:-null}" != 'null' ]; then
      url="$(ess_url)/objects/${objectType}/${objectID}/data"

      USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
      PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")
      TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")

      HTTP_CODE=$(curl \
	-sSL \
	-w '%{http_code}' \
	-o "${TEMP}" \
	-u "${USER}:${PSWD}" \
	--cacert ${HZN_ESS_CERT} \
        --unix-socket ${HZN_ESS_API_ADDRESS} \
	"${url}")
      case ${HTTP_CODE} in
        200)
	  hzn.log.debug "ess_object_data_get(): success; size: " $(wc -c ${TEMP})
	  ;;
	500)
	  hzn.log.debug "ess_object_data_get(): failed to download"
	  ;;
      esac
    fi
  fi
  echo "${TEMP:-}"
}

## status of object based on ID and Type
#
# Get the status of the object of the specified object type and object ID.
#
# notReady - The object is not ready to be sent to destinations.
# ready - The object is ready to be sent to destinations.
# received - The object's metadata has been received but not all its data.
# completelyReceived - The full object (metadata and data) has been received.
# consumed - The object has been consumed by the application.
# deleted - The object was deleted.
#
ess_object_status()
{
  hzn.log.trace "${FUNCNAME[0]}"

  objectID=${1}
  objectType="${2:-model}"

  if [ ! -z "${HZN_ESS_AUTH:-}" ]; then
    USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
    PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")

    TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    HTTP_CODE=$(echo "${OBJECT}" | curl \
      -sSL \
      -X GET \
      -w '%{http_code}' \
      -o ${TEMP} \
      --cacert ${HZN_ESS_CERT} \
      -u "${USER}:${PSWD}" \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      --data @- \
      "$(ess_url)/objects/${objectType}/${objectID}")
    case ${HTTP_CODE} in
      200)
        hzn.log.debug "ess_object_status(): success; http_code: ${HTTP_CODE}"
        RESULT="$(cat ${TEMP})"
        ;;
      *)
        hzn.log.debug "ess_object_status(): failure; unexpected HTTP code: ${HTTP_CODE}"
	RESULT=
        ;;
    esac
    rm -f ${TEMP}
  fi
  echo "${RESULT}"
}

## lookup an object based on ID and Type
#
# Get the metadata of an object of the specified object type and object ID.
# The metadata indicates if the object includes data which can then be obtained using the appropriate API.
#
ess_object_lookup()
{
  hzn.log.trace "${FUNCNAME[0]}"

  objectID=${1}
  objectType="${2:-model}"
  hzn.log.debug "ess_object_lookup(): objectID: ${objectID}; objectType: ${objectType}"
  if [ ! -z "${HZN_ESS_AUTH:-}" ]; then
    USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
    PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")
    TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    HTTP_CODE=$(curl \
      -sSL \
      -X GET \
      -o ${TEMP} \
      -w '%{http_code}' \
      --cacert ${HZN_ESS_CERT} \
      -u "${USER}:${PSWD}" \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      "$(ess_url)/objects/${objectType}/${objectID}")
    case ${HTTP_CODE} in
      200)
        hzn.log.debug "ess_object_find(): success; http_code: ${HTTP_CODE}"
        RESULT="$(cat ${TEMP})"
        ;;
      400)
        hzn.log.debug "ess_object_find(): not found; ID: ${objectID}; type: ${objectType}"
        RESULT=
        ;;
      *)
        hzn.log.debug "ess_object_find(): failure; http_code: ${HTTP_CODE}"
        RESULT=
        ;;
    esac
    rm -f ${TEMP}
  fi
  echo "${RESULT}"
}

ess_object_create()
{
  hzn.log.trace "${FUNCNAME[0]}"

  objectID=${1:-none}
  objectType=${2:-blob}
  objectVersion=${3:-0.0.0}
  nodeID="${4:-${HZN_DEVICE_ID}}"
  nodeType="${5:-${HZN_PATTERN:-test}}"

  hzn.log.debug "ess_object_create(): objectID: ${objectID}; objectType: ${objectType}; objectVersion: ${objectVersion}"

  if [ ! -z "${HZN_ESS_AUTH:-}" ]; then
    USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
    PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")

    # object definition
    OBJECT=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    echo '{"data": [],"meta":{"objectID":"'${objectID}'","objectType": "'${objectType}'","destinationID":"'${nodeID}'","destinationType":"'${nodeType}'","version": "'${objectVersion}'", "description":"created at '$(date -u +%FT%TZ)'"}}' > ${OBJECT}
    hzn.log.debug "ess_object_create; object: " $(jq -c '.' ${OBJECT})

    TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    url="$(ess_url)/objects/${objectType}/${objectID}"

    HTTP_CODE=$(curl \
      -sSL \
      -o ${TEMP} \
      -X PUT \
      -w '%{http_code}' \
      -u "${USER}:${PSWD}" \
      --cacert ${HZN_ESS_CERT} \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      --data @${OBJECT} \
      "${url}")
    rm -f ${OBJECT}

    case ${HTTP_CODE} in
      204)
        hzn.log.debug "ess_object_create(): success; http_code: ${HTTP_CODE}"
        RESULT=true
        ;;
      500)
        hzn.log.warn "ess_object_create(): failed; http_code: ${HTTP_CODE}"
        ;;
      *)
        hzn.log.warn "ess_object_create(): unexpected failure; http_code: ${HTTP_CODE}"
        ;;
    esac
  fi
  echo "${RESULT}"
}

ess_object_update()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=false
  objectID=${1}
  objectType=${2}
  objectVersion=${3}

  hzn.log.debug "ess_object_update(): objectID: ${objectID}; objectType: ${objectType}; objectVersion: ${objectVersion}"

  object=$(ess_object_lookup ${objectID} ${objectType}) 
  if [ ! -z "${object:-}" ]; then
    hzn.log.debug "ess_object_update(); found; object: " $(echo "${object}" | jq -c '.')
    ver=$(echo "${object}" | jq -r '.version')
    if [ ! -z "${ver}" ]; then
      if [ "${ver}" = "${objectVersion}" ]; then
        has_data=$(echo "${object}" | jq '.data|length!=0')
        if [ "${has_data:-false}" = true ]; then
          hzn.log.debug "updating object with data; object: ${objectID}; type: ${objectType}; version: ${objectVersion}"
        fi
      fi
    fi
  else
    if [ $(ess_object_create ${objectID} ${objectType} ${objectVersion}) ]; then
      object=$(ess_object_lookup ${objectID} ${objectType}) 
    fi
  fi
  if [ ! -z "${object:-}" ]; then
    USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
    PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")

    object=$(echo "${object}" | jq '.version="'${objectVersion}'"')
    object=$(echo "${object}" | jq '.description="'$(date -u +%FT%TZ)'"')
    object=$(echo "${object}" | jq '.data=[]')

    TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    url="$(ess_url)/objects/${objectType}/${objectID}"
    OBJECT=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
    echo "${object}" > ${OBJECT}

    HTTP_CODE=$(curl \
      -sSL \
      -X PUT \
      -o ${TEMP} \
      -w '%{http_code}' \
      --cacert ${HZN_ESS_CERT} \
      -u "${USER}:${PSWD}" \
      --unix-socket ${HZN_ESS_API_ADDRESS} \
      --data @${OBJECT} \
      "${url}")
    rm -f ${OBJECT}
    case ${HTTP_CODE} in
      204)
        hzn.log.debug "ess_object_update(): success; http_code: ${HTTP_CODE}"
        RESULT="$(cat ${TEMP})"
        ;;
      *)
        hzn.log.debug "ess_object_update(): failure; http_code: ${HTTP_CODE}"
        ;;
    esac
    rm -f ${TEMP}
  else
    hzn.log.debug "ess_object_update(): no object: ${objectID}"
  fi
  echo "${RESULT}"
}

ess_object_data_put()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=false
  if [ ! -z "${1}" ] && [ ! -z "${2}" ] && [ ! -z "${3}" ] && [ ! -z "${4}" ]; then
    pn=${1}
    objectID=${2}
    objectType=${3}
    objectVersion=${4}
    hzn.log.debug "ess_object_data_put(): file: ${pn}; objectID: ${objectID}; objectType: ${objectType}; objectVersion: ${objectVersion}"

    USER=$(cat ${HZN_ESS_AUTH} | jq -r ".id")
    PSWD=$(cat ${HZN_ESS_AUTH} | jq -r ".token")

    if [ $(ess_object_update ${objectID} ${objectType} ${objectVersion}) ]; then
      # transmit data
      HTTP_CODE=$(curl \
        -sSL \
        -X PUT \
        -w '%{http_code}' \
        -u "${USER}:${PSWD}" \
        --header 'Content-Type:application/octet-stream' \
        --unix-socket ${HZN_ESS_API_ADDRESS} \
        --cacert ${HZN_ESS_CERT} \
        --data-binary @${pn} \
        "$(ess_url)/objects/${objectType}/${objectID}/data")
      case ${HTTP_CODE} in
        204)
          hzn.log.debug "ess_object_data_put(): success; http_code: ${HTTP_CODE}"
          RESULT=true
          ;;
        *)
          hzn.log.debug "ess_object_data_put(): failure; http_code: ${HTTP_CODE}"
          ;;
      esac
    else
      hzn.log.debug "ess_object_data_put(): failed to update object; ID: ${objectId}"
    fi
  fi
  echo "${RESULT}"
}

##
## OBJECT UPLOAD & DOWNLOAD
##

# returns true or false
ess_object_upload()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=false
  if [ ! -z "${1}" ] && [ -s "${1}" ] && [ ! -z "${2}" ] && [ ! -z "${3}" ]; then
    pn=${1}
    objectID=${2}
    objectVersion=${3}
    objectType=${4:-status}

    hzn.log.debug "ess_object_upload(): file: ${pn}; size: $(wc -c ${pn}); objectID: ${objectID}; objectType: ${objectType}; objectVersion: ${objectVersion}"

    if [ $(ess_object_update ${objectID} ${objectType} ${objectVersion}) ]; then
      if [ $(ess_object_data_put ${pn} ${objectID} ${objectType} ${objectVersion}) ]; then
        hzn.log.debug "ess_object_upload(): object data sent"
        RESULT=true
      else
        hzn.log.warn "ess_object_upload(): object data NOT sent"
      fi
    else
      hzn.log.warn "ess_object_upload(): object NOT updated"
    fi
  fi
  echo ${RESULT}
}

# returns a file pathname
ess_object_download()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ ! -z "${1}" ]; then
    objectID=${1}
    objectType=${2:-model}

    TEMP=$(ess_object_data_get ${objectID} ${objectType}) 
    if [ ! -z "${TEMP:-}" ] && [ -s "${TEMP}" ]; then
      hzn.log.debug "ess_object_download(): object retrieved: " $(wc -c ${TEMP})
      if [ $(ess_object_receipt ${objectID} ${objectType}) ]; then
        hzn.log.debug "ess_object_download(): object receipt sent"
      else
        hzn.log.warn "ess_object_download(): object data NOT retrieved"
      fi
    else
      hzn.log.warn "ess_object_download(): object NOT found"
    fi
  fi
  echo "${TEMP:-}"
}

###
### UPLOAD status & DOWNLOAD config
###

ess_status_upload()
{
  hzn.log.trace "${FUNCNAME[0]}"

  pn="${1}"
  RESULT=false
  if [ -s "${pn}" ]; then
    fn="${pn##*/}"
    objectID="${fn%%.*}"
    objectVersion="${fn##*.}"
    RESULT=$(ess_object_upload ${pn} ${objectID} ${objectVersion} "status")
  fi
  echo "${RESULT}"
}

ess_config_download()
{
  pn="${1}"
  RESULT=false
  if [ -s "${pn}" ]; then
    fn="${pn##*/}"
    objectID="${fn%%.*}"
    TEMP=$(ess_object_download ${objectID} "config")
    if [ ! -z "${TEMP:-}" ]; then 
      if [ -s ${TEMP} ]; then
        mv -f ${TEMP} ${pn} && RESULT=true;
      else
        hzn.log.warn "ess_config_download(): NOT found; object: ${fn}; type: config"
      fi
    fi
    rm -f ${TEMP}
  fi
  echo "${RESULT}"
}

###
### MODELS
###

## get model specified by /<path>/<objectID>.<objectVersion>
ess_model_download()
{
  hzn.log.trace "${FUNCNAME[0]}"

  RESULT=false
  if [ ! -z "${1}" ]; then
    pn="${1}"
    objectID="${pn##*/}" && objectID="${objectID%%.*}"
    TEMP=$(ess_object_download ${objectID} "model")
    if [ -s "${TEMP}" ]; then
      mv -f "${TEMP}" "${pn}" && RESULT=true
    else
      rm -f "${TEMP}"
    fi
  fi
  echo "${RESULT}"
}

## put model specified by /<path>/<objectID>.<objectVersion>
ess_model_feedback()
{
  hzn.log.trace "${FUNCNAME[0]}"

  if [ ! -z "${1}" ]; then
    pn="${1}"
    fn="${pn##*/}"
    objectID=${fn%%.*}
    objectVersion=${fn##*.} 

    RESULT=$(ess_object_upload ${pn} ${objectID} ${objectVersion} "model")
  fi
  echo "${RESULT}"
}
