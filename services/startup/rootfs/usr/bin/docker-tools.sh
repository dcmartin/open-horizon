#!/usr/bin/env bash

source /usr/bin/hzn-tools.sh

## docker container functions
docker_container_list()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL --unix-socket /var/run/docker.sock http://localhost/containers/json)
}

docker_container_inspect()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL --unix-socket /var/run/docker.sock http://localhost/containers/${1}/json)
}

docker_container_top()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL --unix-socket /var/run/docker.sock http://localhost/containers/${1}/top)
}

docker_container_logs()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL --unix-socket /var/run/docker.sock http://localhost/containers/${1}/logs)
}

docker_container_changes()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL --unix-socket /var/run/docker.sock http://localhost/containers/${1}/changes)
}

docker_container_stats()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL --unix-socket /var/run/docker.sock http://localhost/containers/${1}/stats?stream=false)
}

docker_container_create()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  echo $(curl -sSL -X POST --unix-socket /var/run/docker.sock -d '{"Image":"'${1}'"}' -H 'Content-Type: application/json' http://localhost/containers/create)
}

## composite docker status
docker_status()
{
  hzn.log.trace "${FUNCNAME[0}"
 
  # create ouput
  TEMP=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  docker_container_list | jq -r '.[].Id' | while read id; do
    # start JSON
    if [ ! -s ${TEMP} ]; then echo '{"containers":[' > ${TEMP}; else echo ',' >> ${TEMP}; fi
    echo '{"id":"'${id}'"' >> ${TEMP}
    # top
    OUT=$(docker_container_top ${id} | jq -c '.')
    if [ ! -z "${OUT}" ]; then
      echo ',' >> ${TEMP}
      echo '"top":'"${OUT}" >> ${TEMP}
    fi
    # inspect
    OUT=$(docker_container_inspect ${id} | jq -c '.')
    if [ ! -z "${OUT}" ]; then
      echo ',' >> ${TEMP}
      echo '"inspect":'"${OUT}" >> ${TEMP}
    fi
    # logs
    OUT=$(docker_container_logs ${id} | jq -c '.')
    if [ ! -z "${OUT}" ]; then
      echo ',' >> ${TEMP}
      echo '"logs":'"${OUT}" >> ${TEMP}
    fi
    # changes
    OUT=$(docker_container_changes ${id} | jq -c '.')
    if [ ! -z "${OUT}" ]; then
      echo ',' >> ${TEMP}
      echo '"changes":'"${OUT}" >> ${TEMP}
    fi
    # stats
    OUT=$(docker_container_stats ${id} | jq -c '.')
    if [ ! -z "${OUT}" ]; then
      echo ',' >> ${TEMP}
      echo '"stats":'"${OUT}" >> ${TEMP}
    fi
    echo '}' >> ${TEMP}
  done
  if [ -s ${TEMP} ]; then echo ']}' >> ${TEMP}; else echo 'null' > ${TEMP}; fi
  echo $(cat ${TEMP})
  rm -f ${TEMP}
}

