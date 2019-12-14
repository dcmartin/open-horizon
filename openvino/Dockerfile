ARG BUILD_FROM

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update && apt-get install -q -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    socat \
    jq \
    bc \
    git \
    coreutils \
    dateutils \
    findutils

# Copy rootts
COPY rootfs /

## OPENVINO

ARG OPENVINO_REPOSITORY=https://github.com/opencv/dldt.git
ARG OPENVINO_CMAKE_FLAGS='-DCMAKE_BUILD_TYPE=Release -DENABLE_MKL_DNN=OFF -DENABLE_CLDNN=OFF -DENABLE_GNA=OFF -DENABLE_SSE42=OFF -DTHREADING=SEQ'

ENV OPENVINO_REPOSITORY "${OPENVINO_REPOSITORY}"
ENV OPENVINO_CMAKE_FLAGS "${OPENVINO_CMAKE_FLAGS}"

##
# openvino
##

RUN \
  mkdir /tmp/dldt && cd /tmp/dldt && git clone ${OPENVINO_REPOSITORY} . \
  && \
  cd inference-engine && git submodule init && git submodule update --recursive \
  && \
  ./install_dependencies.sh

RUN \
  cd /tmp/dldt && mkdir build && cd build \
  && \
  export DIST=$(lsb_release -a 2> /dev/null | head -1 | awk '{ print $3 }') \
  && \
  if [ "${DIST}" == 'Raspbian' ]; then export OPENVINO_CMAKE_FLAGS="${OPENVINO_CMAKE_FLAGS} -DCMAKE_CXX_FLAGS='-march=armv7-a'"; fi \
  && \
  cmake ${OPENVINO_CMAKE_FLAGS} ..

RUN \
  make 

RUN \
  echo 'SUBSYSTEM=="usb", ATTRS{idProduct}=="2150", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"' \
    >> /etc/udev/rules.d/97-myriad-usbboot.rules \
  && \
  echo 'SUBSYSTEM=="usb", ATTRS{idProduct}=="2485", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"' \
    >> /etc/udev/rules.d/97-myriad-usbboot.rules \
  && \
  echo 'SUBSYSTEM=="usb", ATTRS{idProduct}=="f63b", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"' \
   >> /etc/udev/rules.d/97-myriad-usbboot.rules

###
# standard
###

# copy root file-system
COPY rootfs /

# start default program
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
    org.label-schema.name="apache" \
    org.label-schema.description="PouchDB Server" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/apache/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
