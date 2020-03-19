# &#127863; - `OPENVINO.md` - Intel Neural Compute Stick

This document provides a process to setup a RaspberryPi model 4 with an Intel Neural Compute Stick version 2.  The required system:

+ RaspberryPi Model 4
+ Raspian version 10 (aka `Buster`)

The RaspberryPi must have the required operating system installed and configured; for more [information](https://software.intel.com/en-us/articles/ARM-sbc-and-NCS2).

Software to be installed:

+ `OpenCV` [toolkit](https://opencv.org/)
+ `OpenVINO` [toolkit](http://software.intel.com/en-us/articles/intel-neural-compute-stick-2-and-open-source-openvino-toolkit)

## Step 1
Build and test the installation of OpenCV for the RaspberryPi4; **this step will take approximately one (1) hour.**

+ Create directory, copy required version of OpenCV, unpack
+ Build using `make` command with four (4) concurrent jobs
+ Define environment variable `OpenCV_DIR`
+ Test installation using Python

```
curl -sSL https://bootstrap.pypa.io/get-pip.py -o getpip.py
  && \
python3 getpip.py \
  && \
sudo pip3 install numpy
```


```
mkdir -p ~/GIT/
cd ~/GIT/
wget https://github.com/opencv/opencv/archive/4.1.0.zip
unzip 4.1.0.zip
cd opencv-4.1.0
mkdir build && cd build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local/ \
  -DPYTHON3_EXECUTABLE=/usr/bin/python3.7 \
  –DPYTHON_INCLUDE_DIR=/usr/include/python3.7 \
  –DPYTHON_INCLUDE_DIR2=/usr/include/arm-linux-gnueabihf/python3.7m \
  –DPYTHON_LIBRARY=/usr/lib/arm-linux-gnueabihf/libpython3.7m.so \
  ..
make -j4
sudo make install
export OpenCV_DIR=/usr/local/share/opencv4
python3 << EOF
import cv2
cv2.__version__
EOF
```

## Step 2
Download, build and test the Deep Learning Development Toolkit (`dldt`); **this step will take approximately ninety (90) minutes.**

+ Clone `opencv/dldt` repository, and pull all submodules recursively.
+ Install all dependecies
+ Create a build directory, configure the `make` files, and build
+ Test installation with provided `benchmark_app`

```
cd ~/GIT
git clone https://github.com/opencv/dldt.git
cd ~/GIT/dldt/inference-engine
git submodule init
git submodule update –-recursive
sudo ./install_dependencies.sh
mkdir build && cd build
export OpenCV_DIR=/usr/local/share/opencv4
cmake -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_MKL_DNN=OFF \
  -DENABLE_CLDNN=OFF \
  -DENABLE_GNA=OFF \
  -DENABLE_SSE42=OFF \
  -DTHREADING=SEQ \
  -DCMAKE_CXX_FLAGS='-march=armv7-a' \
  ..
make -j4
```

Test the build:

```
../bin/armv7l/Release/benchmark_app -h 
```

Sample output:

```
[Step 1/11] Parsing and validating input arguments
[ INFO ] Parsing input parameters

benchmark_app [OPTION]
Options:

    -h, --help                Print a usage message
    -i "<path>"               Optional. Path to a folder with images and/or binaries or to specific image or binary file.
    -m "<path>"               Required. Path to an .xml file with a trained model.
    -d "<device>"             Optional. Specify a target device to infer on (the list of available devices is shown below). Default value is CPU. Use "-d HETERO:<comma-separated_devices_list>" format to specify HETERO plugin. Use "-d MULTI:<comma-separated_devices_list>" format to specify MULTI plugin. The application looks for a suitable plugin for the specified device.
    -l "<absolute_path>"      Required for CPU custom layers. Absolute path to a shared library with the kernels implementations.
          Or
    -c "<absolute_path>"      Required for GPU custom kernels. Absolute path to an .xml file with the kernels description.
    -api "<sync/async>"       Optional. Enable Sync/Async API. Default value is "async".
    -niter "<integer>"        Optional. Number of iterations. If not specified, the number of iterations is calculated depending on a device.
    -nireq "<integer>"        Optional. Number of infer requests. Default value is determined automatically for device.
    -b "<integer>"            Optional. Batch size value. If not specified, the batch size value is determined from Intermediate Representation.
    -stream_output            Optional. Print progress as a plain text. When specified, an interactive progress bar is replaced with a multiline output.
    -t                        Optional. Time in seconds to execute topology.
    -progress                 Optional. Show progress bar (can affect performance measurement). Default values is "false".

  device-specific performance options:
    -nstreams "<integer>"     Optional. Number of streams to use for inference on the CPU or/and GPU in throughput mode (for HETERO and MULTI device cases use format <dev1>:<nstreams1>,<dev2>:<nstreams2> or just <nstreams>). Default value is determined automatically for a device.Please note that although the automatic selection usually provides a reasonable performance, it still may be non - optimal for some cases, especially for very small networks. See sample's README for more details.
    -nthreads "<integer>"     Optional. Number of threads to use for inference on the CPU (including HETERO and MULTI cases).
    -pin "YES"/"NO"           Optional. Enable ("YES" is default value) or disable ("NO") CPU threads pinning for CPU-involved inference.

  Statistics dumping options:
    -report_type "<type>"     Optional. Enable collecting statistics report. "no_counters" report contains configuration options specified, resulting FPS and latency. "average_counters" report extends "no_counters" report and additionally includes average PM counters values for each layer from the network. "detailed_counters" report extends "average_counters" report and additionally includes per-layer PM counters and latency for each executed infer request.
    -report_folder            Optional. Path to a folder where statistics report is stored.
    -exec_graph_path          Optional. Path to a file where to store executable graph information serialized.
    -pc                       Optional. Report performance counters.

Available target devices:  MYRIAD
```

Try to install:

```
sudo make install
```


## Step 3
Configure the NCS2 USB Driver by defining additional `udev` rules, restarting, and loading the driver.

```
sudo -s
cat > /etc/udev/rules.d/97-myriad-usbboot.rules << EOF
SUBSYSTEM=="usb", ATTRS{idProduct}=="2150", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
SUBSYSTEM=="usb", ATTRS{idProduct}=="2485", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
SUBSYSTEM=="usb", ATTRS{idProduct}=="f63b", ATTRS{idVendor}=="03e7", GROUP="users", MODE="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
EOF
udevadm control --reload-rules
udevadm trigger
ldconfig
exit
```

## Step 4
Download models

```
cd ~/GIT/dldt
mkdir models
cd models
curl -sL -o age-gender-recognition-retail-0013.xml \
  https://download.01.org/opencv/2019/open_model_zoo/R1/models_bin/age-gender-recognition-retail-0013/FP16/age-gender-recognition-retail-0013.xml 
curl -sL -o age-gender-recognition-retail-0013.bin \
  https://download.01.org/opencv/2019/open_model_zoo/R1/models_bin/age-gender-recognition-retail-0013/FP16/age-gender-recognition-retail-0013.bin 
curl -sL -o additional.tar.gz \
  https://software.intel.com/sites/default/files/managed/4e/7d/Setup%20Additional%20Files%20Package.tar.gz
tar xzvf additional.tar.gz
```

Sample directory contents:

```
-rwxr-xr-x 1 dcmartin dcmartin     378 Jun  3  2019 97-myriad-usbboot.rules_.txt
-rw-r--r-- 1 dcmartin dcmartin 2150634 Dec 16 02:27 additional.tar.gz
-rw-r--r-- 1 dcmartin dcmartin 4276038 Dec 16 02:27 age-gender-recognition-retail-0013.bin
-rw-r--r-- 1 dcmartin dcmartin   14936 Dec 16 02:27 age-gender-recognition-retail-0013.xml
-rwxr-xr-x 1 dcmartin dcmartin 2141365 Jun  3  2019 cat.jpg
-rwxr-xr-x 1 dcmartin dcmartin   10818 Jun  3  2019 president_reagan-62x62.png
```

## Step X
Test installation; possible architectures:

+ `armv7l `
+ `intel64`

```
cd ~/GIT/dldt/models
../inference-engine/bin/armv7l/Release/benchmark_app \
   -i president_reagan-62x62.png \
   -m age-gender-recognition-retail-0013.xml  \
   -d MYRIAD \
   -c $PWD/../inference-engine/bin/armv7l/Release/lib \
   -api async
```

Sample output:

```
[Step 1/11] Parsing and validating input arguments
[ INFO ] Parsing input parameters
[ INFO ] Files were added: 1
[ INFO ]     president_reagan-62x62.png
[ WARNING ] -nstreams default value is determined automatically for a device. Although the automatic selection usually provides a reasonable performance,but it still may be non-optimal for some cases, for more information look at README.

[Step 2/11] Loading Inference Engine
[ INFO ] InferenceEngine: 
	API version ............ 2.1
	Build .................. custom_2019_b0c5accaf8e0c0fac17aaef688478d7f391d05bb
	Description ....... API
[ INFO ] Device info: 
	MYRIAD
	myriadPlugin version ......... 2.1
	Build ........... custom_2019_b0c5accaf8e0c0fac17aaef688478d7f391d05bb

[Step 3/11] Reading the Intermediate Representation network
[ INFO ] Loading network files
[ INFO ] Read network took 18.13 ms
[Step 4/11] Resizing network to match image sizes and given batch
[ INFO ] Network batch size: 1, precision: FP16
[Step 5/11] Configuring input of the model
[Step 6/11] Setting device configuration
[Step 7/11] Loading the model to the device
[ INFO ] Load network took 2239.71 ms
[Step 8/11] Setting optimal runtime parameters
[Step 9/11] Creating infer requests and filling input blobs with images
[ INFO ] Network input 'data' precision U8, dimensions (NCHW): 1 3 62 62 
[ WARNING ] Some image input files will be duplicated: 4 files are required but only 1 are provided
[ INFO ] Infer Request 0 filling
[ INFO ] Prepare image president_reagan-62x62.png
libpng warning: iCCP: known incorrect sRGB profile
[ INFO ] Infer Request 1 filling
[ INFO ] Prepare image president_reagan-62x62.png
libpng warning: iCCP: known incorrect sRGB profile
[ INFO ] Infer Request 2 filling
[ INFO ] Prepare image president_reagan-62x62.png
libpng warning: iCCP: known incorrect sRGB profile
[ INFO ] Infer Request 3 filling
[ INFO ] Prepare image president_reagan-62x62.png
libpng warning: iCCP: known incorrect sRGB profile
[Step 10/11] Measuring performance (Start inference asyncronously, 4 inference requests, limits: 60000 ms duration)

[Step 11/11] Dumping statistics report
Count:      24416 iterations
Duration:   60011.68 ms
Latency:    9.44 ms
Throughput: 406.85 FPS
```
