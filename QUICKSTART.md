# QUICKSTART.md

## Step 1 - clone & setup
touch ~/.rnd
echo "${USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_${USER}-nopasswd
sudo apt install -qq -y git 
git clone http://github.com/dcmartin/open-horizon

## Step 2 - update & install
sudo apt update -qq -y
sudo apt upgrade -qq -y
sudo apt install -qq -y build-essential net-tools jq curl apache2-utils gnupg2 pass docker-compose
sudo addgroup dcmartin docker
sudo reboot

## Step 3 - create exchange
cd open-horizon
make exchange

## Step 4 - install horizon
sudo ./sh/get.horizon.sh

## Step 5 - build, push, and publish services
make services

## Step 6 - run `hznmonitor` service
cd services/hznmonitor
make
