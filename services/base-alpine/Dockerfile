ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH=amd64

ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color"

# Set shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN \
    set -o pipefail \
    \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    \
    && apk add --no-cache --virtual .build-dependencies \
        tar=1.32-r1 \
    \
    && apk add --no-cache \
        libcrypto1.1=1.1.1g-r0 \
        libssl1.1=1.1.1g-r0 \
        musl-utils=1.1.24-r9 \
        musl=1.1.24-r9 \
    \
    && apk add --no-cache \
        bash=5.0.17-r0 \
        curl=7.69.1-r0 \
        jq=1.6-r1 \
        tzdata=2020a-r0
    
RUN S6_ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "i386" ]; then S6_ARCH="x86"; fi \
    && if [ "${BUILD_ARCH}" = "armv7" ] || [ "${BUILD_ARCH}" = 'armhf' ]; then S6_ARCH="arm"; fi \
    && if [ $(echo "${BUILD_ARCH}" | sed 's/arm64.*/arm64/') = 'arm64' ]; then S6_ARCH="aarch64"; fi \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.9.0.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -f -r \
        /tmp/*


# Install base system
RUN \
    set -o pipefail \
    \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    \
    && apk add --no-cache \
        apk-tools \
        bash \
        bc \
        curl \
        jq \
        coreutils \
        socat \
    \
    && rm -fr \
        /tmp/*

# Copy root filesystem
COPY rootfs /

# set entrypoint
ENTRYPOINT ["/init"]

# set start command
CMD [ "/usr/bin/run.sh" ]

# Build arguments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-arch="${BUILD_ARCH}" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.name="base-alpine" \
    org.label-schema.description="base alpine container" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/base-alpine/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
