###
### makefile
###

SHELL := /bin/bash

## HOSTIP
THIS_HOSTIP := $(shell ifconfig | egrep 'inet ' | awk '{ print $$2 }' | egrep -v '^172.|^10.|^127.' | head -1)

###
### VARIABLES
###

## HZN
HZN_EXCHANGE_URL ?= $(if $(wildcard HZN_EXCHANGE_URL),$(shell v=$$(cat HZN_EXCHANGE_URL) && echo "** SPECIFIED: HZN_EXCHANGE_URL: $${v}" > /dev/stderr && echo "$${v}"),$(shell v="http://${EXCHANGE_HOSTNAME}:3090/v1/" && echo "!! UNSPECIFIED: HZN_EXCHANGE_URL unset; default: $${v}" > /dev/stderr && echo "$${v}"))
HZN_FSS_CSSURL ?= $(if $(wildcard HZN_FSS_CSSURL),$(shell v=$$(cat HZN_FSS_CSSURL) && echo "** SPECIFIED: HZN_FSS_CSSURL: $${v}" > /dev/stderr && echo "$${v}"),$(shell v="http://${EXCHANGE_HOSTNAME}:9443/css/" && echo "!! UNSPECIFIED: HZN_FSS_CSSURL unset; default: $${v}" > /dev/stderr && echo "$${v}"))
HZN_ORG_ID ?= $(if $(wildcard HZN_ORG_ID),$(shell v=$$(cat HZN_ORG_ID) && echo "** SPECIFIED: HZN_ORG_ID: $${v}" > /dev/stderr && echo "$${v}"),$(shell v=$${USER} && echo "!! UNSPECIFIED: HZN_ORG_ID unset; default: $${v}" > /dev/stderr && echo "$${v}"))
HZN_USER_ID ?= $(if $(wildcard HZN_USER_ID),$(shell v=$$(cat HZN_USER_ID) && echo "** SPECIFIED: HZN_USER_ID: $${v}" > /dev/stderr && echo "$${v}"),$(shell v=$${USER} && echo "!! UNSPECIFIED: HZN_USER_ID unset; default: $${v}" > /dev/stderr && echo "$${v}"))
HZN_EXCHANGE_APIKEY ?= $(if $(wildcard HZN_EXCHANGE_APIKEY),$(shell v=$$(cat HZN_EXCHANGE_APIKEY) && echo "** SPECIFIED: HZN_EXCHANGE_APIKEY: $${v}" > /dev/stderr && echo "$${v}"),$(shell v='whocares' && echo "!! UNSPECIFIED: HZN_EXCHANGE_APIKEY unset; default: $${v}" > /dev/stderr && echo "$${v}"))

## EXCHANGE
EXCHANGE_HOSTNAME ?= $(if $(wildcard EXCHANGE_HOSTNAME),$(shell v=$$(cat EXCHANGE_HOSTNAME) && echo "** SPECIFIED: EXCHANGE_HOSTNAME: $${v}" > /dev/stderr && echo "$${v}"),$(shell v=$(THIS_HOSTIP) && echo "!! UNSPECIFIED: EXCHANGE_HOSTNAME unset; default: $${v}" > /dev/stderr && echo "$${v}"))
EXCHANGE_NAMESPACE ?= $(if $(wildcard EXCHANGE_NAMESPACE),$(shell v=$$(cat EXCHANGE_NAMESPACE) && echo "** SPECIFIED: EXCHANGE_NAMESPACE: $${v}" > /dev/stderr && echo "$${v}"),$(shell v='oh' && echo "!! UNSPECIFIED: EXCHANGE_NAMESPACE unset; default: $${v}" > /dev/stderr && echo "$${v}"))
EXCHANGE_NETWORK ?= $(if $(wildcard EXCHANGE_NETWORK),$(shell v=$$(cat EXCHANGE_NETWORK) && echo "** SPECIFIED: EXCHANGE_NETWORK: $${v}" > /dev/stderr && echo "$${v}"),$(shell v='hznnet' && echo "!! UNSPECIFIED: EXCHANGE_NETWORK unset; default: $${v}" > /dev/stderr && echo "$${v}"))
EXCHANGE_NETWORK_DRIVER ?= $(if $(wildcard EXCHANGE_NETWORK_DRIVER),$(shell v=$$(cat EXCHANGE_NETWORK_DRIVER) && echo "** SPECIFIED: EXCHANGE_NETWORK_DRIVER: $${v}" > /dev/stderr && echo "$${v}"),$(shell v='bridge' && echo "!! UNSPECIFIED: EXCHANGE_NETWORK_DRIVER unset; default: $${v}" > /dev/stderr && echo "$${v}"))
EXCHANGE_ROOT ?= $(if $(wildcard EXCHANGE_ROOT),$(shell v=$$(cat EXCHANGE_ROOT) && echo "** SPECIFIED: EXCHANGE_ROOT: $${v}" > /dev/stderr && echo "$${v}"),$(shell v='root' && echo "!! UNSPECIFIED: EXCHANGE_ROOT unset; default: $${v}" > /dev/stderr && echo "$${v}"))
EXCHANGE_PASSWORD ?= $(if $(wildcard EXCHANGE_PASSWORD),$(shell cat EXCHANGE_PASSWORD),$(shell jq -r '.services.exchange.password' exchange/config.json.tmpl))

## VERSIONS
# EXCHANGE
EXCHANGE_TAG ?= $(if $(wildcard EXCHANGE_TAG),$(shell v=$$(cat EXCHANGE_TAG) && echo "** SPECIFIED: EXCHANGE_TAG: $${v}" > /dev/stderr && echo "$${v}"),$(shell v=$$(jq -r '.services.exchange.stable' exchange/config.json.tmpl) && echo "!! UNSPECIFIED: EXCHANGE_TAG unset; default: $${v}" > /dev/stderr && echo "$${v}"))
# CSS
CSS_TAG ?= $(if $(wildcard CSS_TAG),$(shell v=$$(cat CSS_TAG) && echo "** SPECIFIED: CSS_TAG: $${v}" > /dev/stderr && echo "$${v}"),$(shell v=$$(jq -r '.services.css.stable' exchange/config.json.tmpl) && echo "!! UNSPECIFIED: CSS_TAG unset; default: $${v}" > /dev/stderr && echo "$${v}"))
# AGBOT
AGBOT_TAG ?= $(if $(wildcard AGBOT_TAG),$(shell v=$$(cat AGBOT_TAG) && echo "** SPECIFIED: AGBOT_TAG: $${v}" > /dev/stderr && echo "$${v}"),$(shell v=$$(jq -r '.services.agbot.stable' exchange/config.json.tmpl) && echo "!! UNSPECIFIED: AGBOT_TAG unset; default: $${v}" > /dev/stderr && echo "$${v}"))

###
### TARGETS
###

ACTIONS := tidy clean

default:
	@echo 'These are the targets: exchange, agent, services, all, tidy, and clean; run "make all" to setup everything'

all: exchange agent services

${ACTIONS}:
	@${MAKE} -C exchange $@
	@${MAKE} -C services $@

build:
	@${MAKE} -C services $@

## EXCHANGE

exchange: exchange/config.json
	@echo "making $@"
	${MAKE} -C $@ all up
	@echo -n 'Waiting for exchange '
	@while [ -z "$$(curl -qsSL 127.0.0.1:3090/v1/admin/version 2> /dev/null)" ]; do echo -n '.'; sleep 5; done && echo -n ' operational' || echo ' non-operational'
	${MAKE} -C $@ prime
	@echo 'Now install agent using script sh/get.horizon.sh'

exchange/config.json: exchange/config.json.tmpl
	@echo "making $@"
	@export \
	  EXCHANGE_HOSTNAME="$(EXCHANGE_HOSTNAME)" \
	  EXCHANGE_NAMESPACE="${EXCHANGE_NAMESPACE}" \
	  EXCHANGE_NETWORK="${EXCHANGE_NETWORK}" \
	  EXCHANGE_NETWORK_DRIVER="${EXCHANGE_NETWORK_DRIVER}" \
	  EXCHANGE_TAG="$(EXCHANGE_TAG)" \
	  CSS_TAG="$(CSS_TAG)" \
	  AGBOT_TAG="$(AGBOT_TAG)" \
	  HZN_FSS_CSSURL="$(HZN_FSS_CSSURL)" \
	  HZN_EXCHANGE_URL="$(HZN_EXCHANGE_URL)" \
	  HZN_EXCHANGE_APIKEY="$(HZN_EXCHANGE_APIKEY)" \
	  HZN_ORG_ID="$(HZN_ORG_ID)" \
	  HZN_USER_ID="$(HZN_USER_ID)" \
	&& cat $< \
	| envsubst \
	| jq '.services.exchange.password="'"${EXCHANGE_PASSWORD}"'"' \
	| jq '.services.exchange.encoded="$(shell htpasswd -bnBC 10 "" "$(EXCHANGE_PASSWORD)" | tr -d ':\n' | sed 's/$$2y/$$2a/')"' > $@

## AGENT

agent: exchange/config.json
	@echo "making $@"
	sudo ./sh/get.horizon.sh ${HZN_EXCHANGE_URL} ${HZN_FSS_CSSURL}

## SERVICES

services/HZN_EXCHANGE_APIKEY: makefile
	@echo ${HZN_EXCHANGE_APIKEY} > $@

services/HZN_ORG_ID: makefile
	@echo ${HZN_ORG_ID} > $@

services/HZN_USER_ID: makefile
	@echo ${HZN_USER_ID} > $@

services/HZN_EXCHANGE_URL: makefile
	@echo ${HZN_EXCHANGE_URL} > $@

HZN_VARIABLES := \
	services/HZN_EXCHANGE_URL \
	services/HZN_EXCHANGE_APIKEY \
	services/HZN_ORG_ID \
	services/HZN_USER_ID

services: ${HZN_VARIABLES}
	@echo "making $@"
	@export \
	  HZN_EXCHANGE_URL="$(HZN_EXCHANGE_URL)" \
	  HZN_ORG_ID="$(HZN_ORG_ID)" \
	  HZN_USER_ID="$(HZN_USER_ID)" \
	&& ${MAKE} -C $@ push publish

hznmonitor: ${HZN_VARIABLES} KAFKA_APIKEY MQTT_HOST MQTT_USERNAME MQTT_PASSWORD
	@echo "making $@"
	@export \
	  BASES='base-ubuntu apache-ubuntu' \
	  SERVICES='hznmonitor' \
	  HZN_EXCHANGE_URL="$(HZN_EXCHANGE_URL)" \
	  HZN_ORG_ID="$(HZN_ORG_ID)" \
	  HZN_USER_ID="$(HZN_USER_ID)" \
	&& ${MAKE} -C services push publish
	${MAKE} -C services/hznmonitor

## ADMINISTRIVIA

.PHONY: default exchange/config.json $(ACTIONS) services exchange agent all build hznmonitor 
