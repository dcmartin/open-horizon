# `TRAVIS.md` -  [![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)

[Travis][travis-ci] provides automated execution of jobs in the continuous integration process.  Status of this repository is indicated by the badge above.  

## <img src="travis.png" width=48> Travis jobs

Jobs are defined in a YAML file for the GIT repository; this [repository][repository] has configuration file: [`.travis.yml`][travis-yaml] 

[travis-yaml]: ../.travis.yml
[travis-ci]: https://travis-ci.org/

### Job Lifecycle
The complete job lifecycle, including three optional deployment phases and after checking out the git repository and changing to the repository directory:

+    _OPTIONAL Install_ `apt addons`
+    _OPTIONAL Install_ `cache components`
+    `before_install`
+    `install`
+    `before_script`
+    `script`
+    _OPTIONAL_ `before_cache` (for cleaning up cache)
+    `after_success` or `after_failure`
+    _OPTIONAL_ `before_deploy`
+    _OPTIONAL_ `deploy`
+    _OPTIONAL_ `after_deploy`
+    `after_script`

A build can be composed of many jobs.



##  <img src="https://raw.githubusercontent.com/multiarch/dockerfile/master/logo.jpg" width=48> Multiple architectures

Services may support more than one architecture.  While certain Docker implementations provide emulation for other architectures, e.g. macOS supports `amd64`, `arm64`, and `arm`, the generic LINUX implementation utilized by TravisCI does not.

To utilize generic LINUX to build for multiple architectures requires the addition of [**QEMU**][qemu-static] emulation support as well as utilization of multi-architecture enabled _base_ container images.

[qemu-static]: https://hub.docker.com/r/multiarch/qemu-user-static

### Official `multiarch` images
The official [`multiarch`][multiarch-namespace] namespace on Docker Hub has repositories of QEMU enabled images for various architectures:

[multiarch-namespace]: https://hub.docker.com/u/multiarch/

+ `arm32v6` - https://hub.docker.com/u/arm32v6/
+ `arm32v7` - https://hub.docker.com/u/arm32v7/
+ `arm64v8` - https://hub.docker.com/u/arm64v8/
+ `s390x` - https://hub.docker.com/u/s390x
+ `ppc64le` - https://hub.docker.com/u/ppc64le/

### LINUX Platforms:

+ Ubuntu [`core`][multiarch-ubuntu-core]
+ [Alpine][multiarch-alpine]

[multiarch-ubuntu-core]: https://hub.docker.com/r/multiarch/ubuntu-core
[multiarch-alpine]: https://hub.docker.com/r/multiarch/alpine

#### Recommended:

name|`tag`|size|update
---|---|---|---|
alpine|aarch64-latest-stable|6 MB|8 months ago
alpine|arm64-latest-stable|6 MB|8 months ago
alpine|armhf-latest-stable|6 MB|8 months ago
alpine|amd64-latest-stable|7 MB|8 months ago
alpine|i386-latest-stable|7 MB|8 months ago
alpine|x86_64-latest-stable|7 MB|8 months ago
alpine|x86-latest-stable|7 MB|8 months ago
ubuntu-core|arm64-xenial|41 MB|9 months ago
ubuntu-core|arm64-bionic|30 MB|9 months ago
ubuntu-core|x86_64-xenial|45 MB|9 months ago
ubuntu-core|x86_64-bionic|33 MB|9 months ago
ubuntu-core|x86-xenial|45 MB|9 months ago
ubuntu-core|x86-bionic|34 MB|9 months ago
ubuntu-core|armf-xenial|40 MB|9 months ago
ubuntu-core|armf-bionic|28 MB|9 months ago
ubuntu-core|i386-xenial|51 MB|3 years ago
ubuntu-core|amd64-xenial|50 MB|3 years ago
ubuntu-core|ppc64el-xenial|53 MB|3 years ago

### Example: `ubuntu-base/build.json`

```
{
    "squash": false,
    "build_from": {
        "amd64": "multiarch/ubuntu-core:amd64-xenial",
        "arm": "multiarch/ubuntu-core:armhf-bionic",
        "arm64": "multiarch/ubuntu-core:arm64-bionic",
        "386": "multiarch/ubuntu-core:i386-xenial",
        "ppc64": null,
        "ppc64le": "multiarch/ubuntu-core:ppc64el-xenial",
        "mips64": null,
        "mips64le": null,
        "s390x": null,
        "mips": null,
        "mipsle": null
    },
    "args": {}
}
```

## QEMU in Travis
QEMU container emulation:

```
before_script:
  - docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

### Verify QEMU

For ARMv7 (`armhf`)

```
docker run -it --rm -v /usr/bin/qemu-arm-static:/usr/bin/qemu-arm-static arm32v7/debian /bin/bash
```

For System 390:

```
docker run -it --rm -v /usr/bin/qemu-s390x-static:/usr/bin/qemu-s390x-static s390x/debian /bin/bash
```

For PowerPC (little endian):

```
docker run -it --rm -v /usr/bin/qemu-ppc64le-static:/usr/bin/qemu-ppc64le-static ppc64le/debian /bin/bash
```

# Build

```
sudo: true
language: bash
services: 
  - docker
dist: xenial
branches:
  only:
    - master
env:
  - BUILD_ARCH=amd64
#  - BUILD_ARCH=arm
#  - BUILD_ARCH=arm64
addons:
  apt:
    update: true
    sources:
    - sourceline: deb [arch=amd64,arm,arm64] http://pkg.bluehorizon.network/linux/ubuntu xenial-updates main
      key_url: 'http://pkg.bluehorizon.network/bluehorizon.network-public.key'
    packages:
    - make
    - curl
    - jq
    - ca-certificates
    - gnupg
    - bluehorizon
    - docker-ce
# https://dev.to/zeerorg/build-multi-arch-docker-images-on-travis-5428
before_install:
  - if [ ${BUILD_ARCH} == 'arm' ] && [ ! -z ${QEMU:-} ]; then sudo apt-get install qemu binfmt-support qemu-user-static -y; fi
  - if [ ${BUILD_ARCH} == 'arm' ]; then sudo docker run --privileged linuxkit/binfmt:v0.6 && sudo docker run -d --privileged -p 1234:1234 --name buildkit moby/buildkit:latest --addr tcp://0.0.0.0:1234 --oci-worker-platform linux/amd64 --oci-worker-platform linux/armhf && sudo docker cp buildkit:/usr/bin/buildctl /usr/bin/ && export BUILDKIT_HOST=tcp://0.0.0.0:1234; fi
before_script:
  - if [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_LOGIN}" --password-stdin; echo "${HZN_ORG_ID}" > HZN_ORG_ID; echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE; echo "${HZN_EXCHANGE_APIKEY}" > APIKEY; echo "${PRIVATE_KEY}" | base64 --decode > "${HZN_ORG_ID}.key"; echo "${PUBLIC_KEY}" | base64 --decode > "${HZN_ORG_ID}.pem"; if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi; else if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi; fi
script:
script:
  - export BRANCH=$(if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then echo $TRAVIS_BRANCH; else echo $TRAVIS_PULL_REQUEST_BRANCH; fi)
  - echo "TRAVIS_BRANCH=$TRAVIS_BRANCH, PR=$PR, BRANCH=$BRANCH"
  - make build && make test-service
after_success:
  - make push
  - make publish-service
  - make pattern-publish
```

The configuration provides environmental (`env`) controls for the build process, including installation of software (`apt`).  A virtual machine spawned Docker container executes the corresponding tasks; the container environment limits the capabilities to `build`, `push`, and `publish` targets.  See [MAKE.md][make-md] for more information.

[make-md]: https://github.com/dcmartin/open-horizon/edit/master/doc/MAKE.md
[travis-md]: https://github.com/dcmartin/open-horizon/edit/master/doc/TRAVIS.md
[travis-yaml]: https://github.com/dcmartin/open-horizon/edit/master/.travis.yml

## Example Output (travis-ci.org)

```
Build system information
Build language: bash
Build group: stable
Build dist: xenial
Build id: 516482503
Job id: 516482504
Runtime kernel version: 4.15.0-1026-gcp
travis-build version: d6b12fc73
Build image provisioning date and time
Mon Jan 14 09:03:51 UTC 2019
Operating System Details
Distributor ID:	Ubuntu
Description:	Ubuntu 16.04.5 LTS
Release:	16.04
Codename:	xenial
Systemd Version
systemd 229
Cookbooks Version
f9b6c9e https://github.com/travis-ci/travis-cookbooks/tree/f9b6c9e
git version
git version 2.20.1
bash version
GNU bash, version 4.3.48(1)-release (x86_64-pc-linux-gnu)
gcc version
gcc (Ubuntu 5.4.0-6ubuntu1~16.04.11) 5.4.0 20160609
docker version
Client:
 Version:           18.06.0-ce
 API version:       1.38
 Go version:        go1.10.3
 Git commit:        0ffa825
 Built:             Wed Jul 18 19:11:02 2018
 OS/Arch:           linux/amd64
 Experimental:      false
Server:
 Engine:
  Version:          18.06.0-ce
  API version:      1.38 (minimum version 1.12)
  Go version:       go1.10.3
  Git commit:       0ffa825
  Built:            Wed Jul 18 19:09:05 2018
  OS/Arch:          linux/amd64
  Experimental:     false
clang version
clang version 7.0.0 (tags/RELEASE_700/final)
jq version
jq-1.5
bats version
Bats 0.4.0
shellcheck version
0.6.0
shfmt version
v2.6.2
ccache version
3.2.4
cmake version
cmake version 3.12.4
34mheroku version
heroku/7.19.4 linux-x64 node-v11.3.0
imagemagick version
Version: ImageMagick 6.8.9-9 Q16 x86_64 2018-09-28 http://www.imagemagick.org
md5deep version
4.4
mercurial version
version 4.8
mysql version
mysql  Ver 14.14 Distrib 5.7.24, for Linux (x86_64) using  EditLine wrapper
openssl version
OpenSSL 1.0.2g  1 Mar 2016
packer version
1.3.3
postgresql client version
psql (PostgreSQL) 9.5.14
ragel version
Ragel State Machine Compiler version 6.8 Feb 2013
sudo version
1.8.16
gzip version
gzip 1.6
zip version
Zip 3.0
vim version
VIM - Vi IMproved 7.4 (2013 Aug 10, compiled Nov 24 2016 16:44:48)
iptables version
iptables v1.6.0
curl version
curl 7.47.0 (x86_64-pc-linux-gnu) libcurl/7.47.0 GnuTLS/3.4.10 zlib/1.2.8 libidn/1.32 librtmp/2.3
wget version
GNU Wget 1.17.1 built on linux-gnu.
rsync version
rsync  version 3.1.1  protocol version 31
gimme version
v1.5.3
nvm version
0.34.0
perlbrew version
/home/travis/perl5/perlbrew/bin/perlbrew  - App::perlbrew/0.85
phpenv version
rbenv 1.1.1-39-g59785f6
rvm version
rvm 1.29.7 (latest) by Michal Papis, Piotr Kuczynski, Wayne E. Seguin [https://rvm.io]
default ruby version
ruby 2.5.3p105 (2018-10-18 revision 65156) [x86_64-linux]
apt
Adding APT Sources
0.25s$ curl -sSL "http://pkg.bluehorizon.network/bluehorizon.network-public.key" | sudo -E apt-key add -
OK
0.01s$ echo "deb [arch=amd64,arm,arm64] http://pkg.bluehorizon.network/linux/ubuntu xenial-updates main" | sudo tee -a ${TRAVIS_ROOT}/etc/apt/sources.list >/dev/null
Installing APT Packages
11.01s$ travis_apt_get_update
7.23s$ sudo -E apt-get -yq --no-install-suggests --no-install-recommends $(travis_apt_get_options) install make curl jq ca-certificates gnupg bluehorizon docker-ce
Reading package lists...
Building dependency tree...
Reading state information...
make is already the newest version (4.1-6).
make set to manually installed.
ca-certificates is already the newest version (20170717~16.04.2).
gnupg is already the newest version (1.4.20-1ubuntu3.3).
docker-ce is already the newest version (18.06.0~ce~3-0~ubuntu).
The following additional packages will be installed:
  horizon horizon-cli libcurl3-gnutls libcurl4-gnutls-dev libonig2
Suggested packages:
  libcurl4-doc libcurl3-dbg libgnutls-dev libidn11-dev librtmp-dev
The following NEW packages will be installed:
  bluehorizon horizon horizon-cli jq libonig2
The following packages will be upgraded:
  curl libcurl3-gnutls libcurl4-gnutls-dev
3 upgraded, 5 newly installed, 0 to remove and 117 not upgraded.
Need to get 10.1 MB of archives.
After this operation, 42.0 MB of additional disk space will be used.
Get:1 http://pkg.bluehorizon.network/linux/ubuntu xenial-updates/main amd64 horizon-cli amd64 2.22.6~ppa~ubuntu.xenial [3,972 kB]
Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu xenial-updates/main amd64 curl amd64 7.47.0-1ubuntu2.12 [139 kB]
Get:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu xenial-updates/main amd64 libcurl4-gnutls-dev amd64 7.47.0-1ubuntu2.12 [261 kB]
Get:4 http://us-east-1.ec2.archive.ubuntu.com/ubuntu xenial-updates/main amd64 libcurl3-gnutls amd64 7.47.0-1ubuntu2.12 [185 kB]
Get:5 http://us-east-1.ec2.archive.ubuntu.com/ubuntu xenial-updates/universe amd64 libonig2 amd64 5.9.6-1ubuntu0.1 [86.7 kB]
Get:6 http://us-east-1.ec2.archive.ubuntu.com/ubuntu xenial-updates/universe amd64 jq amd64 1.5+dfsg-1ubuntu0.1 [144 kB]
Get:7 http://pkg.bluehorizon.network/linux/ubuntu xenial-updates/main amd64 horizon amd64 2.22.6~ppa~ubuntu.xenial [5,287 kB]
Get:8 http://pkg.bluehorizon.network/linux/ubuntu xenial-updates/main amd64 bluehorizon all 2.22.6~ppa~ubuntu.xenial [25.8 kB]
Fetched 10.1 MB in 0s (51.8 MB/s)
(Reading database ... 104302 files and directories currently installed.)
Preparing to unpack .../curl_7.47.0-1ubuntu2.12_amd64.deb ...
Unpacking curl (7.47.0-1ubuntu2.12) over (7.47.0-1ubuntu2.11) ...
Preparing to unpack .../libcurl4-gnutls-dev_7.47.0-1ubuntu2.12_amd64.deb ...
Unpacking libcurl4-gnutls-dev:amd64 (7.47.0-1ubuntu2.12) over (7.47.0-1ubuntu2.11) ...
Preparing to unpack .../libcurl3-gnutls_7.47.0-1ubuntu2.12_amd64.deb ...
Unpacking libcurl3-gnutls:amd64 (7.47.0-1ubuntu2.12) over (7.47.0-1ubuntu2.11) ...
Selecting previously unselected package horizon-cli.
Preparing to unpack .../horizon-cli_2.22.6~ppa~ubuntu.xenial_amd64.deb ...
Unpacking horizon-cli (2.22.6~ppa~ubuntu.xenial) ...
Selecting previously unselected package libonig2:amd64.
Preparing to unpack .../libonig2_5.9.6-1ubuntu0.1_amd64.deb ...
Unpacking libonig2:amd64 (5.9.6-1ubuntu0.1) ...
Selecting previously unselected package jq.
Preparing to unpack .../jq_1.5+dfsg-1ubuntu0.1_amd64.deb ...
Unpacking jq (1.5+dfsg-1ubuntu0.1) ...
Selecting previously unselected package horizon.
Preparing to unpack .../horizon_2.22.6~ppa~ubuntu.xenial_amd64.deb ...
Unpacking horizon (2.22.6~ppa~ubuntu.xenial) ...
Selecting previously unselected package bluehorizon.
Preparing to unpack .../bluehorizon_2.22.6~ppa~ubuntu.xenial_all.deb ...
Unpacking bluehorizon (2.22.6~ppa~ubuntu.xenial) ...
Processing triggers for man-db (2.7.5-1) ...
Processing triggers for libc-bin (2.23-0ubuntu10) ...
Setting up libcurl3-gnutls:amd64 (7.47.0-1ubuntu2.12) ...
Setting up curl (7.47.0-1ubuntu2.12) ...
Setting up libcurl4-gnutls-dev:amd64 (7.47.0-1ubuntu2.12) ...
Setting up horizon-cli (2.22.6~ppa~ubuntu.xenial) ...
Setting up libonig2:amd64 (5.9.6-1ubuntu0.1) ...
Setting up jq (1.5+dfsg-1ubuntu0.1) ...
Setting up horizon (2.22.6~ppa~ubuntu.xenial) ...
Setting up bluehorizon (2.22.6~ppa~ubuntu.xenial) ...
Created symlink from /etc/systemd/system/multi-user.target.wants/horizon.service to /lib/systemd/system/horizon.service.
Processing triggers for libc-bin (2.23-0ubuntu10) ...
services
0.02s$ sudo systemctl start docker
git.checkout
1.50s$ git clone --depth=50 --branch=master https://github.com/[secure]/open-horizon.git [secure]/open-horizon
Cloning into '[secure]/open-horizon'...
$ cd [secure]/open-horizon
$ git checkout -qf a08e00e1dffe8ddf44a1a9e837878a9230a2dfb6
Setting environment variables from repository settings
$ export HZN_EXCHANGE_APIKEY=[secure]
$ export DOCKER_PASSWORD=[secure]
$ export DOCKER_LOGIN=[secure]
$ export DOCKER_NAMESPACE=[secure]
$ export HZN_ORG_ID=[secure]
$ export PRIVATE_KEY=[secure]
$ export PUBLIC_KEY=[secure]
Setting environment variables from .travis.yml
$ export BUILD_ARCH=amd64
$ bash -c 'echo $BASH_VERSION'
4.3.48(1)-release
before_install.1
0.01s$ if [ ${BUILD_ARCH} == 'arm' ] && [ ! -z ${QEMU:-} ]; then sudo apt-get install qemu binfmt-support qemu-user-static -y; fi
before_install.2
0.01s$ if [ ${BUILD_ARCH} == 'arm' ]; then sudo docker run --privileged linuxkit/binfmt:v0.6 && sudo docker run -d --privileged -p 1234:1234 --name buildkit moby/buildkit:latest --addr tcp://0.0.0.0:1234 --oci-worker-platform linux/amd64 --oci-worker-platform linux/armhf && sudo docker cp buildkit:/usr/bin/buildctl /usr/bin/ && export BUILDKIT_HOST=tcp://0.0.0.0:1234; fi
before_script
0.88s$ if [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_LOGIN}" --password-stdin; echo "${HZN_ORG_ID}" > HZN_ORG_ID; echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE; echo "${HZN_EXCHANGE_APIKEY}" > APIKEY; echo "${PRIVATE_KEY}" | base64 --decode > "${HZN_ORG_ID}.key"; echo "${PUBLIC_KEY}" | base64 --decode > "${HZN_ORG_ID}.pem"; if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi; else if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi; fi
WARNING! Your password will be stored unencrypted in /home/travis/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store
Login Succeeded
0.01s$ export BRANCH=$(if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then echo $TRAVIS_BRANCH; else echo $TRAVIS_PULL_REQUEST_BRANCH; fi)
The command "export BRANCH=$(if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then echo $TRAVIS_BRANCH; else echo $TRAVIS_PULL_REQUEST_BRANCH; fi)" exited with 0.
0.00s$ echo "TRAVIS_BRANCH=$TRAVIS_BRANCH, PR=$PR, BRANCH=$BRANCH"
TRAVIS_BRANCH=master, PR=, BRANCH=master
The command "echo "TRAVIS_BRANCH=$TRAVIS_BRANCH, PR=$PR, BRANCH=$BRANCH"" exited with 0.
158.57s$ make build && make test-service
>>> MAKE -- 05:08:21 -- making build in base-alpine base-ubuntu  cpu hal wan yolo  yolo2msghub  
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-alpine'
>>> MAKE -- 05:08:21 -- building: base-alpine; tag: [secure]/amd64_com.github.[secure].open-horizon.base-alpine:0.0.4
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-alpine'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
>>> MAKE -- 05:08:30 -- building: base-ubuntu; tag: [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu:0.0.4
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/cpu'
>>> MAKE -- 05:08:48 -- building: cpu; tag: [secure]/amd64_com.github.[secure].open-horizon.cpu:0.0.3
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/cpu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/hal'
>>> MAKE -- 05:08:51 -- building: hal; tag: [secure]/amd64_com.github.[secure].open-horizon.hal:0.0.3
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/hal'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/wan'
>>> MAKE -- 05:08:54 -- building: wan; tag: [secure]/amd64_com.github.[secure].open-horizon.wan:0.0.3
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/wan'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo'
>>> MAKE -- 05:09:04 -- building: yolo; tag: [secure]/amd64_com.github.[secure].open-horizon.yolo:0.0.8
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
>>> MAKE -- 05:10:03 -- building: yolo2msghub; tag: [secure]/amd64_com.github.[secure].open-horizon.yolo2msghub:0.0.11
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
>>> MAKE -- 05:10:11 -- making test-service in base-alpine base-ubuntu  cpu hal wan yolo  yolo2msghub  
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-alpine'
>>> MAKE -- 05:10:11 -- removing container named: amd64_com.github.[secure].open-horizon.base-alpine
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/base-alpine/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:10:11 -- starting service: base-alpine; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/base-alpine/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/base-alpine/horizon verified.
Start service: service(s) base-alpine with instance id prefix e24da907af3b3379c139ab6c313317b84cab614754a5f2240df095b0928db2f0
Running service.
>>> MAKE -- 05:10:12 -- testing service: base-alpine; version: 0.0.4; arch: amd64
--- INFO -- ./sh/test.sh 14219 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 14219 -- No port specified; assuming port 80
+++ WARN ./sh/test.sh 14219 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 14219 -- Testing base-alpine in container tagged: [secure]/amd64_com.github.[secure].open-horizon.base-alpine:0.0.4 at Sat Apr 6 05:10:12 UTC 2019
{"base-alpine":"","date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":"null","service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 14219 -- test /home/travis/build/[secure]/open-horizon/base-alpine/test-base-alpine.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/base-alpine'
Stop service: service(s) base-alpine with instance id prefix e24da907af3b3379c139ab6c313317b84cab614754a5f2240df095b0928db2f0
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-alpine'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-alpine'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
>>> MAKE -- 05:10:13 -- removing container named: amd64_com.github.[secure].open-horizon.base-ubuntu
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/base-ubuntu/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:10:13 -- starting service: base-ubuntu; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/base-ubuntu/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/base-ubuntu/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/base-ubuntu/horizon verified.
Start service: service(s) base-ubuntu with instance id prefix 584550c06de28195c9e37429e697397872d7c49513215d53163f6a8ce6186171
Running service.
>>> MAKE -- 05:10:14 -- testing service: base-ubuntu; version: 0.0.4; arch: amd64
--- INFO -- ./sh/test.sh 14859 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 14859 -- No port specified; assuming port 80
+++ WARN ./sh/test.sh 14859 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 14859 -- Testing base-ubuntu in container tagged: [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu:0.0.4 at Sat Apr 6 05:10:14 UTC 2019
{"base-ubuntu":"","date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":"null","service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 14859 -- test /home/travis/build/[secure]/open-horizon/base-ubuntu/test-base-ubuntu.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
Stop service: service(s) base-ubuntu with instance id prefix 584550c06de28195c9e37429e697397872d7c49513215d53163f6a8ce6186171
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/cpu'
>>> MAKE -- 05:10:15 -- removing container named: amd64_com.github.[secure].open-horizon.cpu
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/cpu/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:10:15 -- starting service: cpu; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/cpu/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/cpu/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/cpu/horizon verified.
Start service: service(s) cpu with instance id prefix d1fa0c9c402a888bf36e57dcdf5dafd2194374f69965179c22859551a42dd213
Running service.
>>> MAKE -- 05:10:16 -- testing service: cpu; version: 0.0.3; arch: amd64
--- INFO -- ./sh/test.sh 15514 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 15514 -- No port specified; assuming port 80
+++ WARN ./sh/test.sh 15514 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 15514 -- Testing cpu in container tagged: [secure]/amd64_com.github.[secure].open-horizon.cpu:0.0.3 at Sat Apr 6 05:10:16 UTC 2019
{"cpu":{"date":"number"},"date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"log_level":"string","debug":"boolean","period":"string","interval":"string","services":"null"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 15514 -- test /home/travis/build/[secure]/open-horizon/cpu/test-cpu.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/cpu'
Stop service: service(s) cpu with instance id prefix d1fa0c9c402a888bf36e57dcdf5dafd2194374f69965179c22859551a42dd213
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/cpu'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/cpu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/hal'
>>> MAKE -- 05:10:17 -- removing container named: amd64_com.github.[secure].open-horizon.hal
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/hal/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:10:18 -- starting service: hal; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/hal/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/hal/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/hal/horizon verified.
Start service: service(s) hal with instance id prefix a946617c71bd4887a372a5dcaaa90be5eeba19f1b17a447bac5e90dbfba9250e
Running service.
>>> MAKE -- 05:10:18 -- testing service: hal; version: 0.0.3; arch: amd64
--- INFO -- ./sh/test.sh 16223 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 16223 -- No port specified; assuming port 80
+++ WARN ./sh/test.sh 16223 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 16223 -- Testing hal in container tagged: [secure]/amd64_com.github.[secure].open-horizon.hal:0.0.3 at Sat Apr 6 05:10:19 UTC 2019
{"hal":"null","date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"log_level":"string","debug":"boolean","period":"string","services":"null"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 16223 -- test /home/travis/build/[secure]/open-horizon/hal/test-hal.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/hal'
Stop service: service(s) hal with instance id prefix a946617c71bd4887a372a5dcaaa90be5eeba19f1b17a447bac5e90dbfba9250e
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/hal'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/hal'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/wan'
>>> MAKE -- 05:10:20 -- removing container named: amd64_com.github.[secure].open-horizon.wan
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/wan/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:10:20 -- starting service: wan; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/wan/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/wan/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/wan/horizon verified.
Start service: service(s) wan with instance id prefix 44cc3dba6c0e345c25304fa6d356bc12ca96f6099d7d41e68c7d4bef5a6758b4
Running service.
>>> MAKE -- 05:10:21 -- testing service: wan; version: 0.0.3; arch: amd64
--- INFO -- ./sh/test.sh 17294 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 17294 -- No port specified; assuming port 80
+++ WARN ./sh/test.sh 17294 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 17294 -- Testing wan in container tagged: [secure]/amd64_com.github.[secure].open-horizon.wan:0.0.3 at Sat Apr 6 05:10:21 UTC 2019
{"wan":{"date":"number"},"date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"log_level":"string","debug":"boolean","period":"string","services":"null"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 17294 -- test /home/travis/build/[secure]/open-horizon/wan/test-wan.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/wan'
Stop service: service(s) wan with instance id prefix 44cc3dba6c0e345c25304fa6d356bc12ca96f6099d7d41e68c7d4bef5a6758b4
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/wan'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/wan'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo'
>>> MAKE -- 05:10:23 -- removing container named: amd64_com.github.[secure].open-horizon.yolo
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/yolo/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:10:23 -- starting service: yolo; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/yolo/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/yolo/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/yolo/horizon verified.
Start service: service(s) yolo with instance id prefix 45aa450dced8affde2522d701b54ac52d15b40a65b29b185cc48c8003d8e6cdd
Running service.
>>> MAKE -- 05:10:23 -- testing service: yolo; version: 0.0.8; arch: amd64
--- INFO -- ./sh/test.sh 18001 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 18001 -- No port specified; assuming port 80
+++ WARN ./sh/test.sh 18001 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 18001 -- Testing yolo in container tagged: [secure]/amd64_com.github.[secure].open-horizon.yolo:0.0.8 at Sat Apr 6 05:10:24 UTC 2019
{"yolo":"null","date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"log_level":"string","debug":"boolean","date":"number","period":"number","entity":"string","scale":"string","config":"string","device":"string","threshold":"number","services":"null","names":["string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string","string"]},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 18001 -- test /home/travis/build/[secure]/open-horizon/yolo/test-yolo.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo'
Stop service: service(s) yolo with instance id prefix 45aa450dced8affde2522d701b54ac52d15b40a65b29b185cc48c8003d8e6cdd
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
>>> MAKE -- 05:10:25 -- removing container named: amd64_com.github.[secure].open-horizon.yolo2msghub
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/yolo2msghub/horizon. Edit these files to define and configure your new service.
getting container images into docker.
To ensure that the dependency operates correctly, please add variable values to the userinput.json file if this service needs any.
New dependency on url: com.github.[secure].open-horizon.yolo, org: [secure], version: 0.0.8, arch: amd64 created.
getting container images into docker.
To ensure that the dependency operates correctly, please add variable values to the userinput.json file if this service needs any.
New dependency on url: com.github.[secure].open-horizon.wan, org: [secure], version: 0.0.3, arch: amd64 created.
getting container images into docker.
To ensure that the dependency operates correctly, please add variable values to the userinput.json file if this service needs any.
New dependency on url: com.github.[secure].open-horizon.hal, org: [secure], version: 0.0.3, arch: amd64 created.
getting container images into docker.
To ensure that the dependency operates correctly, please add variable values to the userinput.json file if this service needs any.
New dependency on url: com.github.[secure].open-horizon.cpu, org: [secure], version: 0.0.3, arch: amd64 created.
>>> MAKE -- 05:10:45 -- starting service: yolo2msghub; directory: horizon/
Service project /home/travis/build/[secure]/open-horizon/yolo2msghub/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/yolo2msghub/horizon verified.
Service project /home/travis/build/[secure]/open-horizon/yolo2msghub/horizon verified.
Start service: service(s) cpu with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.cpu_0.0.3_6480f564-b6ee-4031-b8da-da87f61c4e91
Running service.
Start service: service(s) hal with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.hal_0.0.3_c4ab30ae-01df-4294-afaf-a34dec80cb32
Running service.
Start service: service(s) wan with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.wan_0.0.3_c2e0a111-358c-40ca-8fad-761dbe2f6602
Running service.
Start service: service(s) yolo with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.yolo_0.0.8_af4eac44-f8eb-473b-990d-bc23f1b42e1f
Running service.
Start service: service(s) yolo2msghub with instance id prefix 07df99bf104bb178b5c454c4b269a1b92c96ab529fc2c4a2ae8c7c1d0445c81b
Running service.
>>> MAKE -- 05:10:53 -- testing service: yolo2msghub; version: 0.0.11; arch: amd64
--- INFO -- ./sh/test.sh 20639 -- No host specified; assuming 127.0.0.1
+++ WARN ./sh/test.sh 20639 -- No port specified; assuming port 8587
+++ WARN ./sh/test.sh 20639 -- No protocol specified; assuming http
--- INFO -- ./sh/test.sh 20639 -- Testing yolo2msghub in container tagged: [secure]/amd64_com.github.[secure].open-horizon.yolo2msghub:0.0.11 at Sat Apr 6 05:10:53 UTC 2019
{"wan":{"date":"number"},"cpu":{"date":"number","percent":"number"},"hal":{"date":"number","lshw":{"id":"string","class":"string","claimed":"boolean","handle":"string","description":"string","product":"string","vendor":"string","serial":"string","width":"number","configuration":{"boot":"string","uuid":"string"},"capabilities":{"4":"","vsyscall32":"string"},"children":["object","object"]},"lsusb":[],"lscpu":{"Architecture":"string","CPU_op_modes":"string","Byte_Order":"string","CPUs":"string","On_line_CPUs_list":"string","Threads_per_core":"string","Cores_per_socket":"string","Sockets":"string","NUMA_nodes":"string","Vendor_ID":"string","CPU_family":"string","Model":"string","Model_name":"string","Stepping":"string","CPU_MHz":"string","BogoMIPS":"string","Hypervisor_vendor":"string","Virtualization_type":"string","L1d_cache":"string","L1i_cache":"string","L2_cache":"string","L3_cache":"string","NUMA_node0_CPUs":"string","Flags":"string"},"lspci":["object","object","object","object","object"],"lsblk":["object"],"lsdf":["object"]},"yolo2msghub":{"date":"number"},"date":"number","hzn":{"agreementid":"string","arch":"string","cpus":"number","device_id":"string","exchange_url":"string","host_ips":["string","string","string","string","string","string","string"],"organization":"string","ram":"number","pattern":"null"},"config":{"date":"number","log_level":"string","debug":"boolean","services":["object","object","object"],"period":"number"},"service":{"label":"string","version":"string"}}
!!! SUCCESS -- ./sh/test.sh 20639 -- test /home/travis/build/[secure]/open-horizon/yolo2msghub/test-yolo2msghub.sh returned true
make[2]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
Stop service: service(s) yolo2msghub with instance id prefix 07df99bf104bb178b5c454c4b269a1b92c96ab529fc2c4a2ae8c7c1d0445c81b
Stop service: service(s) cpu with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.cpu_0.0.3_6480f564-b6ee-4031-b8da-da87f61c4e91
Stop service: service(s) hal with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.hal_0.0.3_c4ab30ae-01df-4294-afaf-a34dec80cb32
Stop service: service(s) wan with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.wan_0.0.3_c2e0a111-358c-40ca-8fad-761dbe2f6602
Stop service: service(s) yolo with instance id prefix [secure]-us.ibm.com_com.github.[secure].open-horizon.yolo_0.0.8_af4eac44-f8eb-473b-990d-bc23f1b42e1f
Stopped service.
make[2]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
The command "make build && make test-service" exited with 0.
after_success.1
150.24s$ make push
>>> MAKE -- 05:10:59 -- making push in base-alpine base-ubuntu  cpu hal wan yolo  yolo2msghub  
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-alpine'
>>> MAKE -- 05:10:59 -- building: base-alpine; tag: [secure]/amd64_com.github.[secure].open-horizon.base-alpine:0.0.4
>>> MAKE -- 05:11:00 -- login to docker.io
>>> MAKE -- 05:11:00 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.base-alpine:0.0.4
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.base-alpine]
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
Login Succeeded
d9ff549177a9: Layer already exists
604cf54d304c: Pushed
9210fbaca255: Pushed
0.0.4: digest: sha256:61a1f92a196a54808c538f44c2a592c02a6d4b1553fc6e2e0bdb4e2f9c60fab9 size: 947
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-alpine'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
>>> MAKE -- 05:11:05 -- building: base-ubuntu; tag: [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu:0.0.4
>>> MAKE -- 05:11:06 -- login to docker.io
>>> MAKE -- 05:11:06 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu:0.0.4
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.base-ubuntu]
604cf54d304c: Preparing
d42e17dc6e7d: Preparing
b57c79f4a9f3: Preparing
d60e01b37e74: Preparing
e45cfbc98a50: Preparing
762d8e1a6054: Preparing
762d8e1a6054: Waiting
Login Succeeded
b57c79f4a9f3: Layer already exists
e45cfbc98a50: Layer already exists
d60e01b37e74: Layer already exists
762d8e1a6054: Layer already exists
604cf54d304c: Mounted from [secure]/amd64_com.github.[secure].open-horizon.base-alpine
d42e17dc6e7d: Pushed
0.0.4: digest: sha256:8cac1f2e6d1211fc283636c5d01dc419961d8d5a9c63ab9813dcff8a7a45f92b size: 1570
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/cpu'
>>> MAKE -- 05:11:13 -- building: cpu; tag: [secure]/amd64_com.github.[secure].open-horizon.cpu:0.0.3
>>> MAKE -- 05:11:16 -- login to docker.io
>>> MAKE -- 05:11:16 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.cpu:0.0.3
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.cpu]
51df535231d9: Preparing
a695f69e5137: Preparing
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
Login Succeeded
d9ff549177a9: Layer already exists
604cf54d304c: Mounted from [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu
9210fbaca255: Mounted from [secure]/amd64_com.github.[secure].open-horizon.base-alpine
a695f69e5137: Pushed
51df535231d9: Pushed
0.0.3: digest: sha256:449849d71f2f7d7b560938a8bf6bce4a9196ffdab9f47658453cde0008978b9f size: 1363
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/cpu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/hal'
>>> MAKE -- 05:11:22 -- building: hal; tag: [secure]/amd64_com.github.[secure].open-horizon.hal:0.0.3
>>> MAKE -- 05:11:25 -- login to docker.io
>>> MAKE -- 05:11:25 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.hal:0.0.3
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.hal]
4a21bf8b2a84: Preparing
55f4c56ba889: Preparing
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
Login Succeeded
d9ff549177a9: Layer already exists
9210fbaca255: Mounted from [secure]/amd64_com.github.[secure].open-horizon.cpu
604cf54d304c: Mounted from [secure]/amd64_com.github.[secure].open-horizon.cpu
4a21bf8b2a84: Pushed
55f4c56ba889: Pushed
0.0.3: digest: sha256:296696ed8ee352f7a885518d801a68ccdb1f9e3fa58d667a5fec414f37895490 size: 1366
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/hal'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/wan'
>>> MAKE -- 05:11:32 -- building: wan; tag: [secure]/amd64_com.github.[secure].open-horizon.wan:0.0.3
>>> MAKE -- 05:11:42 -- login to docker.io
>>> MAKE -- 05:11:42 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.wan:0.0.3
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.wan]
566f2d7cec32: Preparing
77119602d966: Preparing
3410dc0d1988: Preparing
4248badb9d8d: Preparing
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
9210fbaca255: Waiting
d9ff549177a9: Waiting
Login Succeeded
604cf54d304c: Mounted from [secure]/amd64_com.github.[secure].open-horizon.hal
77119602d966: Pushed
9210fbaca255: Mounted from [secure]/amd64_com.github.[secure].open-horizon.hal
566f2d7cec32: Pushed
d9ff549177a9: Layer already exists
3410dc0d1988: Pushed
4248badb9d8d: Pushed
0.0.3: digest: sha256:c6ab2f65d99f8bbe870262375df8329cdceac8e2659bedb6f04106d80983e759 size: 1786
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/wan'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo'
>>> MAKE -- 05:11:50 -- building: yolo; tag: [secure]/amd64_com.github.[secure].open-horizon.yolo:0.0.8
>>> MAKE -- 05:12:49 -- login to docker.io
>>> MAKE -- 05:12:49 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.yolo:0.0.8
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.yolo]
f086e2cfb46d: Preparing
40e170e24d88: Preparing
a62f53efb9f0: Preparing
ec44630464d1: Preparing
d69f81f8da2f: Preparing
79644be16167: Preparing
604cf54d304c: Preparing
d42e17dc6e7d: Preparing
b57c79f4a9f3: Preparing
d60e01b37e74: Preparing
e45cfbc98a50: Preparing
762d8e1a6054: Preparing
79644be16167: Waiting
604cf54d304c: Waiting
d42e17dc6e7d: Waiting
b57c79f4a9f3: Waiting
d60e01b37e74: Waiting
e45cfbc98a50: Waiting
762d8e1a6054: Waiting
Login Succeeded
f086e2cfb46d: Pushed
d69f81f8da2f: Pushed
a62f53efb9f0: Pushed
604cf54d304c: Mounted from [secure]/amd64_com.github.[secure].open-horizon.wan
d42e17dc6e7d: Mounted from [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu
b57c79f4a9f3: Layer already exists
40e170e24d88: Pushed
d60e01b37e74: Layer already exists
e45cfbc98a50: Layer already exists
762d8e1a6054: Layer already exists
ec44630464d1: Pushed
79644be16167: Pushed
0.0.8: digest: sha256:d2291ed908490ad0cca92b51f2daa2887c62d86d4b8c9f1e2cb4da0fb0a3385b size: 2833
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
>>> MAKE -- 05:13:15 -- building: yolo2msghub; tag: [secure]/amd64_com.github.[secure].open-horizon.yolo2msghub:0.0.11
>>> MAKE -- 05:13:24 -- login to docker.io
>>> MAKE -- 05:13:24 -- pushing container: [secure]/amd64_com.github.[secure].open-horizon.yolo2msghub:0.0.11
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.yolo2msghub]
676312543e10: Preparing
3ea10ae0dbe5: Preparing
604cf54d304c: Preparing
d42e17dc6e7d: Preparing
b57c79f4a9f3: Preparing
d60e01b37e74: Preparing
e45cfbc98a50: Preparing
762d8e1a6054: Preparing
d60e01b37e74: Waiting
e45cfbc98a50: Waiting
762d8e1a6054: Waiting
Login Succeeded
b57c79f4a9f3: Layer already exists
d60e01b37e74: Layer already exists
604cf54d304c: Mounted from [secure]/amd64_com.github.[secure].open-horizon.yolo
d42e17dc6e7d: Mounted from [secure]/amd64_com.github.[secure].open-horizon.yolo
e45cfbc98a50: Layer already exists
762d8e1a6054: Layer already exists
676312543e10: Pushed
3ea10ae0dbe5: Pushed
0.0.11: digest: sha256:846f5c8a7c563c75111ca268171afe32a568af7cd1a056e02c99b35ffe6a7d94 size: 1989
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
after_success.2
12.88s$ make publish-service
>>> MAKE -- 05:13:29 -- making publish-service in base-alpine base-ubuntu  cpu hal wan yolo  yolo2msghub  
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-alpine'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/base-alpine/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:30 -- publishing service: base-alpine; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.base-alpine:0.0.4...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.base-alpine]
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
604cf54d304c: Layer already exists
d9ff549177a9: Layer already exists
9210fbaca255: Layer already exists
0.0.4: digest: sha256:61a1f92a196a54808c538f44c2a592c02a6d4b1553fc6e2e0bdb4e2f9c60fab9 size: 947
Using '[secure]/amd64_com.github.[secure].open-horizon.base-alpine@sha256:61a1f92a196a54808c538f44c2a592c02a6d4b1553fc6e2e0bdb4e2f9c60fab9' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.base-alpine:0.0.4'
Updating com.github.[secure].open-horizon.base-alpine_0.0.4_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-alpine'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/base-ubuntu/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:31 -- publishing service: base-ubuntu; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.base-ubuntu:0.0.4...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.base-ubuntu]
604cf54d304c: Preparing
d42e17dc6e7d: Preparing
b57c79f4a9f3: Preparing
d60e01b37e74: Preparing
e45cfbc98a50: Preparing
762d8e1a6054: Preparing
762d8e1a6054: Waiting
e45cfbc98a50: Layer already exists
b57c79f4a9f3: Layer already exists
d60e01b37e74: Layer already exists
604cf54d304c: Layer already exists
d42e17dc6e7d: Layer already exists
762d8e1a6054: Layer already exists
0.0.4: digest: sha256:8cac1f2e6d1211fc283636c5d01dc419961d8d5a9c63ab9813dcff8a7a45f92b size: 1570
Using '[secure]/amd64_com.github.[secure].open-horizon.base-ubuntu@sha256:8cac1f2e6d1211fc283636c5d01dc419961d8d5a9c63ab9813dcff8a7a45f92b' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.base-ubuntu:0.0.4'
Updating com.github.[secure].open-horizon.base-ubuntu_0.0.4_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/base-ubuntu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/cpu'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/cpu/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:33 -- publishing service: cpu; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.cpu:0.0.3...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.cpu]
51df535231d9: Preparing
a695f69e5137: Preparing
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
9210fbaca255: Layer already exists
51df535231d9: Layer already exists
604cf54d304c: Layer already exists
a695f69e5137: Layer already exists
d9ff549177a9: Layer already exists
0.0.3: digest: sha256:449849d71f2f7d7b560938a8bf6bce4a9196ffdab9f47658453cde0008978b9f size: 1363
Using '[secure]/amd64_com.github.[secure].open-horizon.cpu@sha256:449849d71f2f7d7b560938a8bf6bce4a9196ffdab9f47658453cde0008978b9f' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.cpu:0.0.3'
Updating com.github.[secure].open-horizon.cpu_0.0.3_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/cpu'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/hal'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/hal/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:35 -- publishing service: hal; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.hal:0.0.3...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.hal]
4a21bf8b2a84: Preparing
55f4c56ba889: Preparing
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
4a21bf8b2a84: Layer already exists
9210fbaca255: Layer already exists
55f4c56ba889: Layer already exists
604cf54d304c: Layer already exists
d9ff549177a9: Layer already exists
0.0.3: digest: sha256:296696ed8ee352f7a885518d801a68ccdb1f9e3fa58d667a5fec414f37895490 size: 1366
Using '[secure]/amd64_com.github.[secure].open-horizon.hal@sha256:296696ed8ee352f7a885518d801a68ccdb1f9e3fa58d667a5fec414f37895490' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.hal:0.0.3'
Updating com.github.[secure].open-horizon.hal_0.0.3_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/hal'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/wan'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/wan/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:36 -- publishing service: wan; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.wan:0.0.3...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.wan]
566f2d7cec32: Preparing
77119602d966: Preparing
3410dc0d1988: Preparing
4248badb9d8d: Preparing
604cf54d304c: Preparing
9210fbaca255: Preparing
d9ff549177a9: Preparing
9210fbaca255: Waiting
d9ff549177a9: Waiting
566f2d7cec32: Layer already exists
77119602d966: Layer already exists
4248badb9d8d: Layer already exists
3410dc0d1988: Layer already exists
604cf54d304c: Layer already exists
9210fbaca255: Layer already exists
d9ff549177a9: Layer already exists
0.0.3: digest: sha256:c6ab2f65d99f8bbe870262375df8329cdceac8e2659bedb6f04106d80983e759 size: 1786
Using '[secure]/amd64_com.github.[secure].open-horizon.wan@sha256:c6ab2f65d99f8bbe870262375df8329cdceac8e2659bedb6f04106d80983e759' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.wan:0.0.3'
Updating com.github.[secure].open-horizon.wan_0.0.3_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/wan'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/yolo/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:38 -- publishing service: yolo; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.yolo:0.0.8...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.yolo]
f086e2cfb46d: Preparing
40e170e24d88: Preparing
a62f53efb9f0: Preparing
ec44630464d1: Preparing
d69f81f8da2f: Preparing
79644be16167: Preparing
604cf54d304c: Preparing
d42e17dc6e7d: Preparing
b57c79f4a9f3: Preparing
d60e01b37e74: Preparing
e45cfbc98a50: Preparing
762d8e1a6054: Preparing
79644be16167: Waiting
604cf54d304c: Waiting
d42e17dc6e7d: Waiting
b57c79f4a9f3: Waiting
d60e01b37e74: Waiting
e45cfbc98a50: Waiting
762d8e1a6054: Waiting
f086e2cfb46d: Layer already exists
a62f53efb9f0: Layer already exists
d69f81f8da2f: Layer already exists
40e170e24d88: Layer already exists
ec44630464d1: Layer already exists
79644be16167: Layer already exists
b57c79f4a9f3: Layer already exists
604cf54d304c: Layer already exists
d42e17dc6e7d: Layer already exists
d60e01b37e74: Layer already exists
762d8e1a6054: Layer already exists
e45cfbc98a50: Layer already exists
0.0.8: digest: sha256:d2291ed908490ad0cca92b51f2daa2887c62d86d4b8c9f1e2cb4da0fb0a3385b size: 2833
Using '[secure]/amd64_com.github.[secure].open-horizon.yolo@sha256:d2291ed908490ad0cca92b51f2daa2887c62d86d4b8c9f1e2cb4da0fb0a3385b' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.yolo:0.0.8'
Updating com.github.[secure].open-horizon.yolo_0.0.8_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo'
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
Created horizon metadata files in /home/travis/build/[secure]/open-horizon/yolo2msghub/horizon. Edit these files to define and configure your new service.
>>> MAKE -- 05:13:41 -- publishing service: yolo2msghub; architecture: amd64
Signing service...
Pushing [secure]/amd64_com.github.[secure].open-horizon.yolo2msghub:0.0.11...
The push refers to repository [docker.io/[secure]/amd64_com.github.[secure].open-horizon.yolo2msghub]
676312543e10: Preparing
3ea10ae0dbe5: Preparing
604cf54d304c: Preparing
d42e17dc6e7d: Preparing
b57c79f4a9f3: Preparing
d60e01b37e74: Preparing
e45cfbc98a50: Preparing
762d8e1a6054: Preparing
d60e01b37e74: Waiting
e45cfbc98a50: Waiting
762d8e1a6054: Waiting
d42e17dc6e7d: Layer already exists
3ea10ae0dbe5: Layer already exists
676312543e10: Layer already exists
b57c79f4a9f3: Layer already exists
604cf54d304c: Layer already exists
d60e01b37e74: Layer already exists
762d8e1a6054: Layer already exists
e45cfbc98a50: Layer already exists
0.0.11: digest: sha256:846f5c8a7c563c75111ca268171afe32a568af7cd1a056e02c99b35ffe6a7d94 size: 1989
Using '[secure]/amd64_com.github.[secure].open-horizon.yolo2msghub@sha256:846f5c8a7c563c75111ca268171afe32a568af7cd1a056e02c99b35ffe6a7d94' in 'deployment' field instead of '[secure]/amd64_com.github.[secure].open-horizon.yolo2msghub:0.0.11'
Updating com.github.[secure].open-horizon.yolo2msghub_0.0.11_amd64 in the exchange...
Storing [secure].pem with the service in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
after_success.3
0.41s$ make pattern-publish
>>> MAKE -- 05:13:42 -- publishing yolo2msghub 
make[1]: Entering directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
>>> MAKE -- 05:13:42 -- publishing: yolo2msghub; organization: [secure]; exchange: https://alpha.edge-fabric.com/v1
Updating yolo2msghub in the exchange...
Storing [secure].pem with the pattern in the exchange...
make[1]: Leaving directory '/home/travis/build/[secure]/open-horizon/yolo2msghub'
Done. Your build exited with 0.
```


# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md


[amd64-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-amd64.svg
[amd64-microbadger]: https://microbadger.com/images/dcmartin/plex-amd64
[armhf-microbadger]: https://microbadger.com/images/dcmartin/plex-armhf
[armhf-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-armhf.svg

[amd64-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-amd64.svg
[amd64-arch-shield]: https://img.shields.io/badge/architecture-amd64-blue.svg
[amd64-dockerhub]: https://hub.docker.com/r/dcmartin/plex-amd64
[amd64-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-amd64.svg
[armhf-arch-shield]: https://img.shields.io/badge/architecture-armhf-blue.svg
[armhf-dockerhub]: https://hub.docker.com/r/dcmartin/plex-armhf
[armhf-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-armhf.svg
[armhf-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-armhf.svg
[i386-arch-shield]: https://img.shields.io/badge/architecture-i386-blue.svg
[i386-dockerhub]: https://hub.docker.com/r/dcmartin/plex-i386
[i386-layers-shield]: https://images.microbadger.com/badges/image/dcmartin/plex-i386.svg
[i386-microbadger]: https://microbadger.com/images/dcmartin/plex-i386
[i386-pulls-shield]: https://img.shields.io/docker/pulls/dcmartin/plex-i386.svg
[i386-version-shield]: https://images.microbadger.com/badges/version/dcmartin/plex-i386.svg
