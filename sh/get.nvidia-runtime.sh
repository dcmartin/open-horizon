#!/bin/bash

get_nvidia_keys()
{
  if [ "${DEBUG:-false}" = true ]; then echo "${FUNCNAME[0]}" &> /dev/stderr; fi

  local distribution=${1}

  curl -sSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - &> /dev/null
  curl -sSL https://nvidia.github.io/nvidia-docker/${distribution}/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list &> /dev/null
}

get_nvidia_runtime()
{
  if [ "${DEBUG:-false}" = true ]; then echo "${FUNCNAME[0]}" &> /dev/stderr; fi

  local distribution=$(. /etc/os-release ; echo "${ID}${VERSION_ID}")
  local result

  get_nvidia_keys ${distribution} &> /dev/null
  apt update -qq -y &> /dev/null
  apt install -qq -y nvidia-container-toolkit &> /dev/null

  echo ${result:-true}
}

set_nvidia_runtime()
{
  if [ "${DEBUG:-false}" = true ]; then echo "${FUNCNAME[0]}" &> /dev/stderr; fi

  local json=${1:-/etc/docker/daemon.json}
  local result

  rm -f ${json}
  echo '{"default-runtime":"nvidia","runtimes":{"nvidia":{"path":"nvidia-container-runtime","runtimeArgs":[]}}}' > ${json}

  if [ -s ${json} ]; then
    result=true
  fi

  echo ${result:-false}
}

###
### main
###

if [ "${USER:-}" != 'root' ]; then
  echo "Run as root: ${0} ${*}" &> /dev/stderr
  exit 1
fi

if [ -z "$(command -v curl)" ]; then
  echo "Installing curl" &> /dev/stderr
  apt install -qq -y curl &> /dev/stderr
fi

if [ $(get_nvidia_runtime) != true ]; then
  echo "Failed to get nVidia runtime" &> /dev/stderr
elif [ $(set_nvidia_runtime) != true ]; then
  echo "Failed to set nVidia runtime" &> /dev/stderr
else
  systemctl restart docker
  echo "SUCCESS" &> /dev/stderr
fi
