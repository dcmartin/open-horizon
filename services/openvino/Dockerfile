ARG BUILD_FROM

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update -qq -y \
  && apt-get install -qq -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    cmake \
    socat \
    jq \
    bc \
    git \
    unzip \
    coreutils \
    dateutils \
    findutils

###
# OpenCV pre-requisites
###

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -qq -y --no-install-recommends \
    libjpeg-dev \
    libtiff5-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -qq -y --no-install-recommends \
    libgtk2.0-dev \
    libgtk-3-dev \
    libatlas-base-dev \
    libopenblas-dev \
    gfortran

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -qq -y --no-install-recommends \
    python2.7-dev \
    python3-dev

##
# opencv
##

ARG OPENCV_GITHUB_ARCHIVE='https://github.com/opencv/opencv/archive/4.1.0.zip'
ARG OPENCV_CMAKE_FLAGS='-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/ -DPYTHON3_EXECUTABLE=/usr/bin/python3.7 –DPYTHON_INCLUDE_DIR=/usr/include/python3.7 –DPYTHON_INCLUDE_DIR2=/usr/include/arm-linux-gnueabihf/python3.7m –DPYTHON_LIBRARY=/usr/lib/arm-linux-gnueabihf/libpython3.7m.so'

ENV OPENCV_CMAKE_FLAGS "${OPENCV_CMAKE_FLAGS}"
ENV OPENCV_GITHUB_ARCHIVE "${OPENCV_GITHUB_ARCHIVE}"

ENV OPENCV_DIR "/tmp/opencv"
ENV OPENCV_VERSION "opencv-4.1.0"

RUN \
  curl -sSL https://bootstrap.pypa.io/get-pip.py -o getpip.py \
  && \
  python3 getpip.py \
  && \
  pip3 install numpy

RUN \
  curl -sSL ${OPENCV_GITHUB_ARCHIVE} -o /tmp/opencv.zip \
  && \
  unzip -qq -d ${OPENCV_DIR} /tmp/opencv.zip \
  && \
  rm -f /tmp/opencv.zip

RUN \
  mkdir ${OPENCV_DIR}/${OPENCV_VERSION}/build

RUN \
  cd ${OPENCV_DIR}/${OPENCV_VERSION}/build \
  && \
  ls .. \
  && \
  cmake ${OPENCV_CMAKE_FLAGS} ..

RUN \
  cd ${OPENCV_DIR}/${OPENCV_VERSION}/build \
  && \
  make -j4

RUN \
  cd ${OPENCV_DIR}/${OPENCV_VERSION}/build \
  && \
  make install

##
# openvino
##

ARG OPENVINO_REPOSITORY=https://github.com/opencv/dldt.git
ARG OPENVINO_CMAKE_FLAGS='-DCMAKE_BUILD_TYPE=Release -DENABLE_MKL_DNN=OFF -DENABLE_CLDNN=OFF -DENABLE_GNA=OFF -DENABLE_SSE42=OFF -DTHREADING=SEQ'

ENV OPENVINO_REPOSITORY "${OPENVINO_REPOSITORY}"
ENV OPENVINO_CMAKE_FLAGS "${OPENVINO_CMAKE_FLAGS}"

RUN \
  apt-get install -qq -y sudo

RUN \
  mkdir /tmp/dldt && cd /tmp/dldt && git clone ${OPENVINO_REPOSITORY} . \
  && \
  cd inference-engine && git submodule init && git submodule update --recursive \
  && \
  ./install_dependencies.sh

RUN \
  ARCH=$(arch) \
  test "${ARCH}" = "armv7l" && export OPENVINO_CMAKE_FLAGS="${OPENVINO_CMAKE_FLAGS} -DCMAKE_CXX_FLAGS=-march=armv7-a" || echo "Not armv7l"

RUN \
  cd /tmp/dldt/inference-engine && mkdir build && cd build \
  && \
  echo "${OPENVINO_CMAKE_FLAGS}" \
  && \
  cmake ${OPENVINO_CMAKE_FLAGS} ..

RUN \
  cd /tmp/dldt/inference-engine/build \
  && \
  make -j4

RUN \
  mkdir -p /etc/udev/rules.d \
  && \
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
