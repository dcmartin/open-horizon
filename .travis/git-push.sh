#!/bin/bash
set -o errexit

### git-push.sh

if [ -z "${1:-}" ]; then
  echo "*** ERROR $0 $$ -- no branch specified" &> /dev/stderr
  exit 1
fi
BRANCH="${1}"

PULL_REQUEST=${2:=${TRAVIS_PULL_REQUEST}}

if [ ${PULL_REQUEST} = false ]; then
  REPO_SLUG=${TRAVIS_REPO_SLUG}
else
  REPO_SLUG=${TRAVIS_PULL_REQUEST_SLUG}
fi

if [ ${TRAVIS_PULL_REQUEST} = "true" ]; then 
case ${BRANCH} in
  master)
  	git config --global user.email "travis@travis-ci.org"
  	git config --global user.name "Travis-CI"
  	git remote add origin "https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"
  	git -a commit -m "merge beta" && git push origin master || exit 1
        git config credential.helper "store --file=.git/credentials"
        echo "https://${GH_TOKEN}:@github.com" > .git/credentials;
        git tag ${SERVICE_VERSION}
	;;
  beta)
    	git config --global user.email "travis@travis-ci.org"
	git config --global user.name "Travis-CI"
	git remote add origin "https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"
	git -a commit -m "merge exp" && git push origin beta || exit 1
	;;
  *)
	;;
esac
