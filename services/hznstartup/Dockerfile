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

# Copy rootts
COPY rootfs /

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
    org.label-schema.name="apache4startup" \
    org.label-schema.description="Apache Web server for the startup service/pattern" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/apache4startup/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
