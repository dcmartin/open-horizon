ARG BUILD_FROM
FROM ${BUILD_FROM}
RUN apt-get update && apt-get install -qq -y socat curl
COPY rootfs /
CMD ["/usr/bin/run.sh"]
