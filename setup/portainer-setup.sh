#!/bin/bash
if [[ -z $(command -v docker) ]]; then
  echo "Please install docker; curl -fsSL get.docker.com | bash"
fi
docker volume create portainer_data
docker run --restart always -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
