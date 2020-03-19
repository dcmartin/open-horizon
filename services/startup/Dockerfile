ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN DEBIAN_FRONTEND=noninteractive \
  \
  && apt-get update \
  \
  && apt-get install -qq -y \
	ca-certificates \
	gnupg \
	curl \
	jq \
	socat \
	bash \
        ssh \
	bc \
	kafkacat \
	net-tools \
	wireless-tools \
	software-properties-common \
  \
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
    org.label-schema.name="hzn_setup" \
    org.label-schema.description="horizon CLI base" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/hzn_setup-ubuntu/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
