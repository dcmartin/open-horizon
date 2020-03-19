ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

# Install base system
RUN apt-get update && apt-get install -q -y --no-install-recommends \
  ca-certificates \
  curl \
  jq \
  socat \
  mosquitto-clients \
  kafkacat 

# Copy root file-system
COPY rootfs /

CMD [ "/usr/bin/run.sh" ]

# Build arguments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.name="mqtt2kafka" \
    org.label-schema.description="route mqtt to kafka" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/mqtt2kafka/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
