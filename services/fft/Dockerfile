ARG BUILD_FROM

FROM $BUILD_FROM

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

## base
RUN export DEBIAN_FRONTEND=noninteractive \
  \
  && \
  \
  apt-get update && apt-get install -qq -y --no-install-recommends \
    apt-utils \
    pkg-config \
    jq \
    curl \
    socat \
    ffmpeg \
    mosquitto-clients \
  \
  && rm -fr \
    /tmp/*

## python
RUN export DEBIAN_FRONTEND=noninteractive \
  \
  && \
  \
  apt-get update && apt-get install -qq -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-tk \
    python3-numpy \
    python3-matplotlib \
    python3-scipy \
  \
  && rm -fr \
    /tmp/*

## cleanup
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt

RUN pip3 install --upgrade setuptools 

RUN pip3 install pydub 

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
    org.label-schema.name="base-ubuntu" \
    org.label-schema.description="base ubuntu container" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/base-ubuntu/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
