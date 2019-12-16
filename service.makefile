## ARCHITECTURE
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/'))

## HORIZON EXCHANGE
HZN_USER_ID ?= $(if $(wildcard ../HZN_USER_ID),$(shell cat ../HZN_USER_ID),"iamapikey")
HZN_ORG_ID ?= $(if $(wildcard ../HZN_ORG_ID),$(shell cat ../HZN_ORG_ID),HZN_ORG_ID_UNSPECIFIED)
HZN_EXCHANGE_URL ?= $(if $(wildcard ../HZN_EXCHANGE_URL),$(shell cat ../HZN_EXCHANGE_URL),"https://alpha.edge-fabric.com/v1/")
HZN_FSS_CSSURL ?= $(if $(wildcard ../HZN_FSS_CSSURL),$(shell cat ../HZN_FSS_CSSURL),"https://alpha.edge-fabric.com/css/")
HZN_VERSION ?= $(if $(wildcard ../HZN_VERSION),$(shell cat ../HZN_VERSION),"v1")

## PACKAGE
HZNPKG_URL ?= $(if $(wildcard ../HZNPKG_URL),$(shell cat ../HZNPKG_URL),"http://pkg.bluehorizon.network")
HZNPKG_KEY ?= $(if $(wildcard ../HZNPKG_KEY),$(shell cat ../HZNPKG_KEY),"{HZNPKG_URL}/bluehorizon.network-public.key}")
HZNPKG_TYPE ?= $(if $(wildcard ../HZNPKG_TYPE),$(shell cat ../HZNPKG_TYPE),"linux")
HZNPKG_DIST ?= $(if $(wildcard ../HZNPKG_DIST),$(shell cat ../HZNPKG_DIST),"ubuntu")
HZNPKG_RELEASE ?= $(if $(wildcard ../HZNPKG_RELEASE),$(shell cat ../HZNPKG_RELEASE),"xenial")
HZNPKG_REPO ?= $(if $(wildcard ../HZNPKG_REPO),$(shell cat ../HZNPKG_REPO),"updates")

## GIT
GIT_REMOTE_URL=$(shell git remote get-url origin)

## HZN
IBM ?= $(shell ibmcloud account show | egrep "Account Owner" | sed 's/.*:[ ]*\([^ ]*\) /\1/g')
DIR ?= horizon
TAG ?= $(if $(wildcard ../TAG),$(shell cat ../TAG),)

## SERVICE
SERVICE_JSON := $(if $(wildcard service.json),service.json,"/dev/null")

## SYNC
SYNC_SERVICE := $(shell jq -r '.sync==true' $(SERVICE_JSON))

## SERVICE
SERVICE_LABEL := $(shell jq -r '.deployment.services|to_entries|first|.key' $(SERVICE_JSON))
SERVICE_LABEL := $(if $(SERVICE_LABEL),$(SERVICE_LABEL),$(shell pwd -P | sed 's|.*/||'))
SERVICE_NAME = $(if ${TAG},${SERVICE_LABEL}-${TAG},${SERVICE_LABEL})
SERVICE_VERSION = $(shell jq -r '.version' $(SERVICE_JSON) | envsubst)
SERVICE_TAG = "${DOCKER_NAMESPACE}/${SERVICE_URL}_${SERVICE_VERSION}_${BUILD_ARCH}"
SERVICE_URI := $(shell jq -r '.url' $(SERVICE_JSON) | envsubst)
SERVICE_URL = $(if ${TAG},${SERVICE_URI}-${TAG},${SERVICE_URI})
SERVICE_REQVARS := $(shell jq -r '.userInput[]|select(.defaultValue==null).name' $(SERVICE_JSON) 2> /dev/null)
SERVICE_VARIABLES := $(shell jq -r '.userInput[].name' $(SERVICE_JSON) 2> /dev/null)
SERVICE_ARCH_SUPPORT := $(shell jq -r '.build_from|to_entries[]|select(.value!=null).key' build.json 2> /dev/null)

## KEYS
PRIVATE_KEY_FILE := $(if $(wildcard ../${HZN_ORG_ID}*.key),$(wildcard ../${HZN_ORG_ID}*.key),MISSING_PRIVATE_KEY_FILE)
PUBLIC_KEY_FILE := $(if $(wildcard ../${HZN_ORG_ID}*.pem),$(wildcard ../${HZN_ORG_ID}*.pem),MISSING_PUBLIC_KEY_FILE)
KEYS := $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

## IBM Cloud API Key
APIKEY := $(if $(wildcard ../HZN_EXCHANGE_APIKEY),$(shell cat ../HZN_EXCHANGE_APIKEY > APIKEY && echo APIKEY),$(if $(wildcard ../apiKey.json),$(shell jq -r '.apiKey' ../apiKey.json > APIKEY && echo APIKEY),APIKEY_NOT_FOUND))

## docker
DOCKER_RESTART ?= $(if $(wildcard ../DOCKER_RESTART),$(shell cat ../DOCKER_RESTART),'--restart=unless-stopped')
DOCKER_REGISTRY ?= $(if $(wildcard ../DOCKER_REGISTRY),$(shell cat ../DOCKER_REGISTRY),$(if $(wildcard ../registry.json),$(shell jq -r '.registry' ../registry.json),))
DOCKER_NAMESPACE ?= $(if $(wildcard ../DOCKER_NAMESPACE),$(shell cat ../DOCKER_NAMESPACE),$(if $(wildcard ../registry.json),$(shell jq -r '.namespace' ../registry.json),$(shell whoami)))
DOCKER_REPOSITORY ?= $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE),$(DOCKER_NAMESPACE))
DOCKER_LOGIN := $(if $(wildcard ../DOCKER_LOGIN),$(shell cat ../DOCKER_LOGIN),$(if $(wildcard ../registry.json),token,))
DOCKER_PASSWORD := $(if $(wildcard ../DOCKER_PASSWORD),$(shell cat ../DOCKER_PASSWORD),$(if $(wildcard ../registry.json),$(shell jq -r '.private' ../registry.json),))
DOCKER_PUBLICKEY := $(if $(wildcard ../DOCKER_PUBLICKEY),$(shell cat ../DOCKER_PUBLICKEY),$(if $(wildcard ../registry.json),$(shell jq -r '.public' ../registry.json),))
DOCKER_SERVER := $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY),"docker.io")
DOCKER_CONFIG := $(if $(wildcard ~/.docker/config.json),$(shell jq -r '.auths|to_entries[]|select(.key|test("'$(DOCKER_SERVER)'"))' ~/.docker/config.json 2> /dev/null),)
DOCKER_LOGIN ?= $(if $(DOCKER_CONFIG),$(shell echo $(DOCKER_CONFIG) | jq -r '.value.auth' | base64 --decode | awk -F: '${ print $1 }'),)
DOCKER_PASSWORD ?= $(if $(DOCKER_CONFIG),$(shell echo $(DOCKER_CONFIG) | jq -r '.value.auth' | base64 --decode | awk -F: '${ print $2 }'),)
DOCKER_NAME = $(BUILD_ARCH)_$(SERVICE_URL)
DOCKER_TAG := $(DOCKER_REPOSITORY)/$(DOCKER_NAME):$(SERVICE_VERSION)

## ports
DOCKER_PORT ?= $(shell jq -r '.deployment.services."'${SERVICE_LABEL}'".specific_ports?|first|.HostPort' $(SERVICE_JSON) | sed 's/\([0-9]*\).*/\1/' | sed 's/null//')
SERVICE_PORT ?= $(shell jq -r '.deployment.services."'${SERVICE_LABEL}'".specific_ports?|first|.HostPort' $(SERVICE_JSON) | sed 's/[0-9]*[:]*\([0-9]*\).*/\1/' | sed 's/null//')
SERVICE_PORT := $(if ${SERVICE_PORT},${SERVICE_PORT},$(if ${DOCKER_PORT},${DOCKER_PORT},80))
DOCKER_PORT := $(if ${DOCKER_PORT},${DOCKER_PORT},$(shell echo "( $$$$ + 5000 ) % 32000 + 32000" | bc))

## BUILD
BUILD_BASE=$(shell export DOCKER_REGISTRY=$(DOCKER_REGISTRY) DOCKER_NAMESPACE=${DOCKER_NAMESPACE} DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) && jq -r ".build_from.${BUILD_ARCH}" build.json | envsubst)
BUILD_ORG=$(shell echo $(BUILD_BASE) | sed "s|\(.*\)/[^/]*|\1|")
SAME_ORG=$(shell if [ $(BUILD_ORG) = $(DOCKER_REPOSITORY) ]; then echo ${DOCKER_REPOSITORY}; else echo ""; fi)
BUILD_PKG=$(shell echo $(BUILD_BASE) | sed "s|.*/\([^:]*\):.*|\1|")
BUILD_TAG=$(shell echo $(BUILD_BASE) | sed "s|.*/[^:]*:\(.*\)|\1|")
BUILD_FROM=$(if ${TAG},$(if ${SAME_ORG},${BUILD_ORG}/${BUILD_PKG}-${TAG}:${BUILD_TAG},${BUILD_BASE}),${BUILD_BASE})

## TEST
TEST_JQ_FILTER ?= $(if $(wildcard TEST_JQ_FILTER),$(shell egrep -v '^\#' TEST_JQ_FILTER | head -1),".")
TEST_NODE_FILTER ?= $(if $(wildcard TEST_NODE_FILTER),$(shell egrep -v '^\#' TEST_NODE_FILTER | head -1),".test=.")
TEST_NODE_TIMEOUT = 10
# temporary
TEST_NODE_NAMES ?= $(if $(wildcard TEST_TMP_MACHINES),$(shell egrep -v '^\#' TEST_TMP_MACHINES),localhost)

##
## targets
##

default:
	@export MAKE=$(MAKE) && if [ -e 'service.json' ]; then $${MAKE} build run check; else $${MAKE} pattern-publish; fi

##
## support
##

$(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE):
	@echo "*** ERROR -- cannot locate $@; use command \"hzn key create\" to create keys; exiting"  > /dev/stderr && exit 1

## development

${DIR}:
	@rm -fr ${DIR} && mkdir -p ${DIR} && export HZN_USER_ID=${HZN_USER_ID} HZN_VERSION=${HZN_VERSION} HZN_ORG_ID=${HZN_ORG_ID} HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && hzn dev service new -d ${DIR} # > /dev/null

${DIR}/service.definition.json: ${SERVICE_JSON}
	@jq '.org="'${HZN_ORG_ID}'"|.label="'${SERVICE_LABEL}'"|.arch="'${BUILD_ARCH}'"|.url="'${SERVICE_URL}'"|.deployment.services=([.deployment.services|to_entries[]|select(.key=="'${SERVICE_LABEL}'")|.key="'${SERVICE_LABEL}'"|.value.image="'${DOCKER_TAG}'"]|from_entries)' $(SERVICE_JSON) > ${DIR}/service.definition.json
	@export HZN_USER_ID=${HZN_USER_ID} HZN_VERSION=${HZN_VERSION} HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} TAG=${TAG} && ./sh/fixservice.sh ${DIR}

${DIR}/userinput.json: userinput.json
	@export HZN_EXCHANGE_APIKEY=$(shell cat $(APIKEY)) SERVICE_URL=${SERVICE_URL} HZN_ORG_ID=${HZN_ORG_ID} && cat userinput.json | envsubst > ${DIR}/userinput.json
	@./sh/checkvars.sh ${DIR}

${DIR}/pattern.json: pattern.json
	-@export TAG=${TAG} && ./sh/fixpattern.sh ${DIR}

depend: $(APIKEY) ${DIR}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- fetching dependencies; service: ${SERVICE_LABEL}; dir: ${DIR}""${NC}" > /dev/stderr
	@export HZN_USER_ID=${HZN_USER_ID} HZN_VERSION=${HZN_VERSION} HZN_ORG_ID=${HZN_ORG_ID} HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} HZN_EXCHANGE_USERAUTH=${HZN_ORG_ID}/${HZN_USER_ID}:$(shell cat $(APIKEY)) TAG=${TAG} && ./sh/mkdepend.sh ${DIR}

##
## CONTAINERS
##

logs:
	docker logs -f $$(docker ps --format '{{.Image}},{{.Names}}' | egrep "${DOCKER_NAME}" | awk -F, '{ print $$2 }')

run: stop stop-service remove
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- run: ${DOCKER_NAME}; port: ${DOCKER_PORT}:${SERVICE_PORT}; tag: ${DOCKER_TAG}""${NC}" > /dev/stderr
	@export DOCKER_RESTART=$(DOCKER_RESTART) DOCKER_PORT=$(DOCKER_PORT) SERVICE_PORT=$(SERVICE_PORT) && ./sh/docker-run.sh "$(DOCKER_NAME)" "$(DOCKER_TAG)"
	@sleep 2

remove:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- remove: ${DOCKER_NAME}; tag: ${DOCKER_TAG}""${NC}" > /dev/stderr
	@docker rm -f $(DOCKER_NAME) 2> /dev/null && echo "${DOCKER_NAME} remove" || true

check:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- check: ${DOCKER_NAME}; tag: ${DOCKER_TAG}; URL: http://localhost:${DOCKER_PORT}""${NC}" > /dev/stderr
	@rm -f check.json
	@export JQ_FILTER="$(TEST_JQ_FILTER)" && curl -sSL "http://localhost:${DOCKER_PORT}" -o check.json && jq "$${JQ_FILTER}" check.json

login: ~/.docker/config.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- login: $(DOCKER_SERVER)""${NC}" > /dev/stderr
	@echo $(DOCKER_PASSWORD) | docker login -u ${DOCKER_LOGIN} --password-stdin  ${DOCKER_SERVER} 2> /dev/null \
	    || docker login 2> /dev/null \
	    || echo "${YELLOW}>>>${NC} MAKE **" $$(date +%T) "** docker login failed ${DOCKER_SERVER}""${NC}" > /dev/stderr; \

push: build # login
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- push: ${DOCKER_NAME}; tag: ${DOCKER_TAG}""${NC}" > /dev/stderr
	@docker push ${DOCKER_TAG}

##
## SERVICES
##

## build

BUILD_OUT = build.${BUILD_ARCH}_${SERVICE_URL}_${SERVICE_VERSION}.out

build: Dockerfile build.json $(SERVICE_JSON) rootfs makefile
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- build: ${SERVICE_NAME}; tag: ${DOCKER_TAG}""${NC}" > /dev/stderr
	@export DOCKER_TAG="${DOCKER_TAG}" && docker build --build-arg BUILD_REF=$$(git rev-parse --short HEAD) --build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_ARCH="$(BUILD_ARCH)" --build-arg BUILD_FROM="$(BUILD_FROM)" --build-arg BUILD_VERSION="${SERVICE_VERSION}" . -t "$(DOCKER_TAG)" > ${BUILD_OUT}

build-service: build
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- build-service: ${SERVICE_NAME}; architecture: ${BUILD_ARCH}""${NC}" > /dev/stderr
	-@export ID="${DOCKER_NAME}" && IMAGES=$$(mktemp) && docker images | egrep "$${ID}" > $${IMAGES} && COUNT=$$(cat $${IMAGES} | wc -l) && LATEST=$$(head -1 $${IMAGES} | awk '{ print $$2,$$3,$$4,$$5,$$6 }') && if [ -z "$${LATEST}" ]; then echo ">>> MAKE --" $$(date +%T) "-- failed; no image found; id: $${ID}"; else echo ">>> MAKE --" $$(date +%T) "-- built; $${COUNT} image(s) found; id: $${ID}; latest: $${LATEST}"; fi
	-@if [ "$${DEBUG:-}" = 'true' ]; then if [ -s "${BUILD_OUT}" ]; then cat ${BUILD_OUT}; else echo ">>> MAKE --" $$(date +%T) "-- no output: ${BUILD_OUT}" > /dev/stderr; fi; fi

service-build:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-build: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" > /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" build-service; \
	done

## push

push-service: 
	@$(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH=$(BUILD_ARCH) push

service-push: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pushing service: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" > /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" push-service; \
	done

## start & stop

service-start: start-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- started service: ${SERVICE_NAME}; directory: $(DIR)/""${NC}" > /dev/stderr

start-service: stop stop-service depend
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- starting service: ${SERVICE_NAME}; directory: ${DIR}""${NC}" > /dev/stderr
	@./sh/checkvars.sh ${DIR}
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && hzn dev service verify -d ${DIR}
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && if [ ${SYNC_SERVICE} = true ]; then hzn dev service start -d ${DIR}; else hzn dev service start -S -d ${DIR}; fi

start: service-start

service-stop: stop-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-stop: ${SERVICE_NAME}; directory: $(DIR)/""${NC}" > /dev/stderr

stop-service: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- stop-service: ${SERVICE_NAME}; directory: $(DIR)/""${NC}" > /dev/stderr
	-@if [ -d "${DIR}" ]; then export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && hzn dev service stop -d ${DIR} 2> /dev/null; fi
	-@$(MAKE) DOCKER_NAME=$(DOCKER_NAME) stop > /dev/null

stop:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- stop: ${DOCKER_NAME}""${NC}" > /dev/stderr
	-@docker stop "${DOCKER_NAME}" 2> /dev/null

##
## TEST
##

TEST_RESULT = ./test.${BUILD_ARCH}_${SERVICE_URL}_${SERVICE_VERSION}.out
TEST_OUTPUT = ./test.${BUILD_ARCH}_${SERVICE_URL}_${SERVICE_VERSION}.json

service-test:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-test: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" > /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) DOCKER_PORT=$(DOCKER_PORT) SERVICE_PORT=$(SERVICE_PORT) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$(BUILD_ARCH)" test-service; \
	done

test-service: start-service test
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- test-service: ${SERVICE_NAME}; version: ${SERVICE_VERSION}; arch: $(BUILD_ARCH)""${NC}" > /dev/stderr
	-@${MAKE} stop-service > /dev/null

test:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- test: ${DOCKER_TAG}""${NC}" > /dev/stderr
	@export DOCKER_PORT=$(DOCKER_PORT) SERVICE_PORT=$(SERVICE_PORT) && ./sh/test.sh "${DOCKER_TAG}" 1> ${TEST_RESULT} 2> ${TEST_OUTPUT} && cat ${TEST_OUTPUT} && cat ${TEST_RESULT}
 
## publish & verify

service-publish: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-publish: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" > /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  BUILD_ARCH="$${arch}" $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) publish-service; \
	done

publish-service: publish
	@echo "${PURPLE}>>> MAKE --" $$(date +%T) "-- publish-service: $(SERVICE_NAME); architecture: ${BUILD_ARCH}""${NC}" > /dev/stderr

publish: ${DIR} $(APIKEY) $(KEYS)
	@echo "${PURPLE}>>> MAKE --" $$(date +%T) "-- publish-service: $(SERVICE_NAME); architecture: ${BUILD_ARCH}""${NC}" > /dev/stderr
	@export HZN_USER_ID=${HZN_USER_ID} HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && if [ ! -z "$(DOCKER_PUBLICKEY)" ]; then ARGS="-r $(DOCKER_REGISTRY):${HZN_USER_ID}:$(DOCKER_PUBLICKEY)"; fi && hzn exchange service publish -I -O -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} -f ${DIR}/service.definition.json -o ${HZN_ORG_ID} -u ${HZN_USER_ID}:$(shell cat $(APIKEY)) $${ARGS:-}

service-verify: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-verify : ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" > /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" verify-service; \
	done

verify-service: verify
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- verify-service: $(SERVICE_NAME); architecture: ${BUILD_ARCH}""${NC}" > /dev/stderr

verify:$(APIKEY) $(KEYS)
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && hzn exchange service verify --public-key-file ${PUBLIC_KEY_FILE} -o ${HZN_ORG_ID} -u ${HZN_USER_ID}:$(shell cat $(APIKEY)) "${SERVICE_TAG}" > ${SERVICE_TAG}.verify.out

## clean local & exchange

service-clean:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- service-clean: ${SERVICE_NAME}; architectures: ${SERVICE_ARCH_SUPPORT}""${NC}" > /dev/stderr
	@for arch in $(SERVICE_ARCH_SUPPORT); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) BUILD_ARCH="$${arch}" clean; \
	done

exchange-clean: ${DIR}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- exchange-clean: $(SERVICE_NAME); organization: ${HZN_ORG_ID}""${NC}" > /dev/stderr
	@./sh/service-clean.sh

##
## PATTERNS
##

pattern.json:
	@echo "${RED}>>> MAKE --" $$(date +%T) "-- not a Pattern; no pattern.json; skipping""${NC}" > /dev/stderr

pattern-publish: ${APIKEY} pattern.json horizon/pattern.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pattern-publish: ${SERVICE_NAME}; organization: ${HZN_ORG_ID}; exchange: ${HZN_EXCHANGE_URL}""${NC}" > /dev/stderr
	@export HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && hzn exchange pattern publish -o "${HZN_ORG_ID}" -u ${HZN_USER_ID}:$(shell cat $(APIKEY)) -f ${DIR}/pattern.json -p ${SERVICE_NAME} -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE}

pattern-verify: pattern.json horizon/pattern.json
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- pattern-verify: ${SERVICE_NAME}; organization: ${HZN_ORG_ID}; exchange: ${HZN_EXCHANGE_URL}""${NC}" > /dev/stderr
	@export HZN_USER_ID=${HZN_USER_ID} HZN_ORG_ID=$(HZN_ORG_ID) HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && hzn exchange pattern verify -o "${HZN_ORG_ID}" -u ${HZN_USER_ID}:$(shell cat $(APIKEY)) --public-key-file ${PUBLIC_KEY_FILE} ${SERVICE_NAME}

##
## NODES
##

nodes-test: $(TEST_NODE_NAMES)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- nodes-test: $(SERVICE_NAME); nodes: ${TEST_NODE_NAMES}; date: $$(date)""${NC}" > /dev/stderr

$(TEST_NODE_NAMES):
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- node: $@: ${SERVICE_NAME}; port: $(SERVICE_PORT); date: $$(date)""${NC}" > /dev/stderr
	-@export JQ_FILTER="$(TEST_NODE_FILTER)" && START=$$(date +%s) && curl --connect-timeout $(TEST_NODE_TIMEOUT) -fsSL "http://${@}:${SERVICE_PORT}" -o test.${@}.json && FINISH=$$(date +%s) && echo "ELAPSED:" $$((FINISH-START)) && jq -c "$${JQ_FILTER}" test.${@}.json | jq -c '.test'

nodes-list:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- nodes-list: ${TEST_NODE_NAMES}""${NC}" > /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- running: ./sh/list-machine.sh $${machine}""${NC}" > /dev/stderr; \
	  ./sh/list-machine.sh $${machine} | jq; \
	done

nodes: ${DIR}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- nodes: ${TEST_NODE_NAMES}""${NC}" > /dev/stderr
	@./sh/checkvars.sh ${DIR}
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- running: ./sh/make-machine.sh $${machine}"; \
	  export \
	  HZNPKG_URL=${HZNPKG_URL} \
	  HZNPKG_KEY=${HZNPKG_KEY} \
	  HZNPKG_TYPE=${HZNPKG_TYPE} \
	  HZNPKG_DIST=${HZNPKG_DIST} \
	  HZNPKG_RELEASE=${HZNPKG_RELEASE} \
	  HZNPKG_REPO=${HZNPKG_REPO} \
	  HZN_VERSION=${HZN_VERSION} \
	  HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} \
	  HZN_FSS_CSSURL=${HZN_FSS_CSSURL} \
	  HZN_ORG_ID=${HZN_ORG_ID} \
	  HZN_USER_ID=${HZN_USER_ID} \
	  HZN_EXCHANGE_APIKEY=$(shell cat $(APIKEY)) \
	  && ./sh/make-machine.sh $${machine}; \
	done

nodes-undo:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- nodes-undo: ${TEST_NODE_NAMES}""${NC}" > /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- unregistering $${machine}" "${NC}"; \
	  ping -W 1 -c 1 $${machine} > /dev/null \
	    && export HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL} && ssh $${machine} 'hzn unregister -fr > ~/undo.log &' \
	    || echo "${RED}>>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" > /dev/stderr; \
	done

nodes-clean: nodes-undo
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- nodes-clean: ${TEST_NODE_NAMES}""${NC}" > /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- cleaning $${machine}" "${NC}"; \
	  ping -W 1 -c 1 $${machine} > /dev/null \
	    && ssh $${machine} 'IDS=$$(docker ps --format "{{.ID}}") && if [ ! -z "$${IDS}" ]; then docker rm -f $${IDS}; fi || docker system prune -fa > ~/prune.log &' \
	    || echo "${RED}>>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" > /dev/stderr; \
	done

nodes-purge: # nodes-undo nodes-clean
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- nodes-purge: ${TEST_NODE_NAMES}""${NC}" > /dev/stderr
	@for machine in $(TEST_NODE_NAMES); do \
	  echo "${MC}>>> MAKE --" $$(date +%T) "-- purging $${machine}" "${NC}" > /dev/stderr; \
	  ping -W 1 -c 1 $${machine} > /dev/null \
	    && ssh $${machine} 'docker system prune -fa && sudo apt-get remove -y bluehorizon horizon horizon-cli > ~/remove.log || sudo apt-get purge -y bluehorizon horizon horizon-cli > ~/purge.log &' \
	    || echo "${RED}"">>> MAKE **" $$(date +%T) "** not found $${machine}""${NC}" > /dev/stderr; \
	done

##
## CSS (just for `startup` service)
##

# alternative: https://alpha.edge-fabric.com/css
# https://alpha.edge-fabric.com/v1/

CSS_SERVICE := $(if $(CSS_SERVICE),$(CSS_SERVICE),'local')

CSS_OBJECT_GET:= 'status'
CSS_OBJECT_PUT:= 'config'

css-test: css-get css-put

# get the data sent by the container (default: model)
css-get:
	export OID=$$(hostname) HZN_EXCHANGE_APIKEY=${APIKEY} HZN_ORG_ID=${HZN_ORG_ID} && OID=$${OID%%.*} \
	  && ./sh/css-get.sh $${OID} ${CSS_OBJECT_GET} ${CSS_SERVICE} $${OID}.json

# send data back to the container
css-put: css-get
	export OID=$$(hostname) HZN_EXCHANGE_APIKEY=${APIKEY} HZN_ORG_ID=${HZN_ORG_ID} && OID=$${OID%%.*} && jq '.config|.hostkey="'$$(base64 ${SERVICE_LABEL})'"' $${OID}.json \
	  | ./sh/css-put.sh $${OID} ${CSS_OBJECT_PUT} ${CSS_SERVICE}

##
## CLEANUP
##

tidy:
	-@rm -f test.*.json build.*.out mkdepend.*.out

clean: remove stop-service
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- clean: ${SERVICE_NAME}; tag: ${DOCKER_TAG}""${NC}" > /dev/stderr
	@rm -fr ${DIR} check.json build.*.out test.*.out test.*.json test.*.jpeg make.out
	-@docker rmi $(DOCKER_TAG) 2> /dev/null || :

distclean: service-clean
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- distclean: ${KEYS} ${APIKEY} ${SERVICE_REQVARS} ${SERVICE_VARIABLES} TEST_TMP_*""${NC}" > /dev/stderr
	@rm -fr $(KEYS) $(APIKEY) $(SERVICE_REQVARS) ${SERVICE_VARIABLES} TEST_TMP_*

##
## BOOKKEEPING
##

.PHONY: tidy default all depend build run check test push build-service test-service push-service publish-service verify-service start-service stop-service service-start service-stop service-test service-publish service-build service-verify pattern-publish pattern-verify nodes nodes-undo nodes-list nodes-clean nodes-purge $(TEST_NODE_NAMES) clean distclean publish

##
## COLORS
##
MC=${LIGHT_CYAN}
TEST_BAD=${LIGHT_RED}
TEST_GOOD=${LIGHT_GREEN}
NC=${NO_COLOR}

NO_COLOR=\033[0m
BLACK=\033[0;30m
RED=\033[0;31m
GREEN=\033[0;32m
BROWN_ORANGE=\033[0;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
LIGHT_GRAY=\033[0;37m

DARK_GRAY=\033[1;30m
LIGHT_RED=\033[1;31m
LIGHT_GREEN=\033[1;32m
YELLOW=\033[1;33m
LIGHT_BLUE=\033[1;34m
LIGHT_PURPLE=\033[1;35m
LIGHT_CYAN=\033[1;36m
WHITE=\034[1;37m
