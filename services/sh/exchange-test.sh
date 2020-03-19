#!/bin/bash

###
### THIS SCRIPT PROVIDES METHODS TO INTERACT WITH THE EXCHANGE
###
### IT SHOULD __NOT__ BE CALLED INTERACTIVELY
###

if [ -z "${HZN_EXCHANGE_URL}" ]; then export HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"; fi
if [ ! -s "APIKEY" ]; then 
  if [ -s "../apiKey.json" ]; then 
    jq -r '.apiKey' "../apiKey.json" > APIKEY
  else 
    echo "+++ WARN -- $0 $$ -- no apiKey.json" &> /dev/stderr
  fi
else
    echo "--- INFO -- $0 $$ -- APIKEY found" &> /dev/stderr
fi

###
### EXCHANGE
###

hzn_exchange()
{
  ITEM="${1}"
  ITEMS='null'
  if [ ! -z "${ITEM}" ]; then
    URL="${HZN_EXCHANGE_URL}/orgs/${SERVICE_ORG}/${ITEM}"
    ALL=$(curl -fsSL -u "${SERVICE_ORG}/${HZN_USER_ID:-iamapikey}:$(cat APIKEY)" "${URL}")
    ENTITYS=$(echo "${ALL}" | jq '{"'${ITEM}'":[.'${ITEM}'| objects | keys[]] | unique}' | jq -r '.'${ITEM}'[]') 
    ITEMS='{"'${ITEM}'":['
    i=0; for ENTITY in ${ENTITYS}; do 
      if [[ $i > 0 ]]; then ITEMS="${ITEMS}"','; fi
      ITEMS="${ITEMS}"$(echo "${ALL}" | jq '.'${ITEM}'."'"${ENTITY}"'"' | jq -c '.id="'"${ENTITY}"'"')
      i=$((i+1))
    done
    ITEMS="${ITEMS}"']}'
  fi
  echo "${ITEMS}"
}

exchange_service_images()
{
  echo $(exchange_services | jq '[.services[]|{"label":.label,"id":.id,"image":(.deployment|fromjson|.services|to_entries[].value.image)}]')
}

exchange_service_delete()
{
  ID="${1}"
  SO=
  STATUS=1
  if [ "${ID}" != "${ID##*/}" ]; then SO="${ID%/*}"; ID=${ID##*/}; echo "+++ WARN $0 $$ -- organization ${SO}; service identifier: ${ID}" &> /dev/stderr; else SO="${SERVICE_ORG}"; fi
  URL="${HZN_EXCHANGE_URL}/orgs/${SO}/services/${ID}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- DELETE ${ID} from ${SO}" &> /dev/stderr; DRY_RUN='--dry-run'; fi
  RESULT=$(curl -fsSL -X DELETE -u "${SO}/${HZN_USER_ID:-iamapikey}:$(cat APIKEY)" "${URL}")
  STATUS=$?
  echo "${STATUS}"
}

exchange_services() {
  if [ -z "${EXCHANGE_SERVICES:-}" ]; then EXCHANGE_SERVICES=$(hzn_exchange services); fi
  echo "${EXCHANGE_SERVICES}"
}

exchange_patterns() {
  if [ -z "${EXCHANGE_PATTERNS:-}" ]; then EXCHANGE_PATTERNS=$(hzn_exchange patterns); fi
  echo "${EXCHANGE_PATTERNS}"
}

find_service_in_exchange() {
  id="${1}"
  RESULT=$(exchange_services | jq '.services[]|select(.id=="'${id}'")')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- find_service_in_exchange ${service}; result (label):" $(echo "${RESULT}" | jq -c '.label') &> /dev/stderr; fi
  echo "${RESULT}"
}

find_pattern_in_exchange() {
  id="${1}"
  RESULT=$(exchange_patterns | jq '.patterns[]|select(.id=="'${id}'")')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- find_pattern_in_exchange ${pattern}; result (label):" $(echo "${RESULT}" | jq -c '.label') &> /dev/stderr; fi
  echo "${RESULT}"
}

is_service_in_exchange() {
  service="${1}"
  RESULT=$(find_service_in_exchange ${service})
  if [ -z "${RESULT}" ]; then RESULT='false'; else RESULT='true'; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- is_service_in_exchange ${service}; result: ${RESULT}" &> /dev/stderr; fi
  echo "${RESULT}"
}

is_pattern_in_exchange() {
  pattern="${1}"
  RESULT=$(find_pattern_in_exchange ${pattern})
  if [ -z "${RESULT}" ]; then RESULT='false'; else RESULT='true'; fi
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- is_pattern_in_exchange ${pattern}; result: ${RESULT}" &> /dev/stderr; fi
  echo "${RESULT}"
}

###
### SERVICES
###

read_service_file() {
  jq -c '.' "${SERVICE_FILE}"
}

get_required_service_ids() {
  echo $(echo "${*}" | jq -j '.requiredServices[]|.org,"/",.url,"_",.version,"_",.arch," "')
}

is_image_in_registry() {
  service="${1}"
  IMAGE=$(echo "${SERVICES}" | jq -r '.[]|select(.id=="'${service}'").image')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- is_image_in_registry ${service}; image: ${IMAGE}" &> /dev/stderr; fi
  docker pull "${IMAGE}" &> /dev/null && STATUS=$?
  docker rmi "${IMAGE}" &> /dev/null
  if [ $STATUS == 0 ]; then echo 'true'; else echo 'false'; fi
}

test_service_arch_support () {
  RESULT='true'
  for arch in ${ARCH_SUPPORT}; do
    sid="${SERVICE_ORG}/${SERVICE_URL}_${SERVICE_VER}_${arch}"
    if [ $(is_service_in_exchange "${sid}") != 'true' ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- service ${sid} is NOT in exchange" &> /dev/stderr; fi
      RESULT='false'
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- service ${sid} is FOUND in exchange" &> /dev/stderr; fi
    fi
  done
  echo "${RESULT}"
}

## test if all services have images in registry
test_service_images() {
  SERVICES=$(jq '[.deployment.services|to_entries[]|{"id":.key,"image":.value.image}]' "${SERVICE_FILE}")
  for service in $(echo "${SERVICES}" | jq -r '.[].id'); do
    if [ "{DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- checking registry for service ${service}" &> /dev/stderr; fi
    RESPONSE=$(is_image_in_registry "${service}")
    if [ "${RESPONSE}" == 'true' ]; then
      if [ "{DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found image ${IMAGE} in registry; status: ${RESPONSE}" &> /dev/stderr; fi
    else
      RESPONSE=false
      if [ "{DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- no existing image ${IMAGE} in registry; status: ${RESPONSE}" &> /dev/stderr; fi
    fi
    echo "${RESPONSE}"
  done
  echo "${RESPONSE}"
}

semver_gt() {
  RESULT='false'
  ev1="${1%%.*}"
  ev2="${1%.*}" && ev2=${ev2##*.}
  ev3="${1##*.}"
  nv1="${2%%.*}"
  nv2="${2%.*}" && nv2=${nv2##*.}
  nv3="${2##*.}"
  if [ ${ev1} -gt ${nv1} ]; then RESULT='true'; fi
  if [ ${ev1} -ge ${nv1} ] && [ ${ev2} -gt ${nv2} ]; then RESULT='true'; fi
  if [ ${ev1} -ge ${nv1} ] && [ ${ev2} -ge ${nv2} ] && [ ${ev3} -gt ${nv3} ]; then RESULT='true'; fi
  echo "${RESULT}" 
}

## service_test
service_test() {
  id="${1}"
  STATUS=0
  RESULT=$(is_service_in_exchange "${id}") 
  if [ "${RESULT}" != 'true' ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- no existing service ${id} in exchange; status: ${RESULT}" &> /dev/stderr; fi
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found service ${id} in exchange; status: ${RESULT}" &> /dev/stderr; fi
  fi
  rsids=$(get_required_service_ids $(read_service_file))
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found required services ids: ${rsids}" &> /dev/stderr; fi
  if [ ! -z "${rsids}" ]; then
    for RS in ${rsids}; do
      version=$(echo "${RS}" | sed 's|.*/.*_\(.*\)_.*|\1|')
      if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- checking required service: ${RS}; version ${version}" &> /dev/stderr; fi
      if [ $(is_service_in_exchange "${RS}") != 'true' ]; then
	STATUS=1
	if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- no existing service ${RS} in exchange; status: ${STATUS}" &> /dev/stderr; fi
      else
        rsie=$(find_service_in_exchange "${RS}")
	url=$(echo "${rsie}" | jq -r '.url')
	arch=$(echo "${rsie}" | jq -r '.arch')

	for ver in $(exchange_services | jq -r '.services[]|select((.url=="'${url}'") and (.arch=="'${arch}'"))|.version'); do
	  if [ $(semver_gt "${ver}" "${version}") == 'true' ]; then
	    STATUS=1
	    if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- NEWER: exchange: ${ver}; service: ${version}; url: ${url}; arch: ${arch}; status: ${STATUS}" &> /dev/stderr; fi
          fi 
	done
      fi
    done
  else
    echo "--- INFO -- $0 $$ -- no required services found in service JSON" &> /dev/stderr
  fi
  echo "${STATUS}"
}

###
### PATTERN
###

read_pattern_file() {
  jq -c '.' "${PATTERN_FILE}"
}

get_pattern_service_ids() {
  echo $(echo "${*}" | jq -j '.services[]|.serviceOrgid,"/",.serviceUrl,"_",.serviceVersions[].version,"_",.serviceArch," "')
}

get_pattern_file_services() {
  echo $(jq -j '.services[]|.serviceOrgid,"/",.serviceUrl,"_",.serviceVersions[].version,"_",.serviceArch," "' "${1}")
}

pattern_services_in_exchange() {
  pattern_services="${*}"
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- pattern services: ${pattern_services}" &> /dev/stderr; fi
  RESPONSE='true'
  if [ ! -z "${pattern_services}" ]; then
    for PS in ${pattern_services}; do
      if [ $(is_service_in_exchange "${PS}") != 'true' ]; then
        RESPONSE='false'
	if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- no existing service ${PS} in exchange; status: ${RESPONSE}" &> /dev/stderr; fi
      else
	if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found service ${PS} in exchange; status: ${RESPONSE}" &> /dev/stderr; fi
      fi
    done
  else
    echo "--- INFO -- $0 $$ -- no services found in pattern JSON" &> /dev/stderr
  fi
  echo "${RESPONSE}"
}

## pattern_test
pattern_test() {
  id="${1}"
  STATUS=0
  ## test if all services for pattern exist
  RESULT=$(pattern_services_in_exchange $(get_pattern_service_ids $(read_pattern_file)))
  if [ "${RESULT}" != 'true' ]; then
    if [ "${DEBUG:-}" == 'true' ]; then echo "*** ERROR -- $0 $$ -- pattern ${id}: some exchange services are MISSING" &> /dev/stderr; fi
    STATUS=1
  else
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- pattern ${id}: all exchange services are AVAILABLE" &> /dev/stderr; fi
    ## test if pattern exists
    RESULT=$(is_pattern_in_exchange "${id}")
    if [ "${RESULT}" == 'true' ]; then
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- pattern ${id}: EXISTS in exchange; checking services..." &> /dev/stderr; fi
      sipf=$(get_pattern_service_ids $(read_pattern_file))
      siex=$(get_pattern_service_ids $(find_pattern_in_exchange "${id}"))
      for sp in ${sipf}; do
	match=false
	for xp in ${siex}; do
	  if [ "${sp}" == "${xp}" ]; then match=true; break; fi
	done
	if [ "${match}" != 'true' ]; then break; fi
      done
      if [ "${match}" == 'true' ]; then 
	echo "*** ERROR -- $0 $$ -- pattern: ${id}: services: NO change" &> /dev/stderr
	STATUS=1
      else
	echo "--- WARN -- $0 $$ -- pattern: ${id}: services: CHANGED" &> /dev/stderr
      fi
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- pattern ${id}: AVAILABLE in exchange" &> /dev/stderr; fi
    fi
  fi
  echo "${STATUS}"
}

service_clean_all ()
{
  STATUS=0
  SERVICES=$(exchange_services | jq -r '.services[].label' | sort | uniq)
  for S in ${SERVICES}; do
    service_clean "${S}"
  done
  echo "${STATUS}"
}

service_clean ()
{
  label="${1}"
  echo "--- INFO -- $0 $$ -- cleaning ${SERVICE_LABEL}" &> /dev/stderr
  STATUS=0
  SERVICES=$(exchange_services | jq '[.services[]|select(.label=="'"${label}"'")]')
  if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found services: " $(echo "${SERVICES}" | jq '.|length') &> /dev/stderr; fi
  if [ "${SERVICES}" != '[]' ]; then
    URLS=$(echo "${SERVICES}" | jq -r '.[].url' | sort | uniq)
    for U in ${URLS}; do
      ARCHS=$(echo "${SERVICES}" | jq -r '.[].arch' | sort | uniq)
      for A in ${ARCHS}; do
	MAX=
        VERSIONS=$(echo "${SERVICES}" | jq -r '.[].version' | sort | uniq)
        if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- versions:" $(echo "${VERSIONS}" | fmt) &> /dev/stderr; fi
        for V in ${VERSIONS}; do
          if [ -z "${MAX:-}" ]; then MAX=${V}; else if [ $(semver_gt "${V}" "${MAX}") == 'true' ]; then MAX="${V}"; fi; fi
        done
        if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ${U} and ${A}: maximum ${MAX}" &> /dev/stderr; fi
        IDS=$(echo "${SERVICES}" | jq -r '.[]|select((.arch=="'${A}'") and (.url=="'${U}'"))|.id')
        for ID in ${IDS}; do
          if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- ID: ${ID}" &> /dev/stderr; fi
          SVC=$(echo "${SERVICES}" | jq '.[]|select(.id=="'${ID}'")')
          VER=$(echo "${SVC}" | jq -r '.version')
          if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- VER: ${VER}" &> /dev/stderr; fi
          if [ $(semver_gt "${MAX}" "${VER}") == 'true' ]; then
            echo "+++ WARN -- $0 $$ -- service ${ID} is out-of-date; cleaning" &> /dev/stderr
	    STATUS=$(exchange_service_delete "${ID}")
            if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- DELETE status: ${STATUS}" &> /dev/stderr; fi
          fi
        done
      done
    done
  fi
  echo "${STATUS}"
}

###
### MAIN
###

## get name of script
SCRIPT_NAME="${0##*/}" && SCRIPT_NAME="${SCRIPT_NAME%.*}"

STATUS=1
EXCHANGE_SERVICES=
EXCHANGE_PATTERNS=
PATTERN_SERVICES=

case ${SCRIPT_NAME} in 
  exchange-*)
    case ${SCRIPT_NAME} in
      exchange-service-delete)
	SERVICE_ID="${1}"
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- deleting service ${SERVICE_ID}" &> /dev/stderr; fi
	STATUS=$(exchange_service_delete "${SERVICE_ID}")
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- status ${STATUS}" &> /dev/stderr; fi
	;;
      exchange-service-list)
	if [ -z "${SERVICE_FILE:-}" ]; then SERVICE_ORG="${HZN_ORG_ID:-}"; else SERVICE_ORG=$(jq -r '.org' "${SERVICE_FILE}"); fi
        if [ -z "${SERVICE_ORG}" ]; then echo "*** ERROR -- $0 $$ -- service organization unknown; set HZN_ORG_ID; exiting" &> /dev/stderr; exit 1; fi
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- listing services in ${SERVICE_ORG}" &> /dev/stderr; fi
	SERVICES=$(exchange_services | jq '.services')
        if [ "${DEBUG:-}" == 'true' ]; then echo "??? DEBUG -- $0 $$ -- found services: " $(echo "${SERVICES}" | jq '.|length') &> /dev/stderr; fi
	LABELS=$(echo "${SERVICES}" | jq -r '.[].label' | sort | uniq)
	OUT='{"services":['
	for LABEL in ${LABELS}; do
	  if [ ! -z "${LOUT}" ]; then LOUT="${LOUT}"','; fi
	  LOUT="${LOUT}"'{"label":"'${LABEL}'","containers":['
          SIDS=$(echo "${SERVICES}" | jq -r '.[]|select(.label=="'${LABEL}'").id')
          for SID in ${SIDS}; do
	    if [ ! -z "${SOUT}" ]; then SOUT="${SOUT}"','; fi
	    IMAGE=$(echo "${SERVICES}" | jq -r '.[]|select(.id=="'${SID}'").deployment|fromjson|.services|to_entries[].value.image')
            SOUT="${SOUT}"'{"id":"'${SID}'","image":"'${IMAGE}'"}'
          done
          LOUT="${LOUT}""${SOUT}"']}'
	  SOUT=
	done
        OUT="${OUT}""${LOUT}"']}'
        echo "${OUT}" | jq
	STATUS=$?
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- status ${STATUS}" &> /dev/stderr; fi
	;;
      *)
        if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- invalid exchange script: ${SCRIPT_NAME}" &> /dev/stderr; fi
        ;;
    esac
    ;;
  *)
    BUILD_FILE="build.json"
    if [ ! -s "${BUILD_FILE}" ]; then echo "*** ERROR -- $0 $$ -- build JSON ${BUILD_FILE} not found; exiting" &> /dev/stderr; exit 1; fi
    ARCH_SUPPORT=$(jq -r '.build_from|to_entries[].key' "${BUILD_FILE}")
    DIR="${1}"
    if [ -z "${DIR}" ]; then DIR="horizon"; echo "--- INFO -- $0 $$ -- directory not specified; using ${DIR}" &> /dev/stderr; fi
    if [ ! -d "${DIR}" ]; then echo "*** ERROR -- $0 $$ -- cannot find directory ${DIR}" &> /dev/stderr; exit 1; fi
    SERVICE_FILE="${2}"
    if [ -z "${SERVICE_FILE}" ]; then SERVICE_FILE="${DIR}/service.definition.json"; echo "--- INFO -- $0 $$ -- service JSON not specified; using ${SERVICE_FILE}" &> /dev/stderr; fi
    SERVICE_ORG=$(jq -r '.org' "${SERVICE_FILE}")
    case ${SCRIPT_NAME} in
      pattern-test)
	PATTERN_FILE="${3}"
	if [ -z "${PATTERN_FILE}" ]; then PATTERN_FILE="${DIR}/pattern.json"; echo "--- INFO -- $0 $$ -- pattern JSON not specified; using ${PATTERN_FILE}" &> /dev/stderr; fi
	if [ -s "${PATTERN_FILE}" ]; then
	  PATTERN_LABEL=$(read_pattern_file | jq -r '.label')
	  ID="${SERVICE_ORG}/${PATTERN_LABEL}"
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- testing pattern ${ID}" &> /dev/stderr; fi
	  STATUS=$(pattern_test "${ID}")
	else
	  STATUS=0
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- no pattern: ${PATTERN_FILE}; status: ${STATUS}" &> /dev/stderr; fi
	fi
	;;
      service-*) 
	if [ -s "${SERVICE_FILE}" ]; then
	  SERVICE_LABEL=$(read_service_file | jq -r '.label')
	  SERVICE_ARCH=$(read_service_file | jq -r '.arch')
	  SERVICE_URL=$(read_service_file | jq -r '.url')
	  SERVICE_VER=$(read_service_file | jq -r '.version')
	  ID="${SERVICE_ORG}/${SERVICE_URL}_${SERVICE_VER}_${SERVICE_ARCH}"
	else
	  STATUS=0
	  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- no service: ${SERVICE_FILE}; status: ${STATUS}" &> /dev/stderr; fi
	fi
	case ${SCRIPT_NAME} in
	  service-test)
	    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- testing service ${ID}" &> /dev/stderr; fi
	    STATUS=$(service_test "${ID}")
	    ;;
	  service-clean)
	    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- cleaning service ${SERVICE_LABEL}" &> /dev/stderr; fi
	    STATUS=$(service_clean "${SERVICE_LABEL}")
	    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- status ${STATUS}" &> /dev/stderr; fi
	    ;;
	  *)
	    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- invalid service script: ${SCRIPT_NAME}" &> /dev/stderr; fi
	    ;;
	esac
	;;
      *)
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- invalid script: ${SCRIPT_NAME}" &> /dev/stderr; fi
	;;
    esac
    ;;
esac

exit ${STATUS}
