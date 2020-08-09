ARG BUILD_FROM

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN apk add --no-cache \
  bc \
  coreutils \
  curl \
  jq \
  dateutils \
  findutils

# Build arguments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.name="homeassistant" \
    org.label-schema.description="home-assistant" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/services/homeassistant/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
