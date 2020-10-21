#!/bin/bash

build_ess()
{
  local arch=${1}
  local dir=${2}/src/github.com/open-horizon/edge-sync-service 
  local build=${dir}/build
  local BUILD_OUTPUT=${build}/edge-sync-service

  case ${arch} in
    amd64)
      PLATFORM="GOARCH=amd64"
      ;;
    armhf)
      PLATFORM="GOARCH=arm GOARM=7"
      ;;
    arm64)
      PLATFORM="GOARCH=arm64"
      ;;
    *)
      echo "An invalid platform was specified: ${arch}"
      return
      ;;
  esac

  pushd ${dir} &> /dev/stderr
  mkdir -p ${build}
  rm -f ${BUILD_OUTPUT}
  env \
    "PATH=$PATH" \
    "GOPATH=$GOPATH" \
    GOOS=linux \
    ${PLATFORM} \
    CGO_ENABLED=0 \
    go build \
      -o ${BUILD_OUTPUT} \
     github.com/open-horizon/edge-sync-service/cmd/edge-sync-service

  docker build -t ${DOCKER_NAMESPACE:-${USER}}/edge-sync-service -f image/edge-sync-service-${arch}/Dockerfile .

  popd &> /dev/stderr
}

get_ess()
{
   local dir=${1:-/tmp/ess)}
}

###
### MAIN
###

ARCH=${1:-$(uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/')}
DIR='/tmp/edge-sync-service'

sudo apt install -qq -y golang

export GOPATH=${DIR}

mkdir -p ${DIR}
cd ${DIR} && go get -d github.com/open-horizon/edge-sync-service
cd ${DIR}/src/github.com/open-horizon/edge-sync-service && ./get_dependencies.sh
cd ${DIR} && go install github.com/open-horizon/edge-sync-service/cmd/edge-sync-service

build_ess ${ARCH} ${DIR}

docker push ${DOCKER_NAMESPACE:-${USER:-$(whoami)}}/edge-sync-service
