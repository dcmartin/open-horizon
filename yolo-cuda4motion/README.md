```
sudo apt install gnupg2 pass
```

```
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
```

```
sudo apt-get install nvidia-container-runtime
```

## RaspberryPi Camera Module
The Pi’s camera has a discrete set of input modes. On the V2 camera these are as follows:

Number|Resolution|Aspect Ratio|Framerates|Video|Image|FoV|Binning
:-------|-------|-------|-------|-------|-------|-------|-------
1|1920x1080|16:9|0.1-30fps|x|||Partial|None
2|3280x2464|4:3|0.1-15fps|x|x|Full|None
3|3280x2464|4:3|0.1-15fps|x|x|Full|None
4|1640x1232|4:3|0.1-40fps|x|||Full|2x2
5|1640x922|16:9|0.1-40fps|x|||Full|2x2
6|1280x720|16:9|40-90fps|x|||Partial|2x2
7|640x480|4:3|40-90fps|x|||Partial|2x2

### Field-of-View
<img src="https://picamera.readthedocs.io/en/release-1.12/_images/sensor_area_2.png">
