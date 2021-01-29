ARG BUILD_FROM=${BUILD_FROM}

FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# setup base system
ARG BUILD_ARCH=amd64

RUN DEBIAN_FRONTEND=noninteractive \
  apt update -qq -y
RUN DEBIAN_FRONTEND=noninteractive \
  apt upgrade -qq -y

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    apt-utils \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    pkg-config \
    procps \
    socat \
    software-properties-common

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    libbz2-dev \
    libffi-dev \
    libgdbm-dev \
    libjpeg-dev \
    libncurses5-dev \
    libnss3-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    zlib1g-dev

# PRE-REQUISITES

RUN DEBIAN_FRONTEND=noninteractive \
  apt install -qq -y --no-install-recommends \
    python-dev \
    python3-dev \
    python3.8-dev \
    python3.8-venv \
    libpython3.8-dev \
    python3-pip

RUN  python3 -m pip install --upgrade pip

# labelstudio requirements
RUN pip3 install 'wheel'
RUN pip3 install 'setuptools'
RUN pip3 install 'requests>=2.22.0'
RUN pip3 install 'cython'
RUN pip3 install 'appdirs==1.4.3'
RUN pip3 install 'attrs>=19.1.0'
RUN pip3 install 'certifi==2019.11.28'
RUN pip3 install 'chardet==3.0.4'
RUN pip3 install 'click~=7.0'
RUN pip3 install 'MarkupSafe==1.1.1'
RUN pip3 install 'Jinja2==2.10.3'
RUN pip3 install 'Flask==1.1.1'
RUN pip3 install 'idna==2.8'
RUN pip3 install 'itsdangerous==1.1.0'
RUN pip3 install 'lxml>=4.2.5'
RUN pip3 install 'mixpanel==4.4.0'
RUN pip3 install 'python-dateutil==2.8.1'
RUN pip3 install 'pytz==2019.3'
RUN pip3 install 'six>=1.13.0'
RUN pip3 install 'srsly>=0.2.0'
RUN pip3 install 'tqdm>=4.40.2'
RUN pip3 install 'urllib3==1.25.7'
RUN pip3 install 'wasabi==0.4.2'
RUN pip3 install 'Werkzeug==0.16.0'
RUN pip3 install 'ordered-set==4.0.2'
RUN pip3 install 'Pillow==6.2.1'
RUN pip3 install 'rarfile==3.1'
RUN pip3 install 'flask_api>=2.0'
RUN pip3 install 'jsonschema>=3.2.0'
RUN pip3 install 'xmljson==0.2.0'
RUN pip3 install 'rq>=1.0'
RUN pip3 install 'boto3>=1.12.32'
RUN pip3 install 'google-cloud-storage==1.28.1'
RUN pip3 install 'flask_wtf==0.14.3'
RUN pip3 install 'label-studio-converter'
RUN pip3 install 'htmlmin==0.1.12'
RUN pip3 install 'gevent>=20.6.2'
RUN pip3 install 'ujson==3.0.0'
RUN pip3 install 'Colorama==0.4.4'
RUN pip3 install 'boxing==0.1.4'
RUN pip3 install 'pyyaml>=5.3.1'

# AMD64
RUN if [ 'amd64' == "${BUILD_ARCH}" ]; then pip3 install 'numpy>=1.17.4' 'pandas>=0.24.0' 'orjson>=2.0.11' 'blis>=0.4.1'; fi

# ARM64
RUN if [ 'armv7' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'numpy>=1.17.4'; fi
RUN if [ 'arm64' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'pandas>=0.24.0'; fi
RUN if [ 'arm64' == "${BUILD_ARCH}" ]; then BLIS_ARCH='generic' pip3 install spacy --no-binary blis; fi
RUN if [ 'arm64' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'orjson>=2.0.11'; fi

# ARMv7
RUN if [ 'armv7' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'numpy>=1.17.4'; fi
RUN if [ 'armv7' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'pandas>=0.24.0'; fi
RUN if [ 'armv7' == "${BUILD_ARCH}" ]; then BLIS_ARCH='generic' pip3 install --no-binary ':all:' 'blis>=0.4.1'; fi
RUN if [ 'armv7' == "${BUILD_ARCH}" ]; then pip3 install --no-binary 'orjson' 'orjson>=2.0.11'; fi

# ARMhf
RUN if [ 'armhf' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'numpy>=1.17.4'; fi
RUN if [ 'armhf' == "${BUILD_ARCH}" ]; then pip3 install --no-binary ':all:' 'pandas>=0.24.0'; fi
RUN if [ 'armhf' == "${BUILD_ARCH}" ]; then BLIS_ARCH='generic' pip3 install --no-binary ':all:' 'blis>=0.4.1'; fi
RUN if [ 'armhf' == "${BUILD_ARCH}" ]; then pip3 install --no-binary 'orjson' 'orjson>=2.0.11'; fi

# last package
RUN pip3 install 'cymem==2.0.3'

### LABEL-STUDIO

ARG LABEL_STUDIO=/label-studio
ENV LABEL_STUDIO ${LABEL_STUDIO}

RUN mkdir -p ${LABEL_STUDIO} \
      && \
      cd ${LABEL_STUDIO} \
      && \
      git clone http://github.com/dcmartin/label-studio.git . \
      && \
      python3 setup.py develop

# cleanup
RUN rm -fr \
      /tmp/* \
      /var/{cache,log}/* \
      /var/lib/apt/lists/*

# defaults

ARG LABELSTUDIO_PROJECT='MyProject'
ARG LABELSTUDIO_HOST='0.0.0.0'
ARG LABELSTUDIO_PORT='7998'
ARG LABELSTUDIO_PROTOCOL='http://'
ARG LABELSTUDIO_USERNAME='username'
ARG LABELSTUDIO_PASSWORD='password'

ENV LABELSTUDIO_PROJECT ${LABELSTUDIO_PROJECT}
ENV LABELSTUDIO_HOST ${LABELSTUDIO_HOST}
ENV LABELSTUDIO_PORT ${LABELSTUDIO_PORT}
ENV LABELSTUDIO_PROTOCOL ${LABELSTUDIO_PROTOCOL}
ENV LABELSTUDIO_USERNAME ${LABELSTUDIO_USERNAME}
ENV LABELSTUDIO_PASSWORD ${LABELSTUDIO_PASSWORD}

# Copy root filesystem
COPY rootfs /

# start
CMD ["/usr/bin/run.sh"]

# Build arguments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="label-studio" \
    io.hass.description="Label Studio" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="David C Martin <github@dcmartin.com>" \
    org.label-schema.description="TPLink EAP controller" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="label-studio" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://addons.community" \
    org.label-schema.usage="https://github.com/dcmartin/hassio-addons/label-studio/tree/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/dcmartin/hassio-addons/label-studio" \
    org.label-schema.vendor="DCMARTIN"
