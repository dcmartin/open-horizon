ARG BUILD_FROM

FROM $BUILD_FROM

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN apk add --no-cache \
  apache2 \
  apache2-utils \
  bc \
  coreutils \
  curl \
  dateutils \
  findutils \
  gawk \
  inotify-tools \
  jq \
  mosquitto-clients \
  nodejs \
  nodejs-npm \
  git

# Copy rootts
COPY rootfs /

## APACHE

ARG NOSQLDB_APACHE_CONF=/etc/apache2/httpd.conf
ARG NOSQLDB_APACHE_HTDOCS=/var/www/localhost/htdocs
ARG NOSQLDB_APACHE_CGIBIN=/var/www/localhost/cgi-bin
ARG NOSQLDB_APACHE_HOST=localhost
ARG NOSQLDB_APACHE_PORT=7999
ARG NOSQLDB_APACHE_ADMIN=root@localhost.local

ENV NOSQLDB_APACHE_CONF "${NOSQLDB_APACHE_CONF}"
ENV NOSQLDB_APACHE_HTDOCS "${NOSQLDB_APACHE_HTDOCS}"
ENV NOSQLDB_APACHE_CGIBIN "${NOSQLDB_APACHE_CGIBIN}"
ENV NOSQLDB_APACHE_HOST "${NOSQLDB_APACHE_HOST}"
ENV NOSQLDB_APACHE_PORT "${NOSQLDB_APACHE_PORT}"
ENV NOSQLDB_APACHE_ADMIN "${NOSQLDB_APACHE_ADMIN}"

# Ports for motion (control and stream)
EXPOSE ${NOSQLDB_APACHE_PORT}

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
    org.label-schema.name="nosqldb" \
    org.label-schema.description="PouchDB Server" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/nosqldb/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
