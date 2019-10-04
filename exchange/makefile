###
### make(1) file for using Docker to start Open Horizon
###
### Uses the default `docker-compose.yml` file in current directory
###

##
## TARGETS:
##

# up - perform `docker-compose up -d`
# down - perform `docker-compose down`
# clean - stop and clean
# 

##
THIS_HOSTIP := $(shell ifconfig | egrep 'inet ' | awk '{ print $$2 }' | egrep -v '^172.|^10.|^127.' | head -1)

## target outpu
DOCKER_COMPOSE := ${PWD}/docker-compose.yml

# exchange root, admin, organization
HZN_ROOT_ID := $(shell jq -r '.horizon.root' config.json)
HZN_NAMESPACE := $(shell jq -r '.horizon.namespace' config.json)
HZN_NAMESPACE := $(if ${HZN_NAMESPACE},${HZN_NAMESPACE},"oh")

## for network
HZN_HOSTNAME := $(shell jq -r '.horizon.hostname' config.json)
HZN_NETWORK := $(shell jq -r '.horizon.network.name' config.json)
HZN_NETWORK_DRIVER := $(shell jq -r '.horizon.network.driver' config.json)
# backups
HZN_HOSTNAME := $(if ${HZN_HOSTNAME},${HZN_HOSTNAME},$(shell hostname -f))
HZN_NETWORK := $(if ${HZN_NETWORK},${HZN_NETWORK},"hznnet")
HZN_NETWORK_DRIVER := $(if ${HZN_NETWORK_DRIVER},${HZN_NETWORK_DRIVER},"bridge")

## key files
HZN_PUBLICKEY_FILE := ${PWD}/publickey.pem
HZN_CACERTS_FILE := ${PWD}/cacerts.pem

## for TLS certificates
SOMECOMP := somecomp.com
SOMEUSER := e2edev
SOMENAME := localhost
SOMESUBJ :="/C=US/ST=${SOMEUSER}${SOMECOMP}/L=${SOMEUSER}${SOMECOMP}/O=${SOMEUSER}${SOMECOMP}/CN=${SOMENAME}"

## EXCHANGE
EXCHANGE_CONTAINER_NAME = $(shell jq -r '.services.exchange.name' config.json)
EXCHANGE_CONTAINER_IMAGE := $(shell jq -r '.services.exchange.image' config.json)
EXCHANGE_CONTAINER_TAG := $(shell jq -r '.services.exchange.tag' config.json)
EXCHANGE_PORT := $(shell jq -r '.services.exchange.port' config.json)
EXCHANGE_VERSION := $(shell jq -r '.services.exchange.version' config.json)
EXCHANGE_ORGANIZATION := $(shell jq -r '.services.exchange.org' config.json)
EXCHANGE_ROOT := ${HZN_ROOT_ID}/$(shell jq -r '.services.exchange.root' config.json)
EXCHANGE_ADMIN_USERNAME := $(shell jq -r '.services.exchange.admin.username' config.json)
EXCHANGE_ADMIN_PASSWORD := $(shell jq -r '.services.exchange.admin.password' config.json)
EXCHANGE_PASSWORD ?= $(if $(wildcard EXCHANGE_PASSWORD),$(shell cat EXCHANGE_PASSWORD),$(shell jq -r '.services.exchange.password' config.json))
EXCHANGE_PASSWORD_ENCODED := $(shell htpasswd -bnBC 10 "" "${EXCHANGE_PASSWORD}" | tr -d ':\n' | sed 's/$2y/$2a/')

EXCHANGE_LISTEN := $(shell jq -r '.services.exchange.listen' config.json)
EXCHANGE_URL := ${EXCHANGE_LISTEN}://${HZN_HOSTNAME}:${EXCHANGE_PORT}/${EXCHANGE_VERSION}

# "WARNING", "INFO", "DEBUG", "TRACE"
EXCHANGE_LOG_LEVEL = $(shell jq -r '.services.exchange.log' config.json)

EXCHANGE_KEYS_DIR := ${PWD}/certs
EXCHANGE_KEYS_KEY := ${EXCHANGE_KEYS_DIR}/exchange.key 
EXCHANGE_KEYS_CRT := ${EXCHANGE_KEYS_DIR}/exchange.crt
EXCHANGE_KEYS_SUBJ := ${SOMESUBJ}
EXCHANGE_KEYS := ${EXCHANGE_KEYS_KEY} ${EXCHANGE_KEYS_CRT}
EXCHANGE_CONFIG_DIR := ${PWD}/exchange
EXCHANGE_CONFIG_FILE := ${EXCHANGE_CONFIG_DIR}/exchange.json

## EXCHANGE DATABASE
EXCHANGEDB_CONTAINER_NAME := $(shell jq -r '.services.exchangedb.name' config.json)
EXCHANGEDB_CONTAINER_IMAGE := $(shell jq -r '.services.exchangedb.image' config.json)
EXCHANGEDB_CONTAINER_TAG := $(shell jq -r '.services.exchangedb.tag' config.json)
EXCHANGEDB_VOLUME_NAME := $(shell jq -r '.services.exchangedb.volume' config.json)
EXCHANGEDB_DATABASE := $(shell jq -r '.services.exchangedb.database' config.json)
EXCHANGEDB_PORT := $(shell jq -r '.services.exchangedb.port' config.json)
EXCHANGEDB_USER := $(shell jq -r '.services.exchangedb.user' config.json)
EXCHANGEDB_PASSWORD := $(shell jq -r '.services.exchangedb.password' config.json)

## independent postgres
POSTGRES_USER := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.authentication.username' postgres.json),${EXCHANGEDB_USER})
POSTGRES_PASSWORD := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.authentication.password' postgres.json),${EXCHANGEDB_PASSWORD})
POSTGRES_DATABASE := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.database' postgres.json),${EXCHANGEDB_DATABASE})
POSTGRES_HOSTNAME := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.hosts[].hostname' postgres.json),${EXCHANGEDB_CONTAINER_NAME})
POSTGRES_PORT := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.hosts[].port' postgres.json),${EXCHANGEDB_PORT})

## CLOUD SYNC SERVICE
CSS_KEYS_DIR := ${PWD}/certs
CSS_KEYS_KEY := ${CSS_KEYS_DIR}/css.key 
CSS_KEYS_CRT := ${CSS_KEYS_DIR}/css.crt
CSS_KEYS_SUBJ := ${SOMESUBJ}
CSS_KEYS := ${CSS_KEYS_KEY} ${CSS_KEYS_CRT}
CSS_CONFIG_DIR := ${PWD}/css
CSS_CONFIG_FILE := ${CSS_CONFIG_DIR}/sync.conf
CSS_CONTAINER_NAME := $(shell jq -r '.services.css.name' config.json)
CSS_CONTAINER_IMAGE := $(shell jq -r '.services.css.image' config.json)
CSS_CONTAINER_TAG := $(shell jq -r '.services.css.tag' config.json)
CSS_PORT := $(shell jq -r '.services.css.port' config.json)
CSS_LISTEN := $(shell jq -r '.services.css.listen' config.json)
CSS_TRANSPORT := $(shell jq -r '.services.css.transport' config.json)
CSS_URL := ${CSS_LISTEN}://${HZN_HOSTNAME}:${CSS_PORT}

## CLOUD SYNC SERVICE DATABASE
CSSDB_CONTAINER_NAME := $(shell jq -r '.services.cssdb.name' config.json)
CSSDB_CONTAINER_IMAGE := $(shell jq -r '.services.cssdb.image' config.json)
CSSDB_CONTAINER_TAG := $(shell jq -r '.services.cssdb.tag' config.json)
CSSDB_VOLUME_NAME := $(shell jq -r '.services.cssdb.volume' config.json)

## AGBOT
AGBOT_KEYS_DIR := ${PWD}/certs
AGBOT_KEYS_KEY := ${AGBOT_KEYS_DIR}/domain.key 
AGBOT_KEYS_CRT := ${AGBOT_KEYS_DIR}/domain.crt
AGBOT_KEYS_SUBJ := ${SOMESUBJ}
AGBOT_KEYS := ${AGBOT_KEYS_KEY} ${AGBOT_KEYS_CRT}
AGBOT_CONFIG_DIR := ${PWD}/agbot
AGBOT_CONFIG_FILE := ${AGBOT_CONFIG_DIR}/agbot.config
AGBOT_POLICY_DIR := ${AGBOT_CONFIG_DIR}/policy
AGBOT_COLONUS_DIR := ${AGBOT_CONFIG_DIR}/colonus
AGBOT_CONTAINER_NAME := $(shell jq -r '.services.agbot.name' config.json)
AGBOT_CONTAINER_IMAGE := $(shell jq -r '.services.agbot.image' config.json)
AGBOT_CONTAINER_TAG := $(shell jq -r '.services.agbot.tag' config.json)
AGBOT_PORT := $(shell jq -r '.services.agbot.port' config.json)
AGBOT_LISTEN := $(shell jq -r '.services.agbot.listen' config.json)
AGBOT_URL := ${AGBOT_LISTEN}://${HZN_HOSTNAME}:${AGBOT_PORT}

## AGREEMENTBOT
EXCHANGE_AGBOT_NAME := $(shell jq -r '.services.agbot.bot.name' config.json)
EXCHANGE_AGBOT_TOKEN := $(shell jq -r '.services.agbot.bot.token' config.json)

###
### TARGETS
###

default: keys config ${DOCKER_COMPOSE}

keys: ${CSS_KEYS} ${AGBOT_KEYS} ${EXCHANGE_KEYS}

CONFIGS := \
	  ${DOCKER_COMPOSE} \
	  ${EXCHANGE_CONFIG_FILE} \
	  ${CSS_CONFIG_FILE} \
	  ${AGBOT_CONFIG_FILE} \
	  ${PWD}/anax.json \
	  ${PWD}/hzn.json \
	  ${PWD}/default.horizon

config: makefile ${CONFIGS} ${AGBOT_POLICY_DIR} ${AGBOT_COLONUS_DIR}

up: ${DOCKER_COMPOSE} keys config
	docker-compose up -d

prime: # up
	export \
	  EXCHANGE_AGBOT_NAME=${EXCHANGE_AGBOT_NAME} \
	  EXCHANGE_AGBOT_TOKEN=${EXCHANGE_AGBOT_TOKEN} \
	  EXCHANGE_URL=${EXCHANGE_URL} \
	  EXCHANGE_ROOT=${EXCHANGE_ROOT} \
	  EXCHANGE_PASSWORD=${EXCHANGE_PASSWORD} \
	  EXCHANGE_ORGANIZATION=${EXCHANGE_ORGANIZATION} \
	  EXCHANGE_ADMIN_USERNAME=${EXCHANGE_ADMIN_USERNAME} \
	  EXCHANGE_ADMIN_PASSWORD=${EXCHANGE_ADMIN_PASSWORD} \
	  && ./prime-exchange.sh

org:
	# create organization & administrative user
	-curl -v -X POST \
	    -u "${EXCHANGE_ROOT}:${EXCHANGE_PASSWORD}" \
	    -H "Content-Type:application/json" \
	    -d '{"label": "${EXCHANGE_ORGANIZATION}", "description": "Organization for ${EXCHANGE_ORGANIZATION}"}' \
	    ${EXCHANGE_URL}/orgs/${EXCHANGE_ORGANIZATION} | jq
	-curl -v -X POST \
	    -u "${EXCHANGE_ROOT}:${EXCHANGE_PASSWORD}" \
	    -H "Content-Type:application/json" \
	    -d '{"password":"${EXCHANGE_PASSWORD}","email": "${EXCHANGE_ORGANIZATION}", "admin": true}' \
	    ${EXCHANGE_URL}/orgs/${EXCHANGE_ORGANIZATION}/users/${EXCHANGE_ADMIN_USERNAME} | jq

down: ${DOCKER_COMPOSE}
	docker-compose down

${CSS_CONFIG_DIR}/sync/auth.json:
	mkdir -p ${CSS_CONFIG_DIR}/sync
	chmod 777 ${CSS_CONFIG_DIR}/sync
	echo '{"regularUsers":[],"syncAdmins":[]}' > ${CSS_CONFIG_DIR}/sync/auth.json

${AGBOT_POLICY_DIR}: config.json
	-mkdir -p $@
	chmod 777 $@

${AGBOT_COLONUS_DIR}: config.json
	-mkdir -p $@ $@/.colonus
	chmod 777 $@ $@/.colonus

##
## CONFIGURATION FILES
##

${CONFIGS}: config.json makefile
	@F=$@ && D=$${F%/*} && F=$${F##*/} && mkdir -p $${D} && \
	export \
	  THIS_HOSTIP='${THIS_HOSTIP}' \
	  HZN_HOSTNAME='${HZN_HOSTNAME}' \
	  HZN_NAMESPACE='${HZN_NAMESPACE}' \
	  HZN_NETWORK='${HZN_NETWORK}' \
	  HZN_NETWORK_DRIVER='${HZN_NETWORK_DRIVER}' \
	  HZN_PUBLICKEY_FILE='${HZN_PUBLICKEY_FILE}' \
	  HZN_CACERTS_FILE='${HZN_CACERTS_FILE}' \
	  EXCHANGE_CONTAINER_NAME='${EXCHANGE_CONTAINER_NAME}' \
	  EXCHANGE_CONTAINER_IMAGE='${EXCHANGE_CONTAINER_IMAGE}' \
	  EXCHANGE_CONTAINER_TAG='${EXCHANGE_CONTAINER_TAG}' \
	  EXCHANGE_ORGANIZATION='${EXCHANGE_ORGANIZATION}' \
	  EXCHANGE_ADMIN_USERNAME='${EXCHANGE_ADMIN_USERNAME}' \
	  EXCHANGE_KEYS_DIR='${EXCHANGE_KEYS_DIR}' \
	  EXCHANGE_CONFIG_FILE='${EXCHANGE_CONFIG_FILE}' \
	  EXCHANGE_LISTEN='${EXCHANGE_LISTEN}' \
	  EXCHANGE_PASSWORD='${EXCHANGE_PASSWORD}' \
	  EXCHANGE_PASSWORD_ENCODED='${EXCHANGE_PASSWORD_ENCODED}' \
	  EXCHANGE_VERSION='${EXCHANGE_VERSION}' \
	  EXCHANGE_LOG_LEVEL='${EXCHANGE_LOG_LEVEL}' \
	  EXCHANGE_PORT='${EXCHANGE_PORT}' \
	  EXCHANGE_URL='${EXCHANGE_URL}' \
	  EXCHANGE_ROOT='${EXCHANGE_ROOT}' \
	  EXCHANGE_AGBOT_NAME='${EXCHANGE_AGBOT_NAME}' \
	  EXCHANGE_AGBOT_TOKEN='${EXCHANGE_AGBOT_TOKEN}' \
	  AGBOT_POLICY_DIR='${AGBOT_POLICY_DIR}' \
	  AGBOT_COLONUS_DIR='${AGBOT_COLONUS_DIR}' \
	  AGBOT_CONFIG_DIR='${AGBOT_CONFIG_DIR}' \
	  AGBOT_CONFIG_FILE='${AGBOT_CONFIG_FILE}' \
	  AGBOT_CONTAINER_NAME='${AGBOT_CONTAINER_NAME}' \
	  AGBOT_CONTAINER_IMAGE='${AGBOT_CONTAINER_IMAGE}' \
	  AGBOT_CONTAINER_TAG='${AGBOT_CONTAINER_TAG}' \
	  AGBOT_KEYS_DIR='${AGBOT_KEYS_DIR}' \
	  AGBOT_LISTEN='${AGBOT_LISTEN}' \
	  AGBOT_PORT='${AGBOT_PORT}' \
	  AGBOT_URL='${AGBOT_URL}' \
	  CSS_CONTAINER_NAME='${CSS_CONTAINER_NAME}' \
	  CSS_CONTAINER_IMAGE='${CSS_CONTAINER_IMAGE}' \
	  CSS_CONTAINER_TAG='${CSS_CONTAINER_TAG}' \
	  CSS_KEYS_DIR='${CSS_KEYS_DIR}' \
	  CSS_CONFIG_DIR='${CSS_CONFIG_DIR}' \
	  CSS_CONFIG_FILE='${CSS_CONFIG_FILE}' \
	  CSS_LISTEN='${CSS_LISTEN}' \
	  CSS_PORT='${CSS_PORT}' \
	  CSS_TRANSPORT='${CSS_TRANSPORT}' \
	  CSS_URL='${CSS_URL}' \
	  CSSDB_CONTAINER_NAME='${CSSDB_CONTAINER_NAME}' \
	  CSSDB_CONTAINER_IMAGE='${CSSDB_CONTAINER_IMAGE}' \
	  CSSDB_CONTAINER_TAG='${CSSDB_CONTAINER_TAG}' \
	  CSSDB_VOLUME_NAME='${CSSDB_VOLUME_NAME}' \
	  EXCHANGEDB_CONTAINER_NAME='${EXCHANGEDB_CONTAINER_NAME}' \
	  EXCHANGEDB_CONTAINER_IMAGE='${EXCHANGEDB_CONTAINER_IMAGE}' \
	  EXCHANGEDB_CONTAINER_TAG='${EXCHANGEDB_CONTAINER_TAG}' \
	  EXCHANGEDB_VOLUME_NAME='${EXCHANGEDB_VOLUME_NAME}' \
	  EXCHANGEDB_DATABASE='${EXCHANGEDB_DATABASE}' \
	  EXCHANGEDB_PORT='${EXCHANGEDB_PORT}' \
	  EXCHANGEDB_USER='${EXCHANGEDB_USER}' \
	  POSTGRES_HOSTNAME='${POSTGRES_HOSTNAME}' \
	  POSTGRES_PORT='${POSTGRES_PORT}' \
	  POSTGRES_PASSWORD='${POSTGRES_PASSWORD}' \
	  POSTGRES_USER='${POSTGRES_USER}' \
	  POSTGRES_DATABASE='${POSTGRES_DATABASE}' \
	  && cat $${F}.tmpl | envsubst > $@

## KEYS
${AGBOT_KEYS}:
	-mkdir -p ${AGBOT_KEYS_DIR}
	@openssl req \
	  -newkey rsa:4096 \
	  -nodes -sha256 -x509 \
	  -keyout ${AGBOT_KEYS_KEY}  \
	  -days 365 \
	  -out ${AGBOT_KEYS_CRT} \
	  -subj ${AGBOT_KEYS_SUBJ}

${CSS_KEYS}:
	-mkdir -p ${CSS_KEYS_DIR}
	@openssl req \
	  -newkey rsa:4096 \
	  -nodes -sha256 -x509 \
	  -keyout ${CSS_KEYS_KEY} \
	  -days 365 \
	  -out ${CSS_KEYS_CRT} \
	  -subj ${CSS_KEYS_SUBJ}

${EXCHANGE_KEYS}:
	mkdir -p ${EXCHANGE_KEYS_DIR}
	openssl req \
	  -newkey rsa:4096 \
	  -nodes -sha256 -x509 \
	  -keyout ${EXCHANGE_KEYS_KEY} \
	  -days 365 \
	  -out ${EXCHANGE_KEYS_CRT} \
	  -subj ${EXCHANGE_KEYS_SUBJ}

## ADMINISTRIVIA

.PHONY: keys config up down clean prime remove remove-images reset-db realclean distclean tidy

remove:
	-docker rm -f "$(AGBOT_CONTAINER_NAME)"
	-docker rm -f "$(EXCHANGE_CONTAINER_NAME)"
	-docker rm -f "$(CSS_CONTAINER_NAME)"
	-docker rm -f "$(EXCHANGEDB_CONTAINER_NAME)"
	-docker rm -f "$(CSSDB_CONTAINER_NAME)"

remove-images: remove
	-docker rmi $(AGBOT_CONTAINER_IMAGE):$(AGBOT_CONTAINER_TAG)
	-docker rmi $(EXCHANGE_CONTAINER_IMAGE):$(EXCHANGE_CONTAINER_TAG)
	-docker rmi $(EXCHANGEDB_CONTAINER_IMAGE):$(EXCHANGEDB_CONTAINER_TAG)
	-docker rmi $(CSS_CONTAINER_IMAGE):$(CSS_CONTAINER_TAG)
	-docker rmi $(CSSDB_CONTAINER_IMAGE):$(CSSDB_CONTAINER_TAG)

reset-db:
	-export \
	  TOKEN=$$(curl -sLX GET -H 'Authorization:Basic ${EXCHANGE_ROOT}:$(EXCHANGE_PASSWORD)' "${EXCHANGE_URL}/admin/dropdb/token" | jq -r '.token'))) \
	  && curl -sLX POST -H "Authorization:Basic ${EXCHANGE_ROOT}:$${TOKEN}" "${EXCHANGE_URL}/admin/dropdb" | jq -r '.msg'
	-curl -sLX POST -H "Authorization:Basic ${EXCHANGE_ROOT}:$(EXCHANGE_PASSWORD)" "${EXCHANGE_URL}/admin/initdb" | jq -r '.msg'

tidy:
	-rm -fr anax.json hzn.json default.horizon

clean: tidy remove
	sudo rm -fr ${DOCKER_COMPOSE} css agbot exchange

realclean:  clean
	-docker volume prune -f
	-rm -fr certs

distclean: realclean
	-docker system prune -f
