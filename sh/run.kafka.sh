#!/bin/bash

zookeeper_start()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "${FUNCNAME[0]} ${*}" &> /dev/stderr; fi
  local result

  docker stop zookeeper &> /dev/null
  docker rm zookeeper &> /dev/null
  docker volume create zookeeper_data &> /dev/null
  result=$(docker run -d \
	--name zookeeper \
	--network host \
	-p ${ZOOKEEPER_PORT}:2181 \
	-v zookeeper_data:/binami \
	-e ALLOW_ANONYMOUS_LOGIN=yes \
	--restart unless-stopped 'bitnami/zookeeper:3' 2> /dev/null)
  echo ${result:-null}
}

kafka_start()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "${FUNCNAME[0]} ${*}" &> /dev/stderr; fi
  local result
  local cid

  docker stop kafka &> /dev/null
  docker rm kafka &> /dev/null
  docker volume create kafka_data &> /dev/null
  result=$(docker run -d \
	--name kafka \
	--network host \
	-p ${KAFKA_PORT}:9092 \
	-v kafka_data:/binami \
	-e KAFKA_CFG_ZOOKEEPER_CONNECT=${ZOOKEEPER_HOST}:${ZOOKEEPER_PORT} \
	-e ALLOW_PLAINTEXT_LISTENER=yes \
	--restart unless-stopped 'bitnami/kafka:2' 2> /dev/null)
  echo ${result:-null}
}

start()
{
  if [ "${DEBUG:-false}" = 'true' ]; then echo "${FUNCNAME[0]} ${*}" &> /dev/stderr; fi
  local result
  local zcid
  local kcid

  zcid=$(zookeeper_start)
  if [ ${zcid} != 'null' ]; then
    kcid=$(kafka_start)
    if [ ${kcid} = 'null' ]; then
      docker rm -f ${zcid} &> /dev/null
      zcid=
    fi
  fi
  if [ ${zcid:-null} = 'null' ] || [ ${kcid}  != 'null' ]; then
    result='[{"name":"kafka","id":"'${kcid}'","port":"'${KAFKA_PORT}'"},{"name":"zookeeper","id":"'${zcid}'","host":"'${ZOOKEEPER_HOST}'","port":"'${ZOOKEEPER_PORT}'"}]'
  fi
  echo ${result:-null}
}

###
### main
###

## KAFKA
if [ -z "${KAFKA_PORT:-}" ] && [ -s KAFKA_PORT ]; then KAFKA_PORT=$(cat KAFKA_PORT); fi; KAFKA_PORT=${KAFKA_PORT:-9092}
if [ -z "${ZOOKEEPER_PORT:-}" ] && [ -s ZOOKEEPER_PORT ]; then ZOOKEEPER_PORT=$(cat ZOOKEEPER_PORT); fi; ZOOKEEPER_PORT=${ZOOKEEPER_PORT:-2181}
if [ -z "${ZOOKEEPER_HOST:-}" ] && [ -s ZOOKEEPER_HOST ]; then ZOOKEEPER_HOST=$(cat ZOOKEEPER_HOST); fi; ZOOKEEPER_HOST=${ZOOKEEPER_HOST:-127.0.0.1}

if [ $(uname -m) != 'x86_64' ]; then
  echo "Unsupported architecture: $(uname -m)" &> /dev/stderr
else
  result=$(start)
  if [ "${result:-null}" = 'null' ]; then
     echo "Failed to start Kafka" &> /dev/stderr
  fi
  echo "${result:-null}"
fi
