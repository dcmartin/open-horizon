#!/bin/bash
if [ $(uname -m) = 'x86_64' ]; then
  cd /tmp
  wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run
  sudo sh cuda_10.2.89_440.33.01_linux.run
else
  echo "Unsupported architecture: $(uname -m)" &> /dev/stderr
fi
