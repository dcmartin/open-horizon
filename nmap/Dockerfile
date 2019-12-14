FROM ubuntu:bionic
RUN apt-get update && apt-get install -qq -y socat curl nmap gawk bc
COPY rootfs /
CMD ["/usr/bin/run.sh"]
