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
  DEBIAN_FRONTEND="noninteractive" apt update -qq -y \
  && \
  DEBIAN_FRONTEND="noninteractive" apt install -qq -y --no-install-recommends \
    apache2 \
    apache2-utils

## APACHE

ARG APACHE_CONF=/etc/apache2/httpd.conf
ARG APACHE_HTDOCS=/var/www/localhost/htdocs
ARG APACHE_CGIBIN=/var/www/localhost/cgi-bin
ARG APACHE_HOST=localhost
ARG APACHE_PORT=8888
ARG APACHE_ADMIN=root@localhost.local
ARG APACHE_PID_FILE=/var/run/apache2/apache2.pid
ARG APACHE_LOG_DIR=/var/www/logs
ARG APACHE_LOG_LEVEL=info

ENV APACHE_CONF "${APACHE_CONF}"
ENV APACHE_HTDOCS "${APACHE_HTDOCS}"
ENV APACHE_CGIBIN "${APACHE_CGIBIN}"
ENV APACHE_HOST "${APACHE_HOST}"
ENV APACHE_PORT "${APACHE_PORT}"
ENV APACHE_ADMIN "${APACHE_ADMIN}"
ENV APACHE_PID_FILE "${APACHE_PID_FILE}"
ENV APACHE_LOG_DIR "${APACHE_LOG_DIR}"
ENV APACHE_LOG_LEVEL "${APACHE_LOG_LEVEL}"

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
    org.label-schema.name="apache-ubuntu" \
    org.label-schema.description="Apache v2 Server for Ubuntu18.04" \ 
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/services/apache-ubuntu/" \ 
    org.label-schema.vcs-ref="${BUILD_REF}" \ 
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
