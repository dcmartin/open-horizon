#!/bin/bash

###
### THIS SCRIPT PROVIDES AUTOMATED DEPENDENCY FETCH
###
### THIS SCRIPT SHOULD __NOT__ BE CALLED INTERACTIVELY
###
### CONSUMES THE FOLLOWING ENVIRONMENT VARIABLES:
###
### + HZN_EXCHANGE_URL
### + HZN_ORG_ID
### + HZN_EXCHANGE_USERAUTH
###

# test envsubst
if [ -z $(command -v "envsubst") ]; then
  echo "*** ERROR -- $0 $$ -- please install gettext package for command envsubst" &> /dev/stderr
  exit 1
fi

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR -- $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
SERVICE="${DIR}/service.definition"
USERINPUT="${DIR}/userinput"

# mandatory
for json in ${SERVICE} ${USERINPUT}; do
if [ ! -s "${json}.json" ]; then echo "*** ERROR -- $0 $$ -- no ${json}.json" 2> /dev/stderr; exit 1; fi
done

# architecture
ARCH=$(jq -r '.arch' "${SERVICE}.json")

# environment
if [ -z "${HZN_EXCHANGE_URL:-}" ]; then
  echo "Error: no HZN_EXCHANGE_URL" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_EXCHANGE_USERAUTH:-}" ]; then
  echo "Error: no HZN_EXCHANGE_USERAUTH" &> /dev/stderr
  exit 1
fi
if [ -z "${HZN_ORG_ID:-}" ]; then
  echo "Error: no HZN_ORG_ID" &> /dev/stderr
  exit 1
fi

if [ $(jq '.requiredServices?!=null' "${SERVICE}.json") == 'true' ]; then
  jq -r '.requiredServices|to_entries[]|.value.url' "${SERVICE}.json" | while read -r; do
      URL="${REPLY}"
      if [ -z "${URL}" ]; then echo "Error: empty required service URL: ${URL}" &> /dev/stderr; exit 1; fi
      VER=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.version' "${SERVICE}.json")
      if [ -z "${VER}" ]; then echo "Error: empty version for required service ${URL}" &> /dev/stderr; exit 1; fi
      ORG=$(jq -r '.requiredServices|to_entries[]|select(.value.url=="'${URL}'").value.org' "${SERVICE}.json" | envsubst)
      if [ -z "${ORG}" ]; then echo "Error: empty org for required service ${URL}" &> /dev/stderr; exit 1; fi
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- directory: ${DIR}; version: ${VER}; architecture: ${ARCH}; organization: ${ORG}" &> /dev/stderr; fi

      ## check if local service or non
      if [ "${ORG}" == ${HZN_ORG_ID} ]; then
	REQDIR="${URL##*.}"
	if [ ! -z "${TAG}" ]; then REQDIR=$(echo "${REQDIR}" | sed "s/-${TAG}//"); fi
      fi
      if [ ! -z "${REQDIR:-}" ] && [ -d "../${REQDIR:-}/horizon" ]; then
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- found directory ${REQDIR}/horizon for ${ORG}/${ARCH}_${URL}:${VER}" &> /dev/stderr; fi
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- hzn dev dependency fetch -d ${DIR}/ -p ../${REQDIR}/horizon -u "${HZN_EXCHANGE_USERAUTH:1:3}"" &> /dev/stderr; fi
	hzn dev dependency fetch -d ${DIR}/ -p "../${REQDIR}/horizon" -u "${HZN_EXCHANGE_USERAUTH}" &> ${0##*/}.${ARCH}.${REQDIR}.out
        if [ $? != 0 ] || [ "${DEBUG:-}" == 'true' ]; then cat ${0##*/}.${ARCH}.${REQDIR}.out; fi
      else
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- retrieving from exchange: ${ORG}/${ARCH}_${URL}:${VER}" &> /dev/stderr; fi
	if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- hzn dev dependency fetch -d ${DIR}/ --ver ${VER} --arch ${ARCH} --org ${ORG} --url ${URL} -u ${HZN_EXCHANGE_USERAUTH:1:3}"; fi
	hzn dev dependency fetch -d ${DIR}/ --ver "${VER}" --arch "${ARCH}" --org "${ORG}" --url "${URL}" -u "${HZN_EXCHANGE_USERAUTH}" &> "${0##*/}.${ARCH}.${ORG}_${URL}_${VER}.out"
        if [ $? != 0 ] || [ "${DEBUG:-}" == 'true' ]; then cat "${0##*/}.${ARCH}.${ORG}_${URL}_${VER}.out"; fi
      fi
      if [ $? != 0 ]; then
	echo "*** ERROR -- $0 $$ -- dependency ${REPLY} was not fetched; exiting" &> /dev/stderr
	exit 1
      fi
  done
else
  if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- no required services" &> /dev/stderr; fi
fi
