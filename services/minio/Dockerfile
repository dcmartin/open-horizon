# Build arguments
ARG BUILD_FROM

# source to build this container 
FROM ${BUILD_FROM}

# architecture
ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color"

# fail on pipe failurs
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  DEBIAN_FRONTEND="noninteractive" apt update -qq -y \
  && \
  DEBIAN_FRONTEND="noninteractive" apt upgrade -qq -y

RUN \
  DEBIAN_FRONTEND="noninteractive" apt install -qq -y --no-install-recommends \
    git

ARG MINIO_PORT=9000
ENV MINIO_PORT=${MINIO_PORT}

RUN \
    MINIO_ARCH=$(echo "${BUILD_ARCH}" | sed "s/\([^_]*\)_.*/\1/") \
    && \
    if [ "${MINIO_ARCH}" = "amd64" ]; then MINIO_ARCH="amd64"; \
    elif [ "${MINIO_ARCH}" = "aarch64" ]; then MINIO_ARCH="arm64"; \
    elif [ "${MINIO_ARCH}" = "arm64" ]; then MINIO_ARCH="arm64"; fi \
    && \
    mkdir -p /usr/local/bin \
    && \
    curl -o /usr/local/bin/minio -sSL "https://dl.min.io/server/minio/release/linux-${MINIO_ARCH}/minio" \
    && \
    curl -o /usr/local/bin/mc -sSL "https://dl.min.io/client/mc/release/linux-${MINIO_ARCH}/mc" \
    && \
    chmod 755 /usr/local/bin/minio /usr/local/bin/mc

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
    org.label-schema.name="apache-ubuntu" \
    org.label-schema.description="Minio object-storage" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/services/minio/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
