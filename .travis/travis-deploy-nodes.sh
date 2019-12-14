#!/bin/bash
set -o errexit

###
### travis-deploy-nodes.sh
###
### This script deploys the pattern to designated test nodes
###

if [ ! -z "${TEST_NODE_NAMES}" ]; then
  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no environment variable: TEST_NODE_NAMES" &> /dev/stderr; fi
  if [ ! -s "${TEST_TMP_MACHINES}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no test device file: TEST_TMP_MACHINES; using default: localhost" &> /dev/stderr; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- test device file: TEST_TMP_MACHINES" &> /dev/stderr; fi
  fi
else
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- TEST_NODE_NAMES: ${TEST_NODE_NAMES}" &> /dev/stderr; fi
fi

${MAKE} nodes
