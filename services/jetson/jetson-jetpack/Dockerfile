ARG BUILD_FROM=arm64v8/ubuntu:xenial-20190122
  
FROM $BUILD_FROM as drivers

ARG BUILD_ARCH=arm64

# Update packages, install some useful packages
RUN apt update && apt install -y \
	apt-utils \
	bzip2 \
	sudo \
	curl \
  && apt-get clean && rm -rf /var/cache/apt

###
### Linux for Tegra R28.2.1 - from https://developer.nvidia.com/embedded/linux-tegra-r2821
###

ARG DRIVER=https://developer.nvidia.com/embedded/dlc/tx2-driver-package-r2821
# ARG DRIVER=https://developer.download.nvidia.com/embedded/L4T/r28_Release_v2.1/Tegra186_Linux_R28.2.1_aarch64.tbz2?13qZ4v6KW-jZhShNacOKJuPQokXaJovAgsQDweNHk8WGu4th8Sz3K1mrnuh_Pkckrp6B0-HmmEpopd_dt-BliMjOMzA6U-jOdf5puStXvE_WrICmI66emlPmizA1XIGVobM8oUeektM8e_SCFJUH3KTU6-K62gY-yIEVoXM7jcM

# creates the Linux_for_Tegra/ directory 
RUN curl -sSL ${DRIVER} | tar xpfj - 
RUN ./Linux_for_Tegra/apply_binaries.sh -r /
RUN rm -fr ./Linux_for_Tegra

## Clean up (don't remove cuda libs... used by child containers)
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt

###
### JETPACK 
###

FROM drivers

# from https://layers.openembedded.org/layerindex/recipe/87651/
ARG JETPACK_URL=https://developer.download.nvidia.com/devzone/devcenter/mobile/jetpack_l4t/3.3/lw.xd42/JetPackL4T_33_b39

# retrieve all packages in JetPack
RUN for DEB in \
	cuda-repo-l4t-9-0-local_9.0.252-1_arm64.deb \
	libcudnn7_7.1.5.14-1+cuda9.0_arm64.deb \
	libcudnn7-dev_7.1.5.14-1+cuda9.0_arm64.deb \
	libcudnn7-doc_7.1.5.14-1+cuda9.0_arm64.deb \
	libopencv_3.3.1_t186_arm64.deb \
	libopencv-dev_3.3.1_t186_arm64.deb \
	libopencv-samples_3.3.1_t186_arm64.deb \
	libopencv-python_3.3.1_t186_arm64.deb \
	libgie-dev_4.1.3-1+cuda9.0_arm64.deb \
	libnvinfer-dev_4.1.3-1+cuda9.0_arm64.deb \
	libnvinfer-samples_4.1.3-1+cuda9.0_arm64.deb \
	libnvinfer4_4.1.3-1+cuda9.0_arm64.deb \
	libvisionworks-repo_1.6.0.500n_arm64.deb \
	libvisionworks-sfm-repo_0.90.3_arm64.deb \
	libvisionworks-tracking-repo_0.88.1_arm64.deb \
	tensorrt_4.0.2.0-1+cuda9.0_arm64.deb \
	; \
	do URL=${JETPACK_URL}/${DEB}; \
		curl -sSL ${URL} -o ${DEB}; \
	done

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
    org.label-schema.name="jetson-jetpack" \
    org.label-schema.description="Jetpack installed on JetsonTX" \
    org.label-schema.vcs-url="http://github.com/dcmartin/open-horizon/tree/master/jetson-jetpack" \
    org.label-schema.vcs-ref="${BUILD_REF}" \
    org.label-schema.version="${BUILD_VERSION}" \
    org.label-schema.vendor="David C Martin <github@dcmartin.com>"
