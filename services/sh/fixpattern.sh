#!/bin/bash

###
### THIS SCRIPT FIXES PATTERN SPECIFICATIONS WHEN TAG IS SPECIFIED
###
### IT SHOULD __NOT__ BE CALLED INTERACTIVELY
###

# where
if [ -z "${1}" ]; then DIR="horizon"; else DIR="${1}"; fi
if [ ! -d "${DIR}" ]; then
  echo "*** ERROR -- $0 $$ -- no directory ${DIR}" &> /dev/stderr
  exit 1
fi

# what
PATTERN="pattern.json"
if [ -s "${PATTERN}" ]; then
  # use pattern label as service identifier
  PATTERN_LABEL=$(jq -r '.label' "${PATTERN}")
  # tagging
  if [ ! -z "${TAG:-}" ]; then
    jq -c '.label="'${PATTERN_LABEL}-${TAG}'"|.services=[.services[]|.serviceUrl as $url|.serviceUrl=$url+"-'${TAG}'"]' "${PATTERN}" > "${PATTERN}.$$"
    mv -f "${PATTERN}.$$" "${DIR}/${PATTERN}"
  else
    cat "${PATTERN}" | envsubst > "${DIR}/${PATTERN}"
  fi
else
  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- cannot find pattern JSON template: ${PATTERN}" &> /dev/stderr; fi
fi
