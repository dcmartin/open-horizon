###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change - create your own HZN_ORG_ID and URL files.
##

HZN_ORG_ID ?= $(if $(wildcard HZN_ORG_ID),$(shell cat HZN_ORG_ID),HZN_ORG_ID)

# tag this build environment
TAG ?= $(if $(wildcard TAG),$(shell cat TAG),)

# hard code architecture for build environment
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),$(shell uname -m | sed -e 's/aarch64.*/arm64/' -e 's/x86_64.*/amd64/' -e 's/armv.*/arm/'))
NVIDIA_RUNTIME := $(shell docker info --format '{{ json . }}' | jq '.DefaultRuntime=="nvidia"')

##
## things NOT TO change
##

BASES := base-alpine base-ubuntu apache-alpine apache-ubuntu 
SERVICES :=  cpu hal wan hzncli herald mqtt fft motion2mqtt hznmonitor noize yolo yolo4motion alpr alpr4motion face face4motion mqtt2kafka
WIP := mqtt2mqtt record hotword 
PATTERNS := startup # hznsetup
MISC := setup sh doc

# intel/amd64 + GPU
ifeq ($(BUILD_ARCH), amd64)
ifeq ($(NVIDIA_RUNTIME), true)
GPU_BASES += base-cuda
GPU_SERVICES += yolo-cuda yolo-cuda4motion
endif
endif

# jetson nano (maybe tx2)
ifeq ($(BUILD_ARCH), arm64)
ifeq ($(NVIDIA_RUNTIME), true)
GPU_BASES += base-tegra
GPU_SERVICES += yolo-tegra yolo-tegra4motion
endif
endif

BASES += $(GPU_BASES)
SERVICES += $(GPU_SERVICES)

# all
ALL = $(BASES) $(SERVICES) $(PATTERNS) # ${WIP}

##
## targets
##

TARGETS = all tidy clean distclean build push publish verify build-service push-service start-service publish-service test-service verify-service clean-service service-build service-push service-publish service-verify service-test service-stop service-clean horizon

## actual

default: build

all: build push $(KEYS) publish

## KEYS
PRIVATE_KEY_FILE ?= ${HZN_ORG_ID}.key
PUBLIC_KEY_FILE ?= ${HZN_ORG_ID}.pem
KEYS := $(PRIVATE_KEY_FILE) $(PUBLIC_KEY_FILE)

$(KEYS):
	@hzn key create -f -k ${PRIVATE_KEY_FILE} -K ${PUBLIC_KEY_FILE} ${HZN_ORG_ID} ${HZN_USER_ID}@${HZN_ORG_ID}

## GPU only

gpu: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- building $@""${NC}" &> /dev/stderr
	@for dir in ${GPU_BASES} ${GPU_SERVICES}; do \
	  $(MAKE) TAG=${TAG} HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir build; \
	  $(MAKE) TAG=${TAG} HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir push; \
	done

## all

$(ALL): $(KEYS)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- making $@""${NC}" &> /dev/stderr
	$(MAKE) TAG=${TAG} HZN_ORG_ID=$(HZN_ORG_ID)  -C $@

$(TARGETS): $(KEYS)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- making $@ in ${ALL}""${NC}" &> /dev/stderr
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

pattern-publish: ${KEYS}
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing $(PATTERNS)""${NC}" &> /dev/stderr
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=${TAG} HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

pattern-validate: $(KEYS)
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- validating $(PATTERNS)""${NC}" &> /dev/stderr
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=${TAG} HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

.PHONY: ${ALL} default all build run check stop push publish verify clean start test sync

CLOC.md: .gitignore .
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- counting source code""${NC}" &> /dev/stderr
	@cloc --md --exclude-list-file=.gitignore . > CLOC.md

.PHONY:	${BASES} ${SERVICES} ${PATTERNS} ${JETSONS} ${MISC} ${WIP}

##
## COLORS
##
MC=${LIGHT_BLUE}
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
