#!/bin/bash
set -o errexit

###
### registry-push-icr.sh
###
### This script pushes the services containers to the IBM Container Registry
###

case ${1} in 
  master)
	export DOCKER_LOGIN=token
	export DOCKER_REGISTRY=${ICR_REGISTRY}
	export DOCKER_NAMESPACE=${ICR_NAMESPACE}
	export DOCKER_PASSWORD=${ICR_PRIVATE}
	export DOCKER_PUBLICKEY=${ICR_PUBLIC}
	if [ ${DEBUG:-} = true ]; then echo "--- INFO -- $0 $$ -- login: ${DOCKER_LOGIN}; registry: ${DOCKER_REGISTRY}; namespace: ${DOCKER_NAMESPACE}" &> /dev/stderr; fi
	.travis/docker-login.sh
	${MAKE} publish-service
	${MAKE} pattern-publish
	;;
  beta)
	if [ ${DEBUG:-} = true ]; then echo "--- INFO -- $0 $$ -- BETA: no action" &> /dev/stderr; fi
	;;
  *)
	if [ ${DEBUG:-} = true ]; then echo "+++ WARN -- $0 $$ -- unknown: ${1}" &> /dev/stderr; fi
	;;
esac
