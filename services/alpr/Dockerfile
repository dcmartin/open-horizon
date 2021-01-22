ARG BUILD_FROM

FROM $BUILD_FROM as alpr

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN apt update -qq -y
RUN \
  DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    apt-utils \
    bc \
    build-essential \
    ca-certificates \
    curl \
    fswebcam \
    git \
    imagemagick \
    jq \
    socat \
    software-properties-common

RUN add-apt-repository ppa:alex-p/tesseract-ocr && apt update -qq -y

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get install -qq -y --no-install-recommends \
  libopencv-dev \
  libtesseract-dev \
  cmake \
  build-essential \
  libleptonica-dev

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get install -qq -y --no-install-recommends \
  liblog4cplus-dev \
  libcurl3-dev

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get install -qq -y --no-install-recommends \
 openjdk-8-jdk \
 default-jdk

# configure alpr
ARG OPENALPR=/alpr
ENV OPENALPR=${OPENALPR}

ARG OPENALPR_GIT="http://github.com/dcmartin/openalpr.git"
ENV OPENALPR_GIT=${OPENALPR_GIT}

# Clone alpr
RUN mkdir -p ${OPENALPR} 
RUN cd ${OPENALPR} && git clone ${OPENALPR_GIT} .

# Build alpr
RUN \
  cd ${OPENALPR}/src && mkdir build && cd build \
  && \
  cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_INSTALL_SYSCONFDIR:PATH=/etc .. \
  && \
  make

FROM alpr

ENV OPENALPR_US_WEIGHTS=""
ENV OPENALPR_US_CONFIG=""
ENV OPENALPR_US_DATA=""
ENV OPENALPR_US_WEIGHTS_URL=""
ENV OPENALPR_US_WEIGHTS_MD5=""

ENV OPENALPR_EU_WEIGHTS=""
ENV OPENALPR_EU_CONFIG=""
ENV OPENALPR_EU_DATA=""
ENV OPENALPR_EU_WEIGHTS_URL=""
ENV OPENALPR_EU_WEIGHTS_MD5=""

# Copy compiled alpr
COPY --from=alpr ${OPENALPR} ${OPENALPR}

RUN \
  cd ${OPENALPR}/src/build && make install

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
    org.label-schema.name="alpr" \
    org.label-schema.description="alpr as a service" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/alpr/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
