###
# Dockerfile
###

###
### build
###

ARG BUILD_FROM
FROM $BUILD_FROM as build

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# setup base system
RUN apt update -qq -y && apt upgrade -qq -y

# minimum
RUN apt install -qq -y --no-install-recommends \
  ca-certificates \
  curl \
  apt-utils \
  jq

# python3.7
RUN apt install -qq -y --no-install-recommends \
  build-essential \
  zlib1g-dev \
  libncurses5-dev \
  libgdbm-dev \
  libnss3-dev \
  libssl-dev \
  libreadline-dev \
  libffi-dev \
  libsqlite3-dev \
  libbz2-dev

RUN \
  cd /tmp \
  && \
  curl -sSL https://www.python.org/ftp/python/3.7.7/Python-3.7.7.tgz -o python.tgz \
  && \
  tar xzf python.tgz \
  && \
  cd Python-3.7.7 \
  && \
  ./configure --enable-optimizations \
  && \
  make -j $(nproc) \
  && \
  make install \
  && \
  rm -fr /tmp/Python-3.7.7

# maximum
RUN apt update -qq -y && apt install -qq -y --no-install-recommends \
  libgstreamer1.0-0 \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav gstreamer1.0-doc \
  gstreamer1.0-tools gstreamer1.0-x \
  gstreamer1.0-alsa \
  gstreamer1.0-gl gstreamer1.0-gtk3 \
  gstreamer1.0-pulseaudio \
  python3-gst-1.0 \
  python3-gi \
  python3-numpy \
  libjpeg-dev \
  zlib1g-dev \
  pkg-config \
  libavdevice-dev \
  libavfilter-dev \
  libopus-dev \
  libvpx-dev \
  libsrtp2-dev \
  procps \
  udev \
  libusb-1.0-0 \
  libunwind8 \
  libgcc1 \
  git \
  python3-pip \
  libx264-dev \
  libhdf5-dev \
  software-properties-common

## FFMPEG v4

RUN add-apt-repository ppa:jonathonf/ffmpeg-4

RUN apt update -qq -y \
  && \
  apt install -qq -y --no-install-recommends ffmpeg \
  && \
  apt upgrade -qq -y

RUN apt update -qq -y && apt upgrade -qq -y && apt install -qq -y --no-install-recommends \
  libc++1 \
  libc++abi1 \
  libcairo2-dev \
  libgirepository1.0-dev

# cleanup
RUN apt clean -qq -y && apt autoremove -qq -y && \
      rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

###
### prereqs
###

FROM build as prereqs

# pip
RUN pip3 install --upgrade pip

# wheel
RUN pip3 install --upgrade wheel

# cython
RUN pip3 install --upgrade cython

# setuptools
RUN pip3 install --upgrade setuptools

RUN pip3 install 'argparse'
RUN pip3 install dill
RUN pip3 install fire
RUN pip3 install matplotlib
RUN pip3 install numba
RUN pip3 install psutil
RUN pip3 install pycocotools
RUN pip3 install 'requests-oauthlib>=1.0.0'
RUN pip3 install 'requests>=2.21.0'
RUN pip3 install scikit-image
RUN pip3 install scipy
RUN pip3 install slidingwindow
RUN pip3 install tqdm
RUN pip3 install 'numpy>=1.16.2'

###
### tflite
###

FROM prereqs as tflite

# tflite
RUN ARCH=$(uname -m) && pip3 install https://dl.google.com/coral/python/tflite_runtime-1.14.0-cp37-cp37m-linux_${ARCH}.whl

# get TPU
RUN  curl -sSL https://dl.google.com/coral/edgetpu_api/edgetpu_api_latest.tar.gz -o /tmp/edgetpu_api.tar.gz \
  && \
  cd /tmp \
  && \
  tar xzf edgetpu_api.tar.gz

RUN \
  ARCH=$(uname -m) \
  && \
  if [ "${ARCH}" = 'armv7l' ]; then \
    LIBEDGETPU_SUFFIX=arm32 HOST_GNU_TYPE=arm-linux-gnueabihf; \
  elif [ "${ARCH}" = 'x86_64' ]; then \
    LIBEDGETPU_SUFFIX=x86_64 HOST_GNU_TYPE=x86_64-linux-gnu; \
  elif [ "${ARCH}" = 'aarch64' ]; then \
    LIBEDGETPU_SUFFIX=arm64 HOST_GNU_TYPE=aarch64-linux-gnu; \
  fi \
  && \
  if [ ! -z "${EDGETPU_THROTTLE:-}" ]; then \
    LIBEDGETPU_SRC="/tmp/edgetpu_api/libedgetpu/libedgetpu_${LIBEDGETPU_SUFFIX}_throttled.so"; \
  else \
    LIBEDGETPU_SRC="/tmp/edgetpu_api/libedgetpu/libedgetpu_${LIBEDGETPU_SUFFIX}.so"; \
  fi \
  && \
  LIBEDGETPU_DST="/usr/lib/${HOST_GNU_TYPE}/libedgetpu.so.1.0" \
    LIBEDGETPU_SRC="/tmp/edgetpu_api/libedgetpu/libedgetpu_${LIBEDGETPU_SUFFIX}_throttled.so" \
    LIBEDGETPU_DST="/usr/lib/${HOST_GNU_TYPE}/libedgetpu.so.1.0" \
  && \
  cp "${LIBEDGETPU_SRC}" "${LIBEDGETPU_DST}" \
  && \
  ldconfig

RUN \
    mkdir -p /etc/udev/rules.d \
    && \
    cp /tmp/edgetpu_api/99-edgetpu-accelerator.rules /etc/udev/rules.d/99-edgetpu-accelerator.rules

# Python API.
RUN pip3 install --no-deps /tmp/edgetpu_api/edgetpu-2.11.1-py3-none-any.whl

# cleanup
RUN apt clean -qq -y && apt autoremove -qq -y && \
      rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

###
### tensorflow
###

FROM prereqs as tensorflow

RUN pip3 install 'tensorflow==1.15.4'

# cleanup
RUN apt clean -qq -y && apt autoremove -qq -y && \
      rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

RUN \
  cd /root \
  && \
  git clone https://github.com/cocodataset/cocoapi \
  && \
  cd cocoapi/PythonAPI \
  && \
  python3 setup.py build_ext --inplace \
  && \
  python3 setup.py build_ext install \
  && \
  mkdir /coco \
  && \
  cd /coco \
  && \
  wget http://images.cocodataset.org/annotations/annotations_trainval2017.zip \
  && \
  unzip annotations_trainval2017.zip \
  && \
  rm -rf annotations_trainval2017.zip

#
#ENTRYPOINT ["python3", "pose_dataworker.py"]
#

FROM tensorflow as pose

# configure pose
ARG OPENPOSE=/pose
ENV OPENPOSE=${OPENPOSE}

ARG OPENPOSE_GIT="http://github.com/dcmartin/openpose.git"
ENV OPENPOSE_GIT=${OPENPOSE_GIT}

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    cmake \
    build-essential \
    pkg-config \
    zip \
    libjpeg8-dev \
    libtiff5-dev \
    libjasper-dev \
    libpng12-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libgtk2.0-dev \
    libatlas-base-dev \
    gfortran

# Clone pose
RUN mkdir -p ${OPENPOSE} 
RUN cd ${OPENPOSE} && git clone ${OPENPOSE_GIT} .

## Build opencv
RUN \
  mkdir -p /tmp/opencv \
  && \
  cd /tmp/opencv \
  && \
  git clone https://github.com/Itseez/opencv.git . \
  && \
  mkdir build \
  && \
  cd build \
  && cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D BUILD_opencv_python3=yes \
    -D PYTHON_EXECUTABLE=/usr/bin/python3 .. \
  && \
  make -j $(nproc) \
  && \
  make install \
  && \
  rm -fr /tmp/opencv

## Build pose
RUN \
  cd ${OPENPOSE} && mkdir build && cd build \
  && \
  export ARGS="${ARGS:-} -DENABLE_AVX2=OFF" \
  export ARGS="${ARGS:-} -DENABLE_NEON=OFF" \
  && \
  cmake ${ARGS:-} .. \
  && \
  make

FROM pose


ENV OPENPOSE_OPT_WEIGHTS="http://www.mediafire.com/file/1pyjsjl0p93x27c/graph_freeze.pb"
ENV OPENPOSE_OPT_CONFIG=""
ENV OPENPOSE_OPT_DATA=""
ENV OPENPOSE_OPT_WEIGHTS_URL=""
ENV OPENPOSE_OPT_WEIGHTS_MD5=""

ENV OPENPOSE_EU_WEIGHTS=""
ENV OPENPOSE_EU_CONFIG=""
ENV OPENPOSE_EU_DATA=""
ENV OPENPOSE_EU_WEIGHTS_URL=""
ENV OPENPOSE_EU_WEIGHTS_MD5=""

# Copy compiled pose
COPY --from=pose ${OPENPOSE} ${OPENPOSE}

RUN \
  cd ${OPENPOSE} && cp ./build/detect-image-demo /usr/local/bin/pose

# Copy usr
COPY rootfs/usr /usr

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
    org.label-schema.name="pose" \
    org.label-schema.description="Face detection as a service" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/services/pose/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
