###
### make(1) file for setting up sdr2msghub pattern and services
###

##
## TARGETS:
##

# register - register the services and patterns
# services - register the services
# patterns - register the pattern
# 

## ARCHITECTURE
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/'))

## HORIZON EXCHANGE
EXCHANGE_VERSION := $(shell jq -r '.horizon.exchange.version' config.json)
EXCHANGE_HOST := $(shell jq -r '.horizon.exchange.host' config.json)
EXCHANGE_PROTOCOL := $(shell jq -r '.horizon.exchange.protocol' config.json)
EXCHANGE_PORT := $(shell jq -r '.horizon.exchange.port' config.json)
EXCHANGE_ORG := $(shell jq -r '.horizon.exchange.org' config.json)
EXCHANGE_USER := $(shell jq -r '.horizon.exchange.user' config.json)
EXCHANGE_APIKEY := $(shell jq -r '.horizon.exchange.apikey' config.json)

CSS_HOST := $(shell jq -r '.horizon.css.host' config.json)
CSS_PROTOCOL := $(shell jq -r '.horizon.css.protocol' config.json)
CSS_PORT := $(shell jq -r '.horizon.css.port' config.json)

## ENVIRONMENT
HZN_USER_ID ?= $(if $(wildcard HZN_USER_ID),$(shell cat HZN_USER_ID),${EXCHANGE_USER})
HZN_ORG_ID ?= $(if $(wildcard HZN_ORG_ID),$(shell cat HZN_ORG_ID),${EXCHANGE_ORG})
HZN_EXCHANGE_APIKEY ?= $(if $(wildcard HZN_EXCHANGE_APIKEY),$(shell cat HZN_EXCHANGE_APIKEY),${EXCHANGE_APIKEY})
HZN_EXCHANGE_URL ?= $(if $(wildcard HZN_EXCHANGE_URL),$(shell cat HZN_EXCHANGE_URL),${EXCHANGE_PROTOCOL}://${EXCHANGE_HOST}:${EXCHANGE_PORT}/${EXCHANGE_VERSION})
HZN_FSS_CSSURL ?= $(if $(wildcard HZN_FSS_CSSURL),$(shell cat HZN_FSS_CSSURL),${CSS_PROTOCOL}://${CSS_HOST}:${CSS_PORT})

## PACKAGE
HZNPKG_URL ?= $(if $(wildcard ../HZNPKG_URL),$(shell cat ../HZNPKG_URL),"http://pkg.bluehorizon.network")
HZNPKG_KEY ?= $(if $(wildcard ../HZNPKG_KEY),$(shell cat ../HZNPKG_KEY),"{HZNPKG_URL}/bluehorizon.network-key.pub}")
HZNPKG_TYPE ?= $(if $(wildcard ../HZNPKG_TYPE),$(shell cat ../HZNPKG_TYPE),"linux")
HZNPKG_DIST ?= $(if $(wildcard ../HZNPKG_DIST),$(shell cat ../HZNPKG_DIST),"ubuntu")
HZNPKG_RELEASE ?= $(if $(wildcard ../HZNPKG_RELEASE),$(shell cat ../HZNPKG_RELEASE),"xenial")
HZNPKG_REPO ?= $(if $(wildcard ../HZNPKG_REPO),$(shell cat ../HZNPKG_REPO),"updates")

## STARTUP
STARTUP_KAFKA_APIKEY ?= $(if $(wildcard STARTUP_KAFKA_APIKEY),$(shell cat STARTUP_KAFKA_APIKEY),"STARTUP_KAFKA_APIKEY")
STARTUP_HOST_USER ?= $(if $(wildcard STARTUP_HOST_USER),$(shell cat STARTUP_HOST_USER),"root")

## this host
THIS_HOSTIP := $(shell ifconfig | egrep 'inet ' | awk '{ print $$2 }' | egrep -v '^172.|^10.|^127.' | head -1)

## machine to register
MACHINE ?= $(if $(wildcard NODES),$(shell cat NODES),"localhost")

###
### TARGETS
###

PATTERN_ID := sdr2msghub
PATTERN_DIR := ${PWD}/${PATTERN_ID}
INPUT_JSON := ${PATTERN_DIR}/userinput.json
PATTERN_JSON := ${PATTERN_DIR}/pattern.json
ALL_PATTERN_JSON := ${PATTERN_JSON} ${INPUT_JSON}

GPS_SERVICE := ibm.gps
SDR_SERVICE := ibm.sdr
SDR2MSGHUB_SERVICE := ibm.sdr2msghub
ALL_SERVICES := ${GPS_SERVICE} ${SDR_SERVICE} ${SDR2MSGHUB_SERVICE}

GPS_SERVICE_JSON := ${PWD}/${GPS_SERVICE}/service.json
SDR_SERVICE_JSON := ${PWD}/${SDR_SERVICE}/service.json
SDR2MSGHUB_SERVICE_JSON := ${PWD}/${SDR2MSGHUB_SERVICE}/service.json
ALL_SERVICES_JSON := ${GPS_SERVICE} ${SDR_SERVICE} ${SDR2MSGHUB_SERVICE}

ALL_JSON := ${PATTERN_JSON} ${INPUT_JSON} ${ALL_SERVICES_JSON}

default: publish ${ALL_JSON}

publish: ${ALL_SERVICES} pattern

register: publish ${MACHINE} 

# create keys

KEYS := key.pem key.pub

${KEYS}:
	hzn key create $$(whoami) $$(hostname) -k key.pem -K key.pub

# publish services and pattern

pattern: ${ALL_SERVICES} ${PATTERN_JSON}
	@echo "$$(date +%FT%TZ) publishing pattern: ${PATTERN_ID}"
	@export STARTUP_KAFKA_APIKEY=${STARTUP_KAFKA_APIKEY} \
	  STARTUP_HOST_USER=${STARTUP_HOST_USER} \
	  HZN_ORG_ID=${HZN_ORG_ID} \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	&& \
        hzn exchange pattern publish \
	  -o "${HZN_ORG_ID}" \
	  -u ${HZN_USER_ID}:${HZN_EXCHANGE_APIKEY} \
	  -f ${PATTERN_JSON} \
	  -p ${PATTERN_ID} \
	  -k key.pem \
	  -K key.pub

${ALL_SERVICES}: ${KEYS}
	@echo "$$(date +%FT%TZ) publishing service: $@"
	@export \
	  HZN_ORG_ID=${HZN_ORG_ID} \
	  HZN_USER_ID=${HZN_USER_ID} \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	  HZN_EXCHANGE_APIKEY=${HZN_EXCHANGE_APIKEY} \
	&& \
	./publish.sh $@ ${KEYS}

# register a machine

${MACHINE}: ${INPUT_JSON}
	export \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	  HZN_ORG_ID=${HZN_ORG_ID} \
	  HZN_USER_ID=${HZN_USER_ID} \
	  HZN_EXCHANGE_APIKEY=${HZN_EXCHANGE_APIKEY} \
	&& \
	  ./sh/make-machine.sh ${MACHINE} &> $@

${ALL_JSON}: makefile config.json
	F=$@ && D=$${F%/*} && F=$${F##*/} && mkdir -p $${D} && \
	export \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	  HZN_EXCHANGE_APIKEY=${HZN_EXCHANGE_APIKEY} \
	  HZN_ORG_ID=${HZN_ORG_ID} \
	  HZN_USER_ID=${HZN_USER_ID} \
	  HZN_FSS_CSSURL=${HZN_FSS_CSSURL} \
	  STARTUP_KAFKA_APIKEY=${STARTUP_KAFKA_APIKEY} \
	  STARTUP_HOST_USER=${STARTUP_HOST_USER} \
	&& \
	  cat $@.tmpl | envsubst > $@

## ADMINISTRIVIA

.PHONY: pattern publish register ${ALL_SERVICES} ${PATTERN_ID}

remove:
	-rm -fr ${ALL_JSON} ${MACHINE}

clean: remove
	
realclean: clean
	for s in ${SERVICES}; do echo "deleting service $${s} $$(../sh/delservices.sh $${s})"; done
	for p in ${PATTERN_ID}; do echo "deleting pattern $${p} $$(../sh/delpatterns.sh $${p})"; done

distclean: realclean
	-rm -f ${KEYS} 
