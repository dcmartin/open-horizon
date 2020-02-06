# Open Horizon Setup

This repository contains sample scripts to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.  Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.  You may create and publish your patterns to your organization.  Refer to the [examples][examples] available on GitHub.

You will need an [IBM Cloud][ibm-cloud] account and IBM MessageHub credentials available in the Slack [channel][edge-slack].

## Supported devices
A target device or virtual environment is required; either of the following are sufficient.

### 1. Raspberry Pi 32-bit `arm`
+ [`Raspberry Pi Model 3B+`][raspberrypi-md]

[raspberrypi-md]: ../setup/RPI.md

### 2. Intel/AMD 64-bit `amd64`
Download a Debian/Ubuntu [image][ubuntu-image] and start a new virtual machine, e.g. using [VirtualBox][virtualbox], with the CD/DVD image as the boot device; change networking from `NAT` to `Bridged`.  **Note**: Install the VirtualBox Extensions Pack.  Connect to VM using `ssh` or use the GUI to start a Terminal session.

### 3. nVidia Jetson 64-bit `arm64`

+ [TX2][jetsontx2-md] - with Ubuntu 18.04 and JetPack 2.3.3/4.1.1
+ [Nano][nano-md] - with Ubuntu 18.04 and JetPack 4.2
+ [Xavier][xavier-md] - with Ubuntu 18.04 and JetPack 4.2

[jetsontx2-md]: ../setup/TX2.md
[nano-md]: ../setup/NANO.md
[xavier-md]: ../setup/XAVIER.md

# A. Manual Installation
## Process
### Step 0 - Set password and change host name
It is recommended, but not required, to change the default `pi` password,  as well as identify the device with a unique name for use in testing (e.g. `test-arm-1`); run the following commands on the target device:

```
sudo passwd pi
export DEVICE_NAME=test-arm-1
sudo sed -i "s|raspberrypi|${DEVICE_NAME}|" /etc/hosts
sudo sed -i "s|raspberrypi|${DEVICE_NAME}|" /etc/hostname
sudo hostname ${DEVICE_NAME}
```
The device will need to be rebooted for the name change to take effect on the LAN; then the device can be referenced by the name, e.g. `test-arm-1.local`.
### Step 1 - Install Open Horizon
For any Debian-based LINUX environment, e.g. Ubuntu or Raspbian.

If `docker` command is not installed, log into the device and run the commands below to install Docker:

```
wget -qO - get.docker.com | sudo bash
```

Then run the following commands to install Open Horizon:

```
wget -qO - ibm.biz/get-horizon | sudo bash
```

### Step 2 - Configure for development / testing

If the device is to be used for development and testing it will need to be configured with the appropriate account, privileges, and change `sudo` policy for that user to not require a password.  Run the following commands to create a new user:

```
export USERID=<your-userid>
sudo adduser ${USERID} 
```
Then add the user to both the `sudo` and `docker` groups:

```
sudo addgroup ${USERID} sudo
sudo addgroup ${USERID} docker
```
Finally, change the permissions for the user to enable password-less `sudo` with the following commands:

```
echo "${USERID} ALL=(ALL) NOPASSWD: ALL" > /tmp/nopasswd \
  && sudo chown root /tmp/nopasswd \
  && sudo chmod 400 /tmp/nopasswd \
  && sudo mv /tmp/nopasswd /etc/sudoers.d/010_${USERID}-nopasswd
```

The **development host** (e.g. Apple iMac or MacBook) will also need to be configured with SSH credentials (n.b. `~/.ssh/`) which are then copied to the device from the host; run the following command **on the development host** as `<your-userid>`:

```
ssh-copy-id <device-name>.local
```

After credentials are established, the device may be used to test [services][service-md] and [patterns][pattern-md].  Refer to [`BUILD.md`][build-md].

[make-md]: ../MAKE.md
[build-md]: ../BUILD.md
[pattern-md]: ../PATTERN.md
[service-md]: ../SERVICE.md

# B. Network installation

Installations can be automated over the network as new devices are discovered.  This technique is suitable for local-area network (LAN) deployments. Please refer to [these][network] instructions.

# C. System installation

System level installation modifies the operating system image boot sequence to install the Open Horizon software.  This technique is suitable for replication in mass quantities.  Please refer to [these][system] instructions.

# D. Horizon Addons

Add the repository [`https://github.com/dcmartin/hassio-addons`][dcm-addons] to the Add-on Store.  Install and start the following addons (n.b. both require `MSGHUB_API_KEY` to `listen` for Kafka messages):

+ [cpu2msghub][cpu2msghub-addon]: specifies the IBM published [cpu2msghub][cpu2msghub-pattern] pattern, which sends CPU load from `/sys/proc` and GPS location to a _private_ Kafka topic; optionally listens to the _private_ Kafka topic and publishes a JSON payload to topic `kafka/cpu-load` on designated MQTT server, e.g. `core-mosquitto`
+ [sdr2msghub][sdr2msghub-addon]: specifies the IBM published [sdr2msghub][sdr2msghub-pattern] pattern, which sends software-defined-radio (SDR) audio and GPS location to a _shared_ Kafka topic; optionally listens to the _shared_ Kafka topic and publishes a JSON payload to topic `kafka/sdr-audio` on designated MQTT server, e.g. `core-mosquitto`
  - Optional: Converts audio received into text using IBM Watson Speech-to-Text (STT) service.
  - Optional: Parses text into language using IBM Natural Language Understanding (NLU) service.

## Sample Output

![sdr2msghub sentiment](https://github.com/dcmartin/hassio-addons/raw/master/sdr2msghub/sdr2msghub_sentiment.png?raw=true "SDR2MSGHUB")
![cpu2msghub sentiment](https://github.com/dcmartin/hassio-addons/raw/master/cpu2msghub/cpu2msghub_cpu.png?raw=true "CPU2MSGHUB")

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)


[commits]: https://github.com/dcmartin/open-horizon/setup/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/setup/graphs/contributors
[cpu2msghub-addon]: https://github.com/dcmartin/hassio-addons/tree/master/cpu2msghub
[cpu2msghub-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/cpu2msghub
[dcm-addons]: https://github.com/dcmartin/hassio-addons
[dcmartin]: https://github.com/dcmartin
[docker]: https://www.docker.com/
[examples]: https://github.com/open-horizon/examples
[ha-addons]: https://github.com/hassio-addons
[ha-home]: https://www.home-assistant.io/
[hassio-install]: https://www.home-assistant.io/hassio/installation/
[hassio-setup]: ../setup/hassio-install.sh
[horizon-setup]: ../setup/hzn-install.sh
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-cloud]: http://cloud.ibm.com/
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/setup/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[network]: ../setup/NETWORK.md
[open-horizon]: https://github.com/open-horizon
[raspbian-image]: https://www.raspberrypi.org/downloads/raspbian/
[releases]: https://github.com/dcmartin/open-horizon/setup/releases
[repository]: https://github.com/dcmartin/open-horizon/setup
[sdr2msghub-addon]: https://github.com/dcmartin/hassio-addons/tree/master/sdr2msghub
[sdr2msghub-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/sdr2msghub
[setup-readme]: ../setup/README.md
[setupdir]: ../setup
[system]: ../setup/SYSTEM.md
[ubuntu-image]: http://releases.ubuntu.com/18.04.1/
[virtualbox]: http://www.virtualbox.org/
