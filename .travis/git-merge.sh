#!/bin/bash
set -o errexit

###
### git-merge.sh
###
### This script pulls the proper parent
###

if [ ! -z "${1}" ]; then
  TPR="${1}"
else
  TPR=${TRAVIS_PULL_REQUEST:-false} 
fi

if [ "${TPR}" = true ];  then
  # get repo
  REPO_SLUG=${TRAVIS_PULL_REQUEST_SLUG:-none}
  # get branch
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-none}
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- pull request; branch: ${BRANCH:-none} to branch: ${TRAVIS_BRANCH:-none}" &> /dev/stderr; fi
  # test for master
  case ${BRANCH} in
    master)
	git merge beta
	;;
    beta)
	git merge exp
	;;
    *)
	echo "+++ WARN -- $0 $$ -- branch in invalid: ${BRANCH}" &> /dev/stderr
	;;
  esac
else
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- non-pull request; branch: ${TRAVIS_BRANCH:-none}" &> /dev/stderr; fi
fi
