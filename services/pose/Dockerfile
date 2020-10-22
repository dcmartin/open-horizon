ARG BUILD_FROM

FROM $BUILD_FROM as pose

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN DEBIAN_FRONTEND=noninteractive \
  apt update -qq -y && apt-get install -qq -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    build-essential \
    socat \
    imagemagick \
    fswebcam \
    jq \
    bc \
    software-properties-common \
    git

# configure pose
ARG OPENPOSE=/pose
ENV OPENPOSE=${OPENPOSE}

ARG OPENPOSE_GIT="http://github.com/dcmartin/openpose.git"
ENV OPENPOSE_GIT=${OPENPOSE_GIT}

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    libopencv-dev \
    cmake


# Clone pose
RUN mkdir -p ${OPENPOSE} 
RUN cd ${OPENPOSE} && git clone ${OPENPOSE_GIT} .

# Build pose
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

ENV OPENPOSE_US_WEIGHTS=""
ENV OPENPOSE_US_CONFIG=""
ENV OPENPOSE_US_DATA=""
ENV OPENPOSE_US_WEIGHTS_URL=""
ENV OPENPOSE_US_WEIGHTS_MD5=""

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
