#!/bin/bash
set -o errexit

docker run --rm --privileged multiarch/qemu-user-static:register --reset
