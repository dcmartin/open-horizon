ARG BUILD_FROM

FROM ${BUILD_FROM}

ARG BUILD_ARCH=arm64

###
### CUDA
###

# install cuda-repo and cudnn
RUN for DEB in \
	cuda-repo-l4t-9-0-local_9.0.252-1_arm64.deb \
	libcudnn7_7.1.5.14-1+cuda9.0_arm64.deb \
	libcudnn7-dev_7.1.5.14-1+cuda9.0_arm64.deb \
	; do dpkg --install ${DEB}; done

# add GPG key from cuda-repo
RUN apt-key add /var/cuda-repo-9-0-local/7fa2af80.pub

# install cuda-toolkit
RUN apt-get update && apt-get install -y --allow-unauthenticated \
	cuda-toolkit-9.0

## Re-link libs in /usr/lib/<arch>/tegra
RUN ln -sf /usr/lib/aarch64-linux-gnu/tegra/libGL.so /usr/lib/aarch64-linux-gnu/libGL.so
RUN ln -sf /usr/lib/aarch64-linux-gnu/libcuda.so /usr/lib/aarch64-linux-gnu/libcuda.so.1

# add to link library path
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/tegra

## Clean up (don't remove cuda libs... used by child containers)
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    TERM="xterm"

RUN apt-get update && apt-get install -q -y --no-install-recommends \
    curl \
    socat \
    jq \
  \
  && rm -fr \
    /tmp/*

# Copy usr
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
    org.label-schema.name="jetson-cuda" \
    org.label-schema.description="JetsonTX with Jetpack and CUDA" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/jetson-cuda" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
