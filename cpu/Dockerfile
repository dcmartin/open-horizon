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
RUN \
    set -o pipefail \
    \
    && apk add --no-cache \
        apk-tools \
        bash \
	bc \
        curl \
        jq \
        coreutils \
        socat \
    && rm -f -r \
        /tmp/*

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
    org.label-schema.name="cpu" \
    org.label-schema.description="cpu utilization percent (0.0-100.0)" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/cpu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"

