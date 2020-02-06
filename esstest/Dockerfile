FROM ubuntu:bionic
RUN apt-get update && apt-get install -qq -y bash socat curl jq
COPY rootfs /
CMD ["/usr/bin/run.sh"]
EXPOSE 8080
