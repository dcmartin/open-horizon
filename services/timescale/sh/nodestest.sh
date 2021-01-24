#!/bin/bash

source ${0%/*}/log-tools.sh

out=${1:-${0##*/}}.$$.json

begin=$(date +%s)
MAKE_MACHINES=$(${0%/*}/make-machines.sh)

if [ ! -z "${MAKE_MACHINES:-}" ]; then
  configured=$(echo "${MAKE_MACHINES}" | jq -r '.configured')
  OUTPUT=$(echo "${MAKE_MACHINES}" | jq -r '.output')

  if [ ! -z "${OUTPUT:-}" ] && [ -s "${OUTPUT}" ]; then
    responding=0
    BAD=$(jq -r '.bad[].machine' ${OUTPUT}) && BADARRAY=(${BAD}) && BADCOUNT=${#BADARRAY[@]}
    hzn.log.info "Configured count: ${configured}; bad count: ${BADCOUNT}"

    if [ ! -z "${BAD:-}" ]; then i=0; for bad in ${BAD}; do
        i=$((i+1))
        NODELIST=$(${0%/*}/ssh.sh ${bad} 'command -v "hzn" &> /dev/null && LANG=en_US.UTF-8 hzn node list || echo "{\"configstate\":{\"state\":\"not installed\"}}"')
        if [ ! -z "${NODELIST:-}" ]; then
          hzn.log.warn "${i}: ${bad}:" $(echo "${NODELIST}" | jq -r '.configstate.state') $(${0%/*}/ssh.sh ${bad} 'cat register.log')
        else
          hzn.log.error "${i}: ${bad}: unknown" $(${0%/*}/ssh.sh ${bad} 'cat register.log')
        fi
      done
    fi

    ## TESTING
    MAXITERATIONS=${MAXITERATIONS:-10}; testing=null; finish=$(date +%s); previous=0; i=0; responding=0; while [ ${responding} -lt ${configured} ] && [ ${i} -lt ${MAXITERATIONS} ]; do
      TEST_MACHINES=$(${0%/*}/test-machines.sh)
      if [ -z "${TEST_MACHINES:-}" ]; then
        hzn.log.error "No output from ${0%/*}/test-machines.sh"
	echo 'null'
        exit 1
      fi
      i=$((i+1))
      responding=$(echo "${TEST_MACHINES}" | jq -r '.responding')
      noresponse=$(echo "${TEST_MACHINES}" | jq -r '.noresponse')
      if [ ${previous:-0} -gt ${responding:-0} ]; then
	hzn.log.warn "nodes are dying"
      fi
      previous=${responding:-0}
      testing=$(echo "${testing}" | jq '.+=['"${TEST_MACHINES}"']')
      hzn.log.info "iteration ${i}; elapsed: $(($(date +%s)-begin)); ${responding} of ${configured}: $((responding*100/configured))%"
    done
    TEST_MACHINES='{"tests":'"${testing:-null}"',"seconds":'$(($(date +%s)-finish))'}'
  else
    hzn.log.error "*** No output found: ${OUTPUT}"
    echo 'null'
    exit 1
  fi
  if [ ${i:-0} -ge ${MAXITERATIONS} ]; then
    hzn.log.warn "+++ UNABLE to complete all nodes in ${i} iterations"
  fi
  CLEAN_MACHINES=$(${0%/*}/clean-machines.sh)
  remaining=$(${0%/*}/lsnodes.sh | jq -r '.nodes[].id' | egrep 'test-vm' | wc -l | awk '{ print $1 }') || remaining=0
  CLEAN_MACHINES=$(echo "${CLEAN_MACHINES}" | jq '.deleted='${remaining:-0})
  if [ ${remaining:-0}  -gt 0 ]; then
    hzn.log.warn "deleting ${remaining} nodes from exchange"
    ${0%/*}/delnodes.sh test-vm
  fi
else
  hzn.log.error "no output from ${0%/*}/make-machines.sh"
  echo 'null'
  exit 1
fi
echo '{"make":'"${MAKE_MACHINES}"',"test":'"${TEST_MACHINES}"',"clean":'"${CLEAN_MACHINES}"'}' | jq '.test.tests[].missing=null' | tee ${out}

# make
#MAKEOUT=$(jq -c '.|select(.bad|length>0).bad[]' $(jq -r '.make.output' ${out}) | jq --slurp -c '.')
#jq '.make.output='"${MAKEOUT}" ${out} > ${out}.$$ && mv -f ${out}.$$ ${out}
# test
#TESTOUT=$(for output in $(jq -r '.test.tests[].output' ${out}); do jq '.|select(.bad|length>0).bad[]' ${output} | jq --slurp -c '{"'${output}'":.}'; done | jq --slurp -c '.')
#jq '.test.output='"${TESTOUT}" ${out} > ${out}.$$ && mv -f ${out}.$$ ${out}
