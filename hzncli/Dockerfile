ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN apt-get update && apt-get install -q -y --no-install-recommends \
  ca-certificates \
  gnupg

RUN apt-get update -y \
  && APT_REPO=updates \
  && APT_LIST=/etc/apt/sources.list.d/bluehorizon.list \
  && PUBLICKEY_URL=http://pkg.bluehorizon.network/bluehorizon.network-public.key \
  && curl -fsSL "${PUBLICKEY_URL}" | apt-key add - \
  && echo "deb [arch=armhf,arm64,amd64] http://pkg.bluehorizon.network/linux/ubuntu xenial-${APT_REPO} main" >> "${APT_LIST}" \
  && apt-get update -y \
  && apt-get install -y horizon-cli \
  && rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

# Copy rootfs
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
    org.label-schema.name="hzncli" \
    org.label-schema.description="horizon CLI base" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/hzncli-ubuntu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
