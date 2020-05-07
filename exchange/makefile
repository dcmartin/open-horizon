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

## where am i
CWD := $(shell pwd -P)

## target output
DOCKER_COMPOSE := ${CWD}/docker-compose.yml

CONFIG_JSON := $(if $(wildcard config.json),config.json,config.json.tmpl)

# exchange root, admin, organization
HZN_ROOT_ID := $(shell jq -r '.horizon.root' $(CONFIG_JSON))

## for network
EXCHANGE_ROOTID := $(if $(wildcard EXCHANGE_ROOTID),$(shell cat EXCHANGE_ROOTID),root)
EXCHANGE_NAMESPACE := $(if $(wildcard EXCHANGE_NAMESPACE),$(shell cat EXCHANGE_NAMESPACE),$(shell whoami))
EXCHANGE_HOSTNAME := $(if $(wildcard EXCHANGE_HOSTNAME),$(shell cat EXCHANGE_HOSTNAME),$(shell hostname -I | awk '{ print $$1 }'))
EXCHANGE_NETWORK := $(if $(wildcard EXCHANGE_NETWORK),$(shell cat EXCHANGE_NETWORK),hzn)
EXCHANGE_NETWORK_DRIVER := $(if $(wildcard EXCHANGE_NETWORK_DRIVER),$(shell cat EXCHANGE_NETWORK_DRIVER),bridge)
EXCHANGE_ORGANIZATION := $(if $(wildcard EXCHANGE_ORGANIZATION),$(shell cat EXCHANGE_ORGANIZATION),$(shell whoami))

## versions
CSS_TAG := $(if $(wildcard CSS_TAG),$(shell cat CSS_TAG),$(shell jq -r '.services.css.stable' ${CONFIG_JSON}))
EXCHANGE_TAG := $(if $(wildcard EXCHANGE_TAG),$(shell cat EXCHANGE_TAG),$(shell jq -r '.services.exchange.stable' ${CONFIG_JSON}))
AGBOT_TAG := $(if $(wildcard AGBOT_TAG),$(shell cat AGBOT_TAG),$(shell jq -r '.services.agbot.stable' ${CONFIG_JSON}))

## key files
HZN_PUBLICKEY_FILE := ${CWD}/publickey.pem
HZN_CACERTS_FILE := ${CWD}/cacerts.pem

## for TLS certificates
SOMECOMP := somecomp.com
SOMEUSER := e2edev
SOMENAME := localhost
SOMESUBJ := "/C=US/ST=${SOMEUSER}${SOMECOMP}/L=${SOMEUSER}${SOMECOMP}/O=${SOMEUSER}${SOMECOMP}/CN=${SOMENAME}"

## EXCHANGE
EXCHANGE_CONTAINER_NAME = $(shell jq -r '.services.exchange.name' $(CONFIG_JSON))
EXCHANGE_CONTAINER_IMAGE := $(shell jq -r '.services.exchange.image' $(CONFIG_JSON))
EXCHANGE_TAG ?= $(shell jq -r '.services.exchange.tag' $(CONFIG_JSON))
EXCHANGE_PORT := $(shell jq -r '.services.exchange.port' $(CONFIG_JSON))
EXCHANGE_VERSION := $(shell jq -r '.services.exchange.version' $(CONFIG_JSON))
EXCHANGE_ROOT := ${HZN_ROOT_ID}/$(shell jq -r '.services.exchange.root' $(CONFIG_JSON))
EXCHANGE_ADMIN_USERNAME := $(shell jq -r '.services.exchange.admin.username' $(CONFIG_JSON))
EXCHANGE_ADMIN_USERNAME := $(if ${EXCHANGE_ADMIN_USERNAME},${EXCHANGE_ADMIN_USERNAME},$(shell whoami))
EXCHANGE_ADMIN_PASSWORD := $(shell jq -r '.services.exchange.admin.password' $(CONFIG_JSON))
EXCHANGE_ADMIN_PASSWORD := $(if ${EXCHANGE_ADMIN_PASSWORD},${EXCHANGE_ADMIN_PASSWORD},whocares)

## PASSWORD
EXCHANGE_PASSWORD ?= $(if $(wildcard EXCHANGE_PASSWORD),$(shell cat EXCHANGE_PASSWORD),Horizon-Rul3s))
#EXCHANGE_PASSWORD_ENCODED := $(shell htpasswd -bnBC 10 "" "${EXCHANGE_PASSWORD}" | base64 -w0)
#EXCHANGE_PASSWORD_ENCODED := $(shell htpasswd -bnBC 10 "" "${EXCHANGE_PASSWORD}" | tr -d ':\n' | sed 's/$$2y/$$2a/')
EXCHANGE_PASSWORD_ENCODED := $(shell htpasswd -bnBC 10 "" "${EXCHANGE_PASSWORD}" | tee EXCHANGE_PASSWORD_ENCODED)

EXCHANGE_LISTEN := $(shell jq -r '.services.exchange.listen' $(CONFIG_JSON))
HZN_EXCHANGE_URL := ${EXCHANGE_LISTEN}://${EXCHANGE_HOSTNAME}:${EXCHANGE_PORT}/${EXCHANGE_VERSION}

# "WARNING", "INFO", "DEBUG", "TRACE"
EXCHANGE_LOG_LEVEL = $(shell jq -r '.services.exchange.log' $(CONFIG_JSON))

EXCHANGE_KEYS_DIR := ${CWD}/certs
EXCHANGE_KEYS_KEY := ${EXCHANGE_KEYS_DIR}/exchange.key 
EXCHANGE_KEYS_CRT := ${EXCHANGE_KEYS_DIR}/exchange.crt
EXCHANGE_KEYS_SUBJ := ${SOMESUBJ}
EXCHANGE_KEYS := ${EXCHANGE_KEYS_KEY} ${EXCHANGE_KEYS_CRT}
EXCHANGE_CONFIG_DIR := ${CWD}/exchange
EXCHANGE_CONFIG_FILE := ${EXCHANGE_CONFIG_DIR}/exchange.json

## EXCHANGE DATABASE
EXCHANGEDB_CONTAINER_NAME := $(shell jq -r '.services.exchangedb.name' $(CONFIG_JSON))
EXCHANGEDB_CONTAINER_IMAGE := $(shell jq -r '.services.exchangedb.image' $(CONFIG_JSON))
EXCHANGEDB_CONTAINER_TAG := $(shell jq -r '.services.exchangedb.tag' $(CONFIG_JSON))
EXCHANGEDB_VOLUME_NAME := $(shell jq -r '.services.exchangedb.volume' $(CONFIG_JSON))
EXCHANGEDB_DATABASE := $(shell jq -r '.services.exchangedb.database' $(CONFIG_JSON))
EXCHANGEDB_PORT := $(shell jq -r '.services.exchangedb.port' $(CONFIG_JSON))
EXCHANGEDB_USER := $(shell jq -r '.services.exchangedb.user' $(CONFIG_JSON))
EXCHANGEDB_PASSWORD := $(shell jq -r '.services.exchangedb.password' $(CONFIG_JSON))

## independent postgres
POSTGRES_USER := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.authentication.username' postgres.json),${EXCHANGEDB_USER})
POSTGRES_PASSWORD := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.authentication.password' postgres.json),${EXCHANGEDB_PASSWORD})
POSTGRES_DATABASE := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.database' postgres.json),${EXCHANGEDB_DATABASE})
POSTGRES_HOSTNAME := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.hosts[].hostname' postgres.json),${EXCHANGEDB_CONTAINER_NAME})
POSTGRES_PORT := $(if $(wildcard postgres.json),$(shell jq -r '.connection.postgres.hosts[].port' postgres.json),${EXCHANGEDB_PORT})

## CLOUD SYNC SERVICE
CSS_KEYS_DIR := ${CWD}/certs
CSS_KEYS_KEY := ${CSS_KEYS_DIR}/css.key 
CSS_KEYS_CRT := ${CSS_KEYS_DIR}/css.crt
CSS_KEYS_SUBJ := ${SOMESUBJ}
CSS_KEYS := ${CSS_KEYS_KEY} ${CSS_KEYS_CRT}
CSS_CONFIG_DIR := ${CWD}/css
CSS_CONFIG_FILE := ${CSS_CONFIG_DIR}/sync.conf
CSS_CONTAINER_NAME := $(shell jq -r '.services.css.name' $(CONFIG_JSON))
CSS_CONTAINER_IMAGE := $(shell jq -r '.services.css.image' $(CONFIG_JSON))
CSS_TAG ?= $(shell jq -r '.services.css.tag' $(CONFIG_JSON))
CSS_PORT := $(shell jq -r '.services.css.port' $(CONFIG_JSON))
CSS_LISTEN := $(shell jq -r '.services.css.listen' $(CONFIG_JSON))
CSS_TRANSPORT := $(shell jq -r '.services.css.transport' $(CONFIG_JSON))
HZN_FSS_CSSURL := ${CSS_LISTEN}://${EXCHANGE_HOSTNAME}:${CSS_PORT}

## CLOUD SYNC SERVICE DATABASE
CSSDB_CONTAINER_NAME := $(shell jq -r '.services.cssdb.name' $(CONFIG_JSON))
CSSDB_CONTAINER_IMAGE := $(shell jq -r '.services.cssdb.image' $(CONFIG_JSON))
CSSDB_CONTAINER_TAG := $(shell jq -r '.services.cssdb.tag' $(CONFIG_JSON))
CSSDB_VOLUME_NAME := $(shell jq -r '.services.cssdb.volume' $(CONFIG_JSON))

## AGBOT
AGBOT_KEYS_DIR := ${CWD}/certs
AGBOT_KEYS_KEY := ${AGBOT_KEYS_DIR}/domain.key 
AGBOT_KEYS_CRT := ${AGBOT_KEYS_DIR}/domain.crt
AGBOT_KEYS_SUBJ := ${SOMESUBJ}
AGBOT_KEYS := ${AGBOT_KEYS_KEY} ${AGBOT_KEYS_CRT}
AGBOT_CONFIG_DIR := ${CWD}/agbot
AGBOT_CONFIG_FILE := ${AGBOT_CONFIG_DIR}/agbot.config
AGBOT_POLICY_DIR := ${AGBOT_CONFIG_DIR}/policy
AGBOT_COLONUS_DIR := ${AGBOT_CONFIG_DIR}/colonus
AGBOT_CONTAINER_NAME := $(shell jq -r '.services.agbot.name' $(CONFIG_JSON))
AGBOT_CONTAINER_IMAGE := $(shell jq -r '.services.agbot.image' $(CONFIG_JSON))
AGBOT_TAG ?= $(shell jq -r '.services.agbot.tag' $(CONFIG_JSON))
AGBOT_PORT := $(shell jq -r '.services.agbot.port' $(CONFIG_JSON))
AGBOT_LISTEN := $(shell jq -r '.services.agbot.listen' $(CONFIG_JSON))
AGBOT_URL := ${AGBOT_LISTEN}://${EXCHANGE_HOSTNAME}:${AGBOT_PORT}

## AGREEMENTBOT
EXCHANGE_AGBOT_NAME := $(shell jq -r '.services.agbot.bot.name' $(CONFIG_JSON))
EXCHANGE_AGBOT_TOKEN := $(shell jq -r '.services.agbot.bot.token' $(CONFIG_JSON))

###
### TARGETS
###

default: all up

all: keys config ${DOCKER_COMPOSE}

keys: ${CSS_KEYS} ${AGBOT_KEYS} ${EXCHANGE_KEYS}

CONFIGS := \
	  ${CWD}/config.json \
	  ${DOCKER_COMPOSE} \
	  ${EXCHANGE_CONFIG_FILE} \
	  ${CSS_CONFIG_FILE} \
	  ${AGBOT_CONFIG_FILE} \
	  ${CWD}/anax.json \
	  ${CWD}/hzn.json \
	  ${CWD}/default.horizon

exchange-fix: EXCHANGE_PASSWORD_ENCODED ${EXCHANGE_CONFIG_FILE}
	temp=$(shell mktemp) \
	  && jq '.|.api.root.password="$(shell cat EXCHANGE_PASSWORD_ENCODED)"' ${EXCHANGE_CONFIG_FILE} > $${temp} \
	  && mv -f $${temp} ${EXCHANGE_CONFIG_FILE}

config-fix: EXCHANGE_PASSWORD_ENCODED ${CWD}/config.json
	temp=$(shell mktemp) \
	  && jq '.services.exchange.encoded="$(shell cat EXCHANGE_PASSWORD_ENCODED)"' ${CWD}/config.json > $${temp} \
	  && mv -f $${temp} ${CWD}/config.json

## config
config: makefile ${CONFIGS} exchange-fix config-fix ${AGBOT_POLICY_DIR} ${AGBOT_COLONUS_DIR}

up: ${DOCKER_COMPOSE} keys config
	docker-compose up -d

prime: # up
	@echo "making $@"
	export \
	  EXCHANGE_AGBOT_NAME=${EXCHANGE_AGBOT_NAME} \
	  EXCHANGE_AGBOT_TOKEN=${EXCHANGE_AGBOT_TOKEN} \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	  EXCHANGE_ROOT=${EXCHANGE_ROOT} \
	  EXCHANGE_PASSWORD=${EXCHANGE_PASSWORD} \
	  EXCHANGE_ORGANIZATION=${EXCHANGE_ORGANIZATION} \
	  EXCHANGE_ADMIN_USERNAME=${EXCHANGE_ADMIN_USERNAME} \
	  EXCHANGE_ADMIN_PASSWORD=${EXCHANGE_ADMIN_PASSWORD} \
	  && ./prime-exchange.sh

org:
	@echo "making $@"
	# create organization & administrative user
	-@curl -v -X POST \
	    -u "${EXCHANGE_ROOT}:${EXCHANGE_PASSWORD}" \
	    -H "Content-Type:application/json" \
	    -d '{"label": "${EXCHANGE_ORGANIZATION}", "description": "Organization for ${EXCHANGE_ORGANIZATION}"}' \
	    ${HZN_EXCHANGE_URL}/orgs/${EXCHANGE_ORGANIZATION} | jq
	-@curl -v -X POST \
	    -u "${EXCHANGE_ROOT}:${EXCHANGE_PASSWORD}" \
	    -H "Content-Type:application/json" \
	    -d '{"password":"${EXCHANGE_PASSWORD}","email": "${EXCHANGE_ORGANIZATION}", "admin": true}' \
	    ${HZN_EXCHANGE_URL}/orgs/${EXCHANGE_ORGANIZATION}/users/${EXCHANGE_ADMIN_USERNAME} | jq

down: ${DOCKER_COMPOSE}
	docker-compose down

${CSS_CONFIG_DIR}/sync/auth.json:
	@echo "making $@"
	-@mkdir -p ${CSS_CONFIG_DIR}/sync
	-@chmod 777 ${CSS_CONFIG_DIR}/sync
	@echo '{"regularUsers":[],"syncAdmins":[]}' > ${CSS_CONFIG_DIR}/sync/auth.json

${AGBOT_POLICY_DIR}: config.json
	@echo "making $@"
	-@mkdir -p $@
	-@chmod 777 $@

${AGBOT_COLONUS_DIR}: config.json
	@echo "making $@"
	-@mkdir -p $@ $@/.colonus
	-@chmod 777 $@ $@/.colonus

##
## CONFIGURATION FILES
##

${CONFIGS}: ${CONFIG_JSON} makefile
	@F=$@ && D=$${F%/*} && F=$${F##*/} && mkdir -p $${D} && \
	export \
	  EXCHANGE_HOSTNAME="${EXCHANGE_HOSTNAME}" \
	  EXCHANGE_NAMESPACE="${EXCHANGE_NAMESPACE}" \
	  EXCHANGE_NETWORK="${EXCHANGE_NETWORK}" \
	  EXCHANGE_NETWORK_DRIVER="${EXCHANGE_NETWORK_DRIVER}" \
	  HZN_PUBLICKEY_FILE="${HZN_PUBLICKEY_FILE}" \
	  HZN_CACERTS_FILE="${HZN_CACERTS_FILE}" \
	  EXCHANGE_CONTAINER_NAME="${EXCHANGE_CONTAINER_NAME}" \
	  EXCHANGE_CONTAINER_IMAGE="${EXCHANGE_CONTAINER_IMAGE}" \
	  EXCHANGE_TAG="${EXCHANGE_TAG}" \
	  EXCHANGE_ORGANIZATION="${EXCHANGE_ORGANIZATION}" \
	  EXCHANGE_ADMIN_USERNAME="${EXCHANGE_ADMIN_USERNAME}" \
	  EXCHANGE_KEYS_DIR="${EXCHANGE_KEYS_DIR}" \
	  EXCHANGE_CONFIG_FILE="${EXCHANGE_CONFIG_FILE}" \
	  EXCHANGE_LISTEN="${EXCHANGE_LISTEN}" \
	  EXCHANGE_PASSWORD="${EXCHANGE_PASSWORD}" \
	  EXCHANGE_PASSWORD_ENCODED="${EXCHANGE_PASSWORD_ENCODED}" \
	  EXCHANGE_VERSION="${EXCHANGE_VERSION}" \
	  EXCHANGE_LOG_LEVEL="${EXCHANGE_LOG_LEVEL}" \
	  EXCHANGE_PORT="${EXCHANGE_PORT}" \
	  HZN_EXCHANGE_URL="${HZN_EXCHANGE_URL}" \
	  EXCHANGE_ROOT="${EXCHANGE_ROOT}" \
	  EXCHANGE_AGBOT_NAME="${EXCHANGE_AGBOT_NAME}" \
	  EXCHANGE_AGBOT_TOKEN="${EXCHANGE_AGBOT_TOKEN}" \
	  AGBOT_POLICY_DIR="${AGBOT_POLICY_DIR}" \
	  AGBOT_COLONUS_DIR="${AGBOT_COLONUS_DIR}" \
	  AGBOT_CONFIG_DIR="${AGBOT_CONFIG_DIR}" \
	  AGBOT_CONFIG_FILE="${AGBOT_CONFIG_FILE}" \
	  AGBOT_CONTAINER_NAME="${AGBOT_CONTAINER_NAME}" \
	  AGBOT_CONTAINER_IMAGE="${AGBOT_CONTAINER_IMAGE}" \
	  AGBOT_TAG="${AGBOT_TAG}" \
	  AGBOT_KEYS_DIR="${AGBOT_KEYS_DIR}" \
	  AGBOT_LISTEN="${AGBOT_LISTEN}" \
	  AGBOT_PORT="${AGBOT_PORT}" \
	  AGBOT_URL="${AGBOT_URL}" \
	  CSS_CONTAINER_NAME="${CSS_CONTAINER_NAME}" \
	  CSS_CONTAINER_IMAGE="${CSS_CONTAINER_IMAGE}" \
	  CSS_TAG="${CSS_TAG}" \
	  CSS_KEYS_DIR="${CSS_KEYS_DIR}" \
	  CSS_CONFIG_DIR="${CSS_CONFIG_DIR}" \
	  CSS_CONFIG_FILE="${CSS_CONFIG_FILE}" \
	  CSS_LISTEN="${CSS_LISTEN}" \
	  CSS_PORT="${CSS_PORT}" \
	  CSS_TRANSPORT="${CSS_TRANSPORT}" \
	  HZN_FSS_CSSURL="${HZN_FSS_CSSURL}" \
	  CSSDB_CONTAINER_NAME="${CSSDB_CONTAINER_NAME}" \
	  CSSDB_CONTAINER_IMAGE="${CSSDB_CONTAINER_IMAGE}" \
	  CSSDB_CONTAINER_TAG="${CSSDB_CONTAINER_TAG}" \
	  CSSDB_VOLUME_NAME="${CSSDB_VOLUME_NAME}" \
	  EXCHANGEDB_CONTAINER_NAME="${EXCHANGEDB_CONTAINER_NAME}" \
	  EXCHANGEDB_CONTAINER_IMAGE="${EXCHANGEDB_CONTAINER_IMAGE}" \
	  EXCHANGEDB_CONTAINER_TAG="${EXCHANGEDB_CONTAINER_TAG}" \
	  EXCHANGEDB_VOLUME_NAME="${EXCHANGEDB_VOLUME_NAME}" \
	  EXCHANGEDB_DATABASE="${EXCHANGEDB_DATABASE}" \
	  EXCHANGEDB_PORT="${EXCHANGEDB_PORT}" \
	  EXCHANGEDB_USER="${EXCHANGEDB_USER}" \
	  POSTGRES_HOSTNAME="${POSTGRES_HOSTNAME}" \
	  POSTGRES_PORT="${POSTGRES_PORT}" \
	  POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
	  POSTGRES_USER="${POSTGRES_USER}" \
	  POSTGRES_DATABASE="${POSTGRES_DATABASE}" \
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

logs:
	docker-compose logs -f

## ADMINISTRIVIA

.PHONY: logs keys config up down clean prime remove remove-images reset-db realclean distclean tidy config.json exchange-fix config-fix

remove:
	-docker rm -f "$(AGBOT_CONTAINER_NAME)"
	-docker rm -f "$(EXCHANGE_CONTAINER_NAME)"
	-docker rm -f "$(CSS_CONTAINER_NAME)"
	-docker rm -f "$(EXCHANGEDB_CONTAINER_NAME)"
	-docker rm -f "$(CSSDB_CONTAINER_NAME)"

remove-images: remove
	-docker rmi $(AGBOT_CONTAINER_IMAGE):$(AGBOT_TAG)
	-docker rmi $(EXCHANGE_CONTAINER_IMAGE):$(EXCHANGE_TAG)
	-docker rmi $(EXCHANGEDB_CONTAINER_IMAGE):$(EXCHANGEDB_CONTAINER_TAG)
	-docker rmi $(CSS_CONTAINER_IMAGE):$(CSS_TAG)
	-docker rmi $(CSSDB_CONTAINER_IMAGE):$(CSSDB_CONTAINER_TAG)

reset-db:
	-export \
	  TOKEN=$$(curl -sLX GET -H 'Authorization:Basic ${EXCHANGE_ROOT}:$(EXCHANGE_PASSWORD)' "${HZN_EXCHANGE_URL}/admin/dropdb/token" | jq -r '.token'))) \
	  && curl -sLX POST -H "Authorization:Basic ${EXCHANGE_ROOT}:$${TOKEN}" "${HZN_EXCHANGE_URL}/admin/dropdb" | jq -r '.msg'
	-curl -sLX POST -H "Authorization:Basic ${EXCHANGE_ROOT}:$(EXCHANGE_PASSWORD)" "${HZN_EXCHANGE_URL}/admin/initdb" | jq -r '.msg'

tidy:
	-rm -fr anax.json hzn.json default.horizon

clean: tidy remove
	sudo rm -fr ${DOCKER_COMPOSE} css agbot exchange

realclean:  clean
	-docker volume prune -f
	-rm -fr certs

distclean: realclean
	-docker system prune -f
