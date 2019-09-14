###
### make(1) file for using Docker to start Open Horizon
###
### Uses the default `docker-compose.yml` file in current directory
###

##
## TARGETS:
##
#
# default - create configuration files
# up - perform `docker-compose up -d` to start EdgeX
# down - perform `docker-compose down` to stop EdgeX
# clean - stop and clean
# publish - publish `edgex` service and pattern in exchange
# machine - start `edgex` pattern on machine(s) specified in `NODES` file
# 

## GLOBAL variables
EDGEX_LOG_LEVEL ?= $(if $(wildcard EDGEX_LOG_LEVEL),$(shell cat EDGEX_LOG_LEVEL),"INFO")
EDGEX_LOG_REMOTE ?= $(if $(wildcard EDGEX_LOG_REMOTE),$(shell cat EDGEX_LOG_REMOTE),false)
EDGEX_REGISTRY_HOST ?= $(if $(wildcard EDGEX_REGISTRY_HOST),$(shell cat EDGEX_REGISTRY_HOST),"localhost")
EDGEX_REGISTRY_PORT ?= $(if $(wildcard EDGEX_REGISTRY_PORT),$(shell cat EDGEX_REGISTRY_PORT),8500)
EDGEX_REGISTRY_TYPE ?= $(if $(wildcard EDGEX_REGISTRY_TYPE),$(shell cat EDGEX_REGISTRY_TYPE),"consul")

## EDGEX configuration files
EDGEX_CONFIG_DIR := ${PWD}
EDGEX_COMMAND := ${EDGEX_CONFIG_DIR}/command.toml
EDGEX_DATA := ${EDGEX_CONFIG_DIR}/data.toml
EDGEX_LOGGING := ${EDGEX_CONFIG_DIR}/logging.toml
EDGEX_METADATA := ${EDGEX_CONFIG_DIR}/metadata.toml
EDGEX_NOTIFICATION := ${EDGEX_CONFIG_DIR}/notification.toml
EDGEX_CONFIG_FILES := ${EDGEX_COMMAND} ${EDGEX_DATA} ${EDGEX_LOGGING} ${EDGEX_METADATA} ${EDGEX_NOTIFICATION}

## EDGEX configuration
COMMAND_SERVICE_HOST := $(shell jq -r '.edgex.command.service.host' "config.json")
COMMAND_SERVICE_PORT := $(shell jq -r '.edgex.command.service.port' "config.json")
COMMAND_SERVICE_PROTOCOL := $(shell jq -r '.edgex.command.service.protocol' "config.json")
DATABASE_PRIMARY_HOST := $(shell jq -r '.edgex.database.primary.host' "config.json")
DATABASE_PRIMARY_PORT := $(shell jq -r '.edgex.database.primary.port' "config.json")
DATABASE_PRIMARY_TYPE := $(shell jq -r '.edgex.database.primary.type' "config.json")
DATA_SERVICE_HOST := $(shell jq -r '.edgex.data.service.host' "config.json")
DATA_SERVICE_PORT := $(shell jq -r '.edgex.data.service.port' "config.json")
DATA_SERVICE_PROTOCOL := $(shell jq -r '.edgex.data.service.protocol' "config.json")
LOGGING_SERVICE_HOST := $(shell jq -r '.edgex.logging.service.host' "config.json")
LOGGING_SERVICE_PORT := $(shell jq -r '.edgex.logging.service.port' "config.json")
LOGGING_SERVICE_PROTOCOL := $(shell jq -r '.edgex.logging.service.protocol' "config.json")
METADATA_SERVICE_HOST := $(shell jq -r '.edgex.metadata.service.host' "config.json")
METADATA_SERVICE_PORT := $(shell jq -r '.edgex.metadata.service.port' "config.json")
METADATA_SERVICE_PROTOCOL := $(shell jq -r '.edgex.metadata.service.protocol' "config.json")
NOTIFICATION_SERVICE_HOST := $(shell jq -r '.edgex.notification.service.host' "config.json")
NOTIFICATION_SERVICE_PORT := $(shell jq -r '.edgex.notification.service.port' "config.json")
NOTIFICATION_SERVICE_PROTOCOL := $(shell jq -r '.edgex.notification.service.protocol' "config.json")
NOTIFICATION_SMTP_ESSCERT := $(shell jq -r '.edgex.notification.smtp.esscert' "config.json")
NOTIFICATION_SMTP_HOST := $(shell jq -r '.edgex.notification.smtp.host' "config.json")
NOTIFICATION_SMTP_PORT := $(shell jq -r '.edgex.notification.smtp.port' "config.json")
NOTIFICATION_SMTP_PASSWORD := $(shell jq -r '.edgex.notification.smtp.password' "config.json")
NOTIFICATION_SMTP_SENDER := $(shell jq -r '.edgex.notification.smtp.sender' "config.json")
NOTIFICATION_SMTP_SUBJECT := $(shell jq -r '.edgex.notification.smtp.subject' "config.json")
NOTIFICATION_SMTP_USERNAME := $(shell jq -r '.edgex.notification.smtp.username' "config.json")

## contsiner names
EDGEX_CONTAINERS := 

## HORIZON configuration files

# server
HORIZON_EXCHANGE_HOST := $(shell jq -r '.horizon.exchange.host' "config.json")
HORIZON_EXCHANGE_PORT := $(shell jq -r '.horizon.exchange.port' "config.json")
HORIZON_EXCHANGE_PROTOCOL := $(shell jq -r '.horizon.exchange.protocol' "config.json")
HORIZON_EXCHANGE_VERSION := $(shell jq -r '.horizon.exchange.version' "config.json")
HORIZON_EXCHANGE_URL := ${HORIZON_EXCHANGE_PROTOCOL}://${HORIZON_EXCHANGE_HOST}:${HORIZON_EXCHANGE_PORT}/${HORIZON_EXCHANGE_VERSION}
HORIZON_EXCHANGE_URL := $(if ${HZN_EXCHANGE_URL},${HZN_EXCHANGE_URL},${HORIZON_EXCHANGE_URL})

# user
HORIZON_EXCHANGE_ORG := $(if ${HZN_ORG_ID},${HZN_ORG_ID},$(shell jq -r '.horizon.exchange.org' "config.json"))
HORIZON_EXCHANGE_USER := $(if ${HZN_USER_ID},${HZN_USER_ID},$(shell jq -r '.horizon.exchange.user' "config.json"))
HORIZON_EXCHANGE_APIKEY := $(if ${HZN_EXCHANGE_APIKEY},${HZN_EXCHANGE_APIKEY},$(if $(wildcard HZN_EXCHANGE_APIKEY),$(shell cat HZN_EXCHANGE_APIKEY),$(shell jq -r '.horizon.exchange.apikey' "config.json")))

# service & pattern
HORIZON_CONFIG_DIR := ${PWD}/horizon
HORIZON_SERVICE_JSON := ${HORIZON_CONFIG_DIR}/service.json
HORIZON_PATTERN_JSON := ${HORIZON_CONFIG_DIR}/pattern.json
HORIZON_INPUT_JSON := ${HORIZON_CONFIG_DIR}/userinput.json
HORIZON_CONFIG_FILES := ${HORIZON_SERVICE_JSON} ${HORIZON_PATTERN_JSON} ${HORIZON_INPUT_JSON}

##
THIS_HOSTIP := $(shell ifconfig | egrep 'inet ' | awk '{ print $$2 }' | egrep -v '^172.|^10.|^127.' | head -1)

## target output
DOCKER_COMPOSE := ${PWD}/docker-compose.yml

###
### TARGETS
###

default: ${EDGEX_CONFIG_FILES} ${DOCKER_COMPOSE} ${HORIZON_CONFIG_FILES}

# create keys

KEYS := key.pem key.pub

${KEYS}:
	hzn key create $$(whoami) $$(hostname) -k key.pem -K key.pub

publish: ${HZN_CONFIG_FILES} ${KEYS}
	@echo "$$(date +%FT%TZ) publishing service"
	@export \
	  HZN_ORG_ID=${HORIZON_EXCHANGE_ORG} \
	  HZN_USER_ID=${HORIZON_EXCHANGE_USER} \
	  HZN_EXCHANGE_APIKEY=${HORIZON_EXCHANGE_USER} \
	  HZN_EXCHANGE_URL=${HORIZON_EXCHANGE_URL} \
	&& \
	hzn exchange service publish \
	    -I \
	    -O \
	    -o ${HORIZON_EXCHANGE_ORG} \
	    -u ${HORIZON_EXCHANGE_ORG}/${HORIZON_EXCHANGE_USER}:${HORIZON_EXCHANGE_APIKEY} \
	    -k ${PRIVATE_KEY} \
	    -K ${PUBLIC_KEY} \
	    -f ${HORIZON_SERVICE_JSON}
	@echo "$$(date +%FT%TZ) publishing pattern"
	@export \
	  HZN_ORG_ID=${HORIZON_EXCHANGE_ORG} \
	  HZN_USER_ID=${HORIZON_EXCHANGE_USER} \
	  HZN_EXCHANGE_APIKEY=${HORIZON_EXCHANGE_USER} \
	  HZN_EXCHANGE_URL=${HORIZON_EXCHANGE_URL} \
	&& \
	hzn exchange pattern publish \
	  -o ${HORIZON_EXCHANGE_ORG} \
	  -u ${HORIZON_EXCHANGE_USER}:${HORIZON_EXCHANGE_APIKEY} \
	  -f ${HORIZON_PATTERN_JSON} \
	  -p 'edgex' \
	  -k key.pem \
	  -K key.pub

# register a machine

${MACHINE}: ${INPUT_JSON}
	export \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	  HZN_ORG_ID=${HZN_ORG_ID} \
	  HZN_USER_ID=${HZN_USER_ID} \
	  HZN_EXCHANGE_APIKEY=${HZN_EXCHANGE_APIKEY} \
	  && \
	  ./sh/make-machine.sh ${MACHINE} &> $@

${HORIZON_CONFIG_FILES}: config.json makefile
	@echo 'Making $@'
	@export \
	  HORIZON_EXCHANGE_HOST=${HORIZON_EXCHANGE_HOST} \
	  HORIZON_EXCHANGE_PORT=${HORIZON_EXCHANGE_PORT} \
	  HORIZON_EXCHANGE_PROTOCOL=${HORIZON_EXCHANGE_PROTOCOL} \
	  HORIZON_EXCHANGE_VERSION=${HORIZON_EXCHANGE_VERSION} \
	  HORIZON_EXCHANGE_URL=${HORIZON_EXCHANGE_URL} \
	  HORIZON_EXCHANGE_ORG=${HORIZON_EXCHANGE_ORG} \
	  HORIZON_EXCHANGE_USER=${HORIZON_EXCHANGE_USER} \
	  HORIZON_EXCHANGE_PASSWORD=${HORIZON_EXCHANGE_PASSWORD} \
	  HZN_ORG_ID=${HORIZON_EXCHANGE_ORG} \
	  HZN_USER_ID=${HORIZON_EXCHANGE_USER} \
	  HZN_EXCHANGE_APIKEY=${HORIZON_EXCHANGE_USER} \
	  HZN_EXCHANGE_URL=${HORIZON_EXCHANGE_URL} \
	&& \
	cat $@.tmpl | envsubst > $@


${EDGEX_CONFIG_FILES} ${DOCKER_COMPOSE}: config.json makefile # $@.tmpl
	@echo 'Making $@'
	@export \
	  EDGEX_COMMAND=${EDGEX_COMMAND} \
	  EDGEX_DATA=${EDGEX_DATA} \
	  EDGEX_LOGGING=${EDGEX_LOGGING} \
	  EDGEX_METADATA=${EDGEX_METADATA} \
	  EDGEX_NOTIFICATION=${EDGEX_NOTIFICATION} \
	  EDGEX_LOG_LEVEL=${EDGEX_LOG_LEVEL} \
	  EDGEX_LOG_REMOTE=${EDGEX_LOG_REMOTE} \
	  EDGEX_REGISTRY_HOST=${EDGEX_REGISTRY_HOST} \
	  EDGEX_REGISTRY_PORT=${EDGEX_REGISTRY_PORT} \
	  EDGEX_REGISTRY_TYPE=${EDGEX_REGISTRY_TYPE} \
	  COMMAND_SERVICE_HOST=${COMMAND_SERVICE_HOST} \
	  COMMAND_SERVICE_PORT=${COMMAND_SERVICE_PORT} \
	  COMMAND_SERVICE_PROTOCOL=${COMMAND_SERVICE_PROTOCOL} \
	  DATABASE_PRIMARY_HOST=${DATABASE_PRIMARY_HOST} \
	  DATABASE_PRIMARY_PORT=${DATABASE_PRIMARY_PORT} \
	  DATABASE_PRIMARY_TYPE=${DATABASE_PRIMARY_TYPE} \
	  DATA_SERVICE_HOST=${DATA_SERVICE_HOST} \
	  DATA_SERVICE_PORT=${DATA_SERVICE_PORT} \
	  DATA_SERVICE_PROTOCOL=${DATA_SERVICE_PROTOCOL} \
	  LOGGING_SERVICE_HOST=${LOGGING_SERVICE_HOST} \
	  LOGGING_SERVICE_PORT=${LOGGING_SERVICE_PORT} \
	  LOGGING_SERVICE_PROTOCOL=${LOGGING_SERVICE_PROTOCOL} \
	  METADATA_SERVICE_HOST=${METADATA_SERVICE_HOST} \
	  METADATA_SERVICE_PORT=${METADATA_SERVICE_PORT} \
	  METADATA_SERVICE_PROTOCOL=${METADATA_SERVICE_PROTOCOL} \
	  NOTIFICATION_SERVICE_HOST=${NOTIFICATION_SERVICE_HOST} \
	  NOTIFICATION_SERVICE_PORT=${NOTIFICATION_SERVICE_PORT} \
	  NOTIFICATION_SERVICE_PROTOCOL=${NOTIFICATION_SERVICE_PROTOCOL} \
	  NOTIFICATION_SMTP_ESSCERT=${NOTIFICATION_SMTP_ESSCERT} \
	  NOTIFICATION_SMTP_HOST=${NOTIFICATION_SMTP_HOST} \
	  NOTIFICATION_SMTP_PORT=${NOTIFICATION_SMTP_PORT} \
	  NOTIFICATION_SMTP_PASSWORD=${NOTIFICATION_SMTP_PASSWORD} \
	  NOTIFICATION_SMTP_SENDER=${NOTIFICATION_SMTP_SENDER} \
	  NOTIFICATION_SMTP_SUBJECT=${NOTIFICATION_SMTP_SUBJECT} \
	  NOTIFICATION_SMTP_USERNAME=${NOTIFICATION_SMTP_USERNAME} \
	&& \
	cat $@.tmpl | envsubst > $@

up: ${DOCKER_COMPOSE}
	docker-compose up -d

down: ${DOCKER_COMPOSE}
	docker-compose down

## ADMINISTRIVIA

.PHONY: keys config up down clean prime reset-db realclean distclean tidy

tidy:
	-@rm -fr *.out

clean: tidy
	-@rm -fr ${DOCKER_COMPOSE} ${EDGEX_CONFIG_FILES} ${HORIZON_CONFIG_FILES} *.out

realclean:  clean
	-@docker rm -f ${EDGEX_CONTAINERS}
	-@docker volume prune -f
	-@rm -fr certs

distclean: realclean
	-@docker system prune -f
