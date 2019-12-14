#!/bin/bash
set -o errexit

if [ ${TRAVIS_PULL_REQUEST:-} = false ]; then 
  # login docker
  echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_LOGIN} --password-stdin
fi
