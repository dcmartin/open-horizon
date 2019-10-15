###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change - create your own HZN_HZN_ORG_ID_ID and URL files.
##

HZN_ORG_ID ?= $(if $(wildcard HZN_ORG_ID),$(shell cat HZN_ORG_ID),HZN_ORG_ID)
HZN_USER_ID ?= $(if $(wildcard HZN_USER_ID),$(shell cat HZN_USER_ID),HZN_USER_ID)

# tag this build environment
TAG ?= $(if $(wildcard TAG),$(shell cat TAG),)

# hard code architecture for build environment
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),)

##
## things NOT TO change
##

SERVICES := base-alpine base-ubuntu cpu hal wan mqtt apache-ubuntu hznsetup hznmonitor yolo yolo4motion # yolo-cuda yolo4motion-cuda mqtt2mqtt 
PATTERNS := hznsetup startup yolo4motion motion2mqtt motion2mqtt+yolo4motion
MISC := setup sh doc

ALL = $(SERVICES) $(PATTERNS)

##
## targets
##
CLEAN_TARGETS = clean realclean distclean 
SERVICE_TARGETS = build push publish service-build service-push service-publish
PATTERN_TARGETS = pattern-publish
ALL_TARGETS = $(CLEAN_TARGETS) $(SERVICE_TARGETS) $(PATTERN_TARGETS)

## actual

default: build

services: $(SERVICE_TARGETS)

patterns: $(PATTERN_TARGETS)

$(ALL_TARGETS):
	@echo "$(MC)>>> MAKE --" $$(date +%T) "-- making $@""$(NC)" &> /dev/stderr
	$(MAKE) TAG=$(TAG) HZN_USER_ID=$(HZN_USER_ID) HZN_ORG_ID=$(HZN_ORG_ID)  -C $@

$(SERVICE_TARGETS):
	@echo "$(MC)>>> MAKE --" $$(date +%T) "-- making $@""$(NC)" &> /dev/stderr
	@for dir in $(SERVICES); do \
	  echo "$(MC)>>> MAKE --" $$(date +%T) "-- making $@ in $${dir}""$(NC)" &> /dev/stderr; \
	  $(MAKE) TAG=$(TAG) HZN_USER_ID=$(HZN_USER_ID) HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

$(PATTERN_TARGETS):
	@echo "$(MC)>>> MAKE --" $$(date +%T) "-- publishing $(PATTERNS)""$(NC)" &> /dev/stderr
	@for dir in $(PATTERNS); do \
	  echo "$(MC)>>> MAKE --" $$(date +%T) "-- making $@ in $${dir}""$(NC)" &> /dev/stderr; \
	  $(MAKE) TAG=$(TAG) HZN_USER_ID=$(HZN_USER_ID) HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

.PHONY: $(ALL_TARGETS)

##
## COLORS
##
MC=$(LIGHT_BLUE)
NC=$(NO_COLOR)

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
