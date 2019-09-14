#!/bin/bash

if [ -z "$(command -v docker)" ]; then
  wget get.docker.com | sudo bash -s
  sudo addgroup $(whoami) docker
fi
if [ -z "$(command -v docker-compose)" ]; then
  sudo apt install -qq -y docker-compose
fi
if [ ! -s docker-compose.yml ]; then
  rm -f docker-compose.yml
  if [ ! -s docker-compose-redis-edinburgh-no-secty-1.0.0.yml ]; then
    wget https://raw.githubusercontent.com/edgexfoundry/developer-scripts/master/releases/edinburgh/compose-files/docker-compose-redis-edinburgh-no-secty-1.0.1.yml
  fi
  ln -s docker-compose-redis-edinburgh-no-secty-1.0.1.yml docker-compose.yml
fi

# get the images
if [ $(docker-compose pull &> /dev/stderr && echo true || echo false) = true ]; then
  # start the containers
  if [ $(docker-compose up -d &> /dev/stderr && echo true || echo false) = true ]; then
    # show the containers
    docker-compose ps
    # show the configuration
    docker-compose config --services
    # check all the services
    machine="localhost"
    ports="48060 48061 48070 48071 48075 48080 48081 48082 48085 49990"
    for port in ${ports}; do pong=$(curl -sSL http://${machine}:${port}/api/v1/ping) && echo "port: $port; reply: ${pong}"; done
    # stop the containers
    docker-compose stop
    # all done
    docker-compose down
  else
    echo "Failed to start"
  fi
else
  echo "Failed to pull"
fi
