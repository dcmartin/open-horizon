ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN \
  export DEBIAN_FRONTEND=noninteractive \
  && \
  apt-get update && apt-get install -q -y --no-install-recommends \
  bc \
  inotify-tools \
  dateutils \
  mosquitto-clients \
  iproute2

ARG GPU
ENV GPU=${GPU}

# Copy usr
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
    org.label-schema.name="yolo" \
    org.label-schema.description="yolo listening to MQTT" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/yolo4motion/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
