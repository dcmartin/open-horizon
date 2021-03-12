# Build arguments
ARG BUILD_FROM

# source to build this container 
FROM ${BUILD_FROM}

# architecture
ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color"

# fail on pipe failurs
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  DEBIAN_FRONTEND=noninteractive apt update -qq -y \
  && \
  DEBIAN_FRONTEND=noninteractive apt upgrade -qq -y

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    python-dev \
    python3-dev \
    python3.8-dev \
    libpython3.8-dev \
    python3-pip

RUN  python3 -m pip install --upgrade pip

# requirements
RUN pip3 install 'protobuf'
RUN pip3 install 'slidingwindow'

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    pkg-config \
    zip \
    libjpeg8-dev \
    libtiff5-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libgtk2.0-dev \
    libatlas-base-dev \
    gfortran

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    wget \ 
    unzip

# GPU
ARG GPU
ENV GPU=${GPU}

# FFMPEG CUDA
RUN \
  if [ ${GPU:-0} -eq 1 ]; then \
    apt install -qq -y build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev \
    && \
    mkdir -p /tmp/ffmpeg-build \
    && \
    cd /tmp/ffmpeg-build \
    && \
    VERSION=latest \
    && \
    NVCH='nv-codec-headers' \
    && \
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git ${NVCH} \
    && \
    pushd ${NVCH} \
    && \
    make install \
    && \
    popd \
    && \
    curl -sSL https://ffmpeg.org/releases/ffmpeg-snapshot-git.tar.bz2 -o ffmpeg-${VERSION}.tar.bz2 \
    && \
    tar xjvf ffmpeg-${VERSION}.tar.bz2 \
    && \
    cd ffmpeg/ \
    && \
    DIR=$(pwd -P) \
    && \
    export PKG_CONFIG_PATH="${DIR}/ffmpeg_build/lib/pkgconfig" \
    && \
    ./configure --enable-cuda --enable-nonfree  --extra-cflags="-I/usr/local/cuda/include" --extra-ldflags="-L/usr/local/cuda/lib" \
    && \
    make -j$(nproc) \
    && \
    make install; \
  fi

RUN \
  if [ ${GPU:-0} -eq 0 ]; then \
    apt install -qq -y ffmpeg; \
  fi

# OPENCV CUDA
RUN \
  mkdir -p /tmp/opencv \
  && \
  cd /tmp/opencv \
  && \
  VERSION=4.5.0 \
  && \
  if [ ! -s opencv-${VERSION}.zip ]; then curl -sSL https://github.com/opencv/opencv/archive/${VERSION}.zip -o opencv-${VERSION}.zip; fi \
  && \
  if [ ! -s opencv_contrib-${VERSION}.zip ]; then curl -sSL https://github.com/opencv/opencv_contrib/archive/${VERSION}.zip -o opencv_contrib-${VERSION}.zip; fi \
  && \
  if [ ! -d opencv-${VERSION} ]; then unzip opencv-${VERSION}.zip; fi \
  && \
  if [ ! -d opencv_contrib-${VERSION} ]; then unzip opencv_contrib-${VERSION}.zip; fi \
  && \
  if [ ! -d opencv-${VERSION}/release ]; then mkdir -p opencv-${VERSION}/release; fi \
  && \
  git clone https://github.com/catkin/catkin_simple

RUN \
  cd /tmp/opencv/opencv-${VERSION}/release \
  && \
  if [ ${GPU:-0} -eq 1 ]; then \
    if [ "${BUILD_ARCH:-}" = 'amd64' ]; then \
      CUDA_ARCH_BIN='-D CUDA_ARCH_BIND=5.3'; \
      CUDA_FAST_MATH='-D CUDA_ARCH_BIND=5.3'; \
        CUDA_ARCH_PTX='-D CUDA_ARCH_PTX=""' \
        CUDA_FAST_MATH='-D CUDA_FAST_MATH=ON' \
        OPENCV_DNN_CUDA='-D OPENCV_DNN_CUDA=ON' \
        WITH_CUBLAS'-D WITH_CUBLAS=ON' \
        WITH_CUDA'-D WITH_CUDA=ON' \
        WITH_CUDNN'-D WITH_CUDNN=ON' \
        ENABLE_FAST_MATH='-D ENABLE_FAST_MATH=ON' \
        ENABLE_NEON='-D ENABLE_NEON=ON' \
    fi; \
  fi; \
  && \
  cmake \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_NEW_PYTHON_SUPPORT=ON \
    -D BUILD_TBB=ON \
    -D BUILD_TESTS=OFF \
    -D BUILD_TIFF=ON \
    -D BUILD_opencv_python3=TRUE \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
    -D INSTALL_C_EXAMPLES=OFF \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D WITH_EIGEN=ON \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D CMAKE_MODULE_PATH=../ \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${VERSION}/modules \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D WITH_FFMPEG=ON \
    -D WITH_GSTREAMER=ON \
    -D WITH_LIBV4L=ON \
    -D WITH_OPENGL=ON \
    -D WITH_OPENMP=ON \
    -D WITH_QT=OFF \
    -D WITH_TBB=ON \
    -D WITH_V4L=ON \
    -D PYTHON_EXECUTABLE=/usr/bin/python3 \
        ${CUDA_ARCH_BIN:-} \
        ${CUDA_ARCH_PTX:-} \
        ${CUDA_FAST_MATH:-} \
        ${OPENCV_DNN_CUDA:-} \
        ${WITH_CUBLAS:-} \
        ${WITH_CUDA:-} \
        ${WITH_CUDNN:-} \
        ${ENABLE_FAST_MATH:-} \
        ${ENABLE_NEON:-} \
    ..; \
  fi

RUN \
  cd /tmp/opencv/opencv-${VERSION}/release \
  && \
  make -j $(nproc) \
  && \
  make install \

RUN \
  rm -fr /tmp/opencv

#        -D CUDA_ARCH_BIN=5.3 \
#        -D CUDA_ARCH_PTX="" \
#        -D CUDA_FAST_MATH=ON \
#        -D ENABLE_FAST_MATH=ON \
#        -D ENABLE_NEON=ON \
#        -D OPENCV_DNN_CUDA=ON \
#        -D WITH_CUBLAS=ON \
#        -D WITH_CUDA=ON \
#        -D WITH_CUDNN=ON \

RUN \
  DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y autoconf automake libtool curl make g++ unzip \
  && \
  git clone https://github.com/google/protobuf.git \
  && \
  cd protobuf \
  && \
  git submodule update --init --recursive \
  && \
  ./autogen.sh \
  && \
  ./configure \
  && \
  make \
  && \
  make check \
  && \
  make install \
  && \
  ldconfig

RUN \
  DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y libgoogle-glog-dev
>>>>>>> b65568a6766334e1303579fa114b456fd719a11f

###
### POSE
###

ARG OPENPOSE=/pose
ENV OPENPOSE=${OPENPOSE}
ARG OPENPOSE_GIT="http://github.com/dcmartin/openpose-old.git"
ENV OPENPOSE_GIT=${OPENPOSE_GIT}

# Clone pose
RUN mkdir -p ${OPENPOSE} 
RUN cd ${OPENPOSE} && git clone ${OPENPOSE_GIT} .

## Build pose
RUN \
  cd ${OPENPOSE} \
  && \
  mkdir build && cd build \
  && \
  cmake -DGPU_MODE=CPU_ONLY -DBUILD_PYTHON=ON .. \
  && \
  make -j $(nproc) \
  && \
  make install

RUN \
  cd ${OPENPOSE} \
  && \
  git clone https://github.com/cocodataset/cocoapi \
  && \
  pip3 install cython \
  && \
  cd cocoapi/PythonAPI \
  && \
  python3 setup.py build_ext --inplace \
  && \
  python3 setup.py build_ext install

RUN \
  cd ${OPENPOSE} \
  && \
  mkdir coco && cd coco \
  && \
  wget http://images.cocodataset.org/annotations/annotations_trainval2017.zip \
  && \
  unzip annotations_trainval2017.zip \
  && \
  rm -rf annotations_trainval2017.zip

# cleanup
RUN apt clean -qq -y && apt autoremove -qq -y && \
      rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

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
    org.label-schema.name="pose" \
    org.label-schema.description="Human pose estimation detection as a service" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/services/pose/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
