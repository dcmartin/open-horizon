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

# AMD64
RUN if [ 'amd64' == "${BUILD_ARCH}" ]; then pip3 install 'blis==0.4.1'; fi

# ARM64
RUN if [ 'aarch64' == "${BUILD_ARCH}" ]; then BLIS_ARCH='generic' pip3 install spacy --no-binary blis; fi

# ARMv7
#RUN if [ 'armv7' == "${BUILD_ARCH}" ]; then BLIS_ARCH='generic' pip3 install --no-binary ':all:' 'blis==0.4.1'; fi

# ARMhf
#RUN if [ 'armhf' == "${BUILD_ARCH}" ]; then BLIS_ARCH='generic' pip3 install --no-binary ':all:' 'blis==0.4.1'; fi

RUN pip3 install \
  'pip>=20.2.3' \
   'appdirs==1.4.3' \
   'attrs>=19.1.0' \
   'certifi==2019.11.28' \
   'chardet==3.0.4' \
   'click~=7.0' \
   'cymem==2.0.3' \
   'Flask==1.1.1' \
   'idna==2.8' \
   'itsdangerous==1.1.0' \
   'Jinja2==2.10.3' \
   'lxml>=4.2.5' \
   'MarkupSafe==1.1.1' \
   'mixpanel==4.4.0' \
   'numpy>=1.17.4' \
   'python-dateutil==2.8.1' \
   'pytz==2019.3' \
   'six>=1.13.0' \
   'srsly>=0.2.0' \
   'tqdm>=4.40.2' \
   'urllib3==1.25.7' \
   'wasabi==0.4.2' \
   'Werkzeug==0.16.0' \
   'ordered-set==4.0.2' \
   'orjson>=2.0.11' \
   'rarfile==3.1' \
   'flask_api>=2.0' \
   'pandas>=0.24.0' \
   'jsonschema>=3.2.0' \
   'xmljson==0.2.0' \
   'rq>=1.0' \
   'boto3>=1.12.32' \
   'google-cloud-storage==1.28.1' \
   'flask_wtf==0.14.3' \
   'label-studio-converter>=0.0.22' \
   'htmlmin==0.1.12' \
   'gevent>=20.6.2' \
   'ujson==3.0.0' \
   'Colorama==0.4.4' \
   'boxing==0.1.4' \
   'pyyaml>=5.3.1' \
   'numpy>=1.17.4'  \
   'pandas>=0.24.0' \
   'orjson>=2.0.11'

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
