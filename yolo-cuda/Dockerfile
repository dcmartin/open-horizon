ARG BUILD_FROM

###
## WARNING ! WARNING !
#
# This container may only be built using the nVidia container runtime
# Please change /etc/docker/daemon.json to specify the runtime
# See below:
#
#{
#  "default-runtime": "nvidia",
#  "runtimes": {
#    "nvidia": {
#      "path": "/usr/bin/nvidia-container-runtime",
#      "runtimeArgs": []
#    }
#  }
#}
#
## WARNING ! WARNING !
### 

FROM $BUILD_FROM as openyolo

ARG BUILD_ARCH=amd64

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN apt-get update && apt-get install -q -y --no-install-recommends \
  ca-certificates \
  curl \
  build-essential \
  socat \
  imagemagick \
  fswebcam \
  jq \
  git

# configure openyolo
ARG OPENYOLO=/openyolo
ARG OPENYOLO_GIT="http://github.com/dcmartin/openyolo"
ENV OPENYOLO=${OPENYOLO} OPENYOLO_GIT=${OPENYOLO_GIT}

# configure darknet
ENV DARKNET=${OPENYOLO}/darknet

ENV DARKNET_TINYV2_WEIGHTS="${DARKNET}/yolov2-tiny-voc.weights"
ENV DARKNET_TINYV2_CONFIG="${DARKNET}/cfg/yolov2-tiny-voc.cfg"
ENV DARKNET_TINYV2_DATA="${DARKNET}/cfg/voc.data"
ENV DARKNET_TINYV2_NAMES="${DARKNET}/data/voc.names"
ENV DARKNET_TINYV2_WEIGHTS_URL="http://pjreddie.com/media/files/yolov2-tiny-voc.weights"
ENV DARKNET_TINYV2_WEIGHTS_MD5="fca33deaff44dec1750a34df42d2807e"

ENV DARKNET_TINYV3_WEIGHTS="${DARKNET}/yolov3-tiny.weights"
ENV DARKNET_TINYV3_CONFIG="${DARKNET}/cfg/yolov3-tiny.cfg"
ENV DARKNET_TINYV3_DATA="${DARKNET}/cfg/coco.data"
ENV DARKNET_TINYV3_NAMES="${DARKNET}/data/coco.names"
ENV DARKNET_TINYV3_WEIGHTS_URL="http://pjreddie.com/media/files/yolov3-tiny.weights"
ENV DARKNET_TINYV3_WEIGHTS_MD5="3bcd6b390912c18924b46b26a9e7ff53"

ENV DARKNET_V2_WEIGHTS="${DARKNET}/yolov2.weights"
ENV DARKNET_V2_CONFIG="${DARKNET}/cfg/yolov2.cfg"
ENV DARKNET_V2_DATA="${DARKNET}/cfg/coco.data"
ENV DARKNET_V2_NAMES="${DARKNET}/data/coco.names"
ENV DARKNET_V2_WEIGHTS_URL="https://pjreddie.com/media/files/yolov2.weights"
ENV DARKNET_V2_WEIGHTS_MD5="70d89ba2e180739a1c700a9ff238e354"

ENV DARKNET_V3_WEIGHTS="${DARKNET}/yolov3.weights"
ENV DARKNET_V3_CONFIG="${DARKNET}/cfg/yolov3.cfg"
ENV DARKNET_V3_DATA="${DARKNET}/cfg/coco.data"
ENV DARKNET_V3_NAMES="${DARKNET}/data/coco.names"
ENV DARKNET_V3_WEIGHTS_URL="https://pjreddie.com/media/files/yolov3.weights"
ENV DARKNET_V3_WEIGHTS_MD5="c84e5b99d0e52cd466ae710cadf6d84c"

# Clone openyolo
RUN mkdir -p ${OPENYOLO} 
RUN cd ${OPENYOLO} && git clone ${OPENYOLO_GIT} .

# Build darknet

RUN cd ${DARKNET} \
    && \
    GPU=1 make

FROM openyolo

# Copy compiled darknet
COPY --from=openyolo ${OPENYOLO} ${OPENYOLO}

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
    org.label-schema.name="yolo" \
    org.label-schema.description="yolo/darknet as a service" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/yolo-cuda/" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
