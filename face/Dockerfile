ARG BUILD_FROM

FROM $BUILD_FROM as face

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

# configure face
ARG OPENFACE=/face
ENV OPENFACE=${OPENFACE}

ARG OPENFACE_GIT="http://github.com/dcmartin/openface.git"
ENV OPENFACE_GIT=${OPENFACE_GIT}

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    libopencv-dev \
    cmake


# Clone face
RUN mkdir -p ${OPENFACE} 
RUN cd ${OPENFACE} && git clone ${OPENFACE_GIT} .

# Build face
RUN \
  cd ${OPENFACE} && mkdir build && cd build \
  && \
  export ARGS="${ARGS:-} -DENABLE_AVX2=OFF" \
  export ARGS="${ARGS:-} -DENABLE_NEON=OFF" \
  && \
  cmake ${ARGS:-} .. \
  && \
  make

FROM face

ENV OPENFACE_US_WEIGHTS=""
ENV OPENFACE_US_CONFIG=""
ENV OPENFACE_US_DATA=""
ENV OPENFACE_US_WEIGHTS_URL=""
ENV OPENFACE_US_WEIGHTS_MD5=""

ENV OPENFACE_EU_WEIGHTS=""
ENV OPENFACE_EU_CONFIG=""
ENV OPENFACE_EU_DATA=""
ENV OPENFACE_EU_WEIGHTS_URL=""
ENV OPENFACE_EU_WEIGHTS_MD5=""

# Copy compiled face
COPY --from=face ${OPENFACE} ${OPENFACE}

RUN \
  cd ${OPENFACE} && cp ./build/detect-image-demo /usr/local/bin/face

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
    org.label-schema.name="face" \
    org.label-schema.description="face as a service" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/face/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
