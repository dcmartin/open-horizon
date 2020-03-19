# from Ubuntu 16.04
FROM arm64v8/ubuntu:xenial-20190122 as jetsontx2-xenial-drivers

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

FROM jetsontx2-xenial-drivers as jetsontx2-jetpack33

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

###
### CUDA
###

FROM jetsontx2-jetpack33 as jetsontx2-cuda9

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

###
### OPENCV
###

FROM jetsontx2-cuda9 as jetsontx2-opencv

RUN apt-get update && apt-get install -y \
	pkg-config

RUN apt-get update && apt-get install -y \
	libavcodec-ffmpeg56 \
	libavformat-ffmpeg56 \
	libavutil-ffmpeg54 \
	libswscale-ffmpeg3

RUN apt-get update && apt-get install -y \
	libcairo2 \
	libgdk-pixbuf2.0-0 \
	libgtk2.0-0

RUN apt-get update && apt-get install -y \
	libpng12-0

RUN apt-get update && apt-get install -y \
	libtbb2 \
	libglib2.0-0 \
	libjasper1 \
	libjpeg8>=8c \
	libtbb-dev

RUN for DEB in \
	libopencv_3.3.1_t186_arm64.deb \
	libopencv-dev_3.3.1_t186_arm64.deb \
	libopencv-samples_3.3.1_t186_arm64.deb \
	libopencv-python_3.3.1_t186_arm64.deb \
	; do dpkg --install ${DEB}; done

## Clean up 
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt

###
### CAFFE
###

FROM jetsontx2-opencv as jetsontx2-caffe

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
	build-essential \
	cmake \
	git \
	gfortran \
	libatlas-base-dev \
	libboost-all-dev \
	libgflags-dev \
	libfreetype6-dev \
	libpng12-dev \
	libgoogle-glog-dev \
	libhdf5-dev \
	libhdf5-serial-dev \
	libleveldb-dev \
	liblmdb-dev \
	libprotobuf-dev \
	libsnappy-dev \
	protobuf-compiler \
	python-all-dev \
	python-dev \
	python-pip \
	pkg-config

# Pip for python stuff
RUN pip install --upgrade --no-cache-dir pip setuptools wheel
RUN pip install --no-cache-dir numpy
RUN pip install --no-cache-dir pillow matplotlib h5py protobuf scipy scikit-image scikit-learn

WORKDIR /
RUN git clone https://github.com/BVLC/caffe

WORKDIR /caffe
RUN apt-get install -y python-setuptools
WORKDIR /caffe/python
RUN for req in $(cat requirements.txt); do pip install --no-cache-dir $req; done

## BUILD CAFFE

WORKDIR /caffe

# configuration
ARG MAKE_ARGS="USE_CUDNN=1 USE_LEVELDB=1 USE_LMDB=1 USE_HDF5=1 USE_OPENCV=1 OPENCV_VERSION=3"

# configure Makefile.config
RUN cat Makefile.config.example \
	# CUDA9.0: comment out "compute_20" line in Makefile.config (this arch obsolete)
	| sed 's/-gencode arch=compute_20,code=sm_20/#-gencode arch=compute_20,code=sm_20/' \
	> Makefile.config

# extra include directories
ARG EXTRA_INCLUDE_DIR="/usr/local/include /usr/local/lib/python2.7/dist-packages/numpy/core/include /usr/include/hdf5/serial"
RUN sed -i "s|^INCLUDE_DIRS := \(.*\)|INCLUDE_DIRS := \1 ${EXTRA_INCLUDE_DIR}|" Makefile.config

# Build
RUN echo 'obj: $(OBJS)' >> Makefile
RUN make ${MAKE_ARGS} obj -j4

# extra library directories
ARG EXTRA_LIBRARY_DIR="/usr/local/lib /usr/local/cuda/lib64 /usr/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu/hdf5/serial/lib"
RUN sed -i "s|^LIBRARY_DIRS := \(.*\)|LIBRARY_DIRS := \1 ${EXTRA_LIBRARY_DIR}|" Makefile.config

# link, etc..
RUN make ${MAKE_ARGS} lib -j4
RUN make ${MAKE_ARGS} tools -j4
RUN make ${MAKE_ARGS} examples -j4
RUN make ${MAKE_ARGS} pycaffe -j4
RUN make ${MAKE_ARGS} test -j4
RUN make ${MAKE_ARGS} distribute

# Clean up
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt
