# `TX2.md` - Install on nVidia TX2

**WARNING**: _work in progress_

The nVidia TX2 is configured using the nVidia JetPack.  The latest version for TX2 is version 3.3 and is Ubuntu 16.04.  To install you will need both the v3.3 JetPack as well as the current 4.1.1.  Both may be downloaded from the [nVidia Developer portal][nvidia-developer].  These instructions depend on the utilization of a VMWare Fusion or Workstation virtual machine running Ubuntu version 14.04 LTS. Other virtual machine systems may work (n.b. USB connectivity is required) as well as other versions of Ubuntu on the host computer; refer to the nVidia Developer portal for more information.

[nvidia-developer]: https://developer.nvidia.com/embedded/jetpack

The two JetPack versions used in this document are:

+ `JetPack-L4T-4.1.1-linux-x64_b57.run`
+ `JetPack-L4T-3.3-linux-x64_b39.run`

## Step 1 
To maintain separation, create two different directories, one for each version:

```
mkdir ~/JP33 ~/JP411
```

Then move the downloaded JetPacks into the respective directory:

```
mv JetPack-L4T-3.3-linux-x64_b39.run ~/JP33/
mv JetPack-L4T-4.1.1-linux-x64_b57.run ~/JP411/
```
## Step 2
Each JetPack will download a variety of additional items that may be necessary in future development.  First run the earlier version:

```
cd ~/JP33 
bash JetPack-L4T-3.3-linux-x64_b39.run
```

A graphical user-interface provides the ability to configure the JetPack and download additional software; default is _full_ and is recommended.  Once the software has been downloaded and the application indicates it is ready to proceed, quit the JetPack.

Repeat the process for the newer version:

```
cd ~/JP411
bash JetPack-L4T-4.1.1-linux-x64_b57.run
```

## Step 3
Once both JetPacks have been configured and downloaded, remove the original `rootfs/` directory, make a new one, then uncompress and copy the contents of the newer release operating system:

```
sudo rm -fr ~/JP33/64_TX2/Linux_for_Tegra/rootfs
mkdir ~/JP33/64_TX2/Linux_for_Tegra/rootfs
bunzip2 -c ~/JP411/jetpack_download/Tegra_Linux_Sample-Root-Filesystem_R3.1.1.0_aarch64.tbz2 \
  | ( cd ~/JP33/64_TX2/Linux_for_Tegra/rootfs/ ; tar xf - )
bunzip2 -c ~/JP411/jetpack_download/Jetson_Linux_R3.1.1.0_aarch64.tbz2 \
  | ( cd ~/JP33/64_TX2 ; sudo tar xf - )
```

**Note:** Direct links to the [file-system][jetpack-411-filesystem] and [drivers][jetpack-411-drivers] compressed `tar` archives.

[jetpack-411-filesystem]: https://developer.nvidia.com/embedded/dlc/l4t-sample-root-filesystem-31-1-0
[jetpack-411-drivers]: https://developer.nvidia.com/embedded/dlc/l4t-jetson-xavier-driver-package-31-1-0

## Step 4
Once the copy is complete, change directory and run the following command to configure the binaries:

```
cd ~/JP33/64_TX2/Linux_for_Tegra
sudo ./apply_binaries.sh
```

When that command completes, reset the TX2 into recovery mode with a USB cable connected and run the following command:

```
sudo ./flash.sh jetson-tx2 mmcblk0p1
```
If this command results in failure, check whether the nVidia TX is connected by running the `lsusb` command; there should be an entry for `nVidia`.

## Step 5

After the TX2 has been flashed with the new image, reboot the TX2 using the _reset_ button (n.b. the one closest to the corner).  Wait until the TX2 boots; ff you don't know the TX2 network address, search the connected local-area-network (LAN); for example, find all devices on the LAN identified by `nvidia`:

```
sudo nmap -sn -T5 192.168.1.0/24 | egrep -B2 -i 'nvidia'
```

Once the TX2 has booted and is identified on the network, copy the `~/JP411/jetpack_download/` directory from the VMware Ubuntu host to the TX2; use default _login_ `nvidia` with _password_ `nvidia`; for example, if the TX2 addreess is `192.168.1.31`:

```
scp -r ~/JP411/jetpack_download/ nvidia@192.168.1.31:.
```

After this step the VMware virtual machine host is no longer required.

## Step 6
Log into the TX2 with with default login `nvidia` with password `nvidia` and update, for example with TX addresss of `192.168.1.31`:

```
ssh 192.168.1.31 -l nvidia
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
```

## Step 7 \[optional\]
Add external SSD hard drive:

```
sudo -s
mkdir /sda
echo '/dev/sda /sda /ext4' >> /etc/fstab
mount -a
```

Install `rsync`

```
sudo apt install -y rsync
```

Relocate `/var/lib/docker` to SSD:

```
sudo -s
systemctl stop docker
rsync -a /var/lib/docker /sda/docker
rm -fr /var/lib/docker
ln -s /sda/docker /var/lib/docker
systemctl start docker
```

Relocate `/home` to SSD:

```
sudo -s
rsync -a /home /sda/home
rm -fr /home
ln -s /sda/home /home
```

## Step 8
Secure built-in accounts `nvidia` and `ubuntu`, create new account, add group permissions:

```
sudo passwd nvidia
sudo passwd ubuntu
sudo adduser <yourid>
sudo addgroup <yourid> sudo
sudo addgroup <yourid> docker
```

Logout of `nvidia` account and re-login with `<yourid>`.

## Step 9 \[optional\]

Install CUDA, OpenCV, and other packages copied from VMware host. On the TX2 enter:

```
cd ~/jetpack_download
sudo -s
add-apt-repository ppa:graphics-drivers
apt update -y
apt upgrade -y
apt install -y libtbb2
dpkg --install libopencv_3.3.1_arm64.deb
dpkg --install cuda-repo-l4t-10-0-local-10.0.117_1.0-1_arm64.deb
apt install -y cuda-license-10-0
apt install -y cuda-cublas-10-0
dpkg --install libcudnn7-dev_7.3.1.20-1+cuda10.0_arm64.deb
dpkg --install libnvinfer5_5.0.3-1+cuda10.0_arm64.deb 
dpkg --install libnvinfer-dev_5.0.3-1+cuda10.0_arm64.deb 
dpkg --install libnvinfer-samples_5.0.3-1+cuda10.0_all.deb
dpkg --install tensorrt_5.0.3.2-1+cuda10.0_arm64.deb 
apt update -y
apt upgrade -y
apt autoremove -y
apt install -y cuda-libraries-10-0
apt install -y cuda-nvtx-10-0
apt install -y libnvidia-common-390
```

```
sudo dpkg --install cuda-repo-l4t-9-0-local_9.0.252-1_arm64.deb
sudo dpkg --install libcudnn7_7.1.5.14-1+cuda9.0_arm64.deb

```

## Step 10
Remove old `docker` and install new `docker-ce`

```
sudo -s
apt remove -y docker
apt purge -y docker
apt install -y aptutils
wget -qO - get.docker.com | sudo bash
```

## Step X
Install Open Horizon

```
wget -qO - ibm.biz/get-horizon | sudo bash
```

## Step Y
Turn on Wifi

```
sudo nmcli dev wifi connect <SSID> password <PASSWORD>
```
