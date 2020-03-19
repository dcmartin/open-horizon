#!/bin/bash
docker stop portainer
docker rm portainer
docker volume create portainer_data
docker run -d -p "0.0.0.0:9000:9000" -p 8000:8000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
