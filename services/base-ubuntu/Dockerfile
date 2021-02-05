# Build arguments
ARG BUILD_FROM

# source to build this container 
FROM ${BUILD_FROM}

# architecture
ARG BUILD_ARCH=amd64

# fail on pipe failurs
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color"

# BASE requirements

RUN \
    DEBIAN_FRONTEND="noninteractive" apt update -qq -y \
    && \
    DEBIAN_FRONTEND="noninteractive" apt upgrade -qq -y \
    && \
    DEBIAN_FRONTEND="noninteractive" apt install -qq -y --no-install-recommends \
      apt-utils \
      bc \
      ca-certificates \
      curl \
      jq \
      socat \
      software-properties-common \
      tzdata

## BASHIO Home Assistant integration

RUN \
    S6_ARCH=$(echo ${BUILD_ARCH} | sed "s/\([^_]*\)_.*/\1/") \
    && \
    echo "${S6_ARCH}" \
    && \
    if [ "${S6_ARCH}" = "i386" ]; then S6_ARCH="x86"; \
    elif [ "${S6_ARCH}" = "armv7" ]; then S6_ARCH="arm"; \
    elif [ "${S6_ARCH}" = "armhf" ]; then S6_ARCH="arm"; \
    elif [ "${S6_ARCH}" = "amd64" ]; then S6_ARCH="amd64"; \
    elif [ "${S6_ARCH}" = "aarch64" ]; then S6_ARCH="aarch64"; \
    elif [ "${S6_ARCH}" = "arm64" ]; then S6_ARCH="aarch64"; fi \
    && \
    curl -sSL "https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-${S6_ARCH}.tar.gz" | tar zxf - -C / \
    && \
    mkdir -p /etc/fix-attrs.d \
    && \
    mkdir -p /etc/services.d

RUN \
    curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.10.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

## CLEANUP

RUN \
  DEBIAN_FRONTEND="noninteractive" apt clean -qq -y \
  && \
  DEBIAN_FRONTEND="noninteractive" apt autoremove -qq -y \
  && \
  rm -fr \
  /tmp/* \
  /var/{cache,log}/* \
  /var/lib/apt/lists/*

# Entrypoint (for everyone downstream, unless they over-ride)
ENTRYPOINT [ "/init" ]

# Copy root file-system
COPY rootfs /

CMD [ "/usr/bin/run.sh" ]

ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.name="apache-ubuntu" \
    org.label-schema.description="Base Ubuntu 18.04 LTS with Open Horizon and Home Assistant integration" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/services/base-ubuntu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"

