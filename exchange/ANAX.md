# `ANAX.md` - setting up Open Horizon agent


## Step 1 - Add `bluehorizon` repository

```
wget -qO - http://pkg.bluehorizon.network/bluehorizon.network-public.key | apt-key add -
cat << EOF > /etc/apt/sources.list.d/bluehorizon.list
deb [arch=$(dpkg --print-architecture)] http://pkg.bluehorizon.network/linux/ubuntu xenial-testing main
deb-src [arch=$(dpkg --print-architecture)] http://pkg.bluehorizon.network/linux/ubuntu xenial-testing main
EOF
```

## Step 2 - Update, upgrade, and install:

```
apt update -qq -y
apt upgrade -qq -y
apt install -qq -y bluehorizon
```

## Step 3 - Configure _exchange_

```
export HZN_EXCHANGE_URL=http://exchange:3090/v1/
export HZN_FSS_CSSURL=http://exchange:9443/css/
sudo sed -i -e "s/^HZN_EXCHANGE_URL=.*/HZN_EXCHANGE_URL=${HZN_EXCHANGE_URL}" /etc/default/horizon
sudo sed -i -e "s/^HZN_FSS_CSSURL=.*/HZN_FSS_CSSURL=${HZN_FSS_CSSURL}/" /etc/default/horizon
sudo systemctl restart horizon
```

## Step 4 - Test

```
export HZN_ORG_ID=${USER}
export HZN_USER_ID=${USER}
export HZN_EXCHANGE_APIKEY="whocares"
export HZN_EXCHANGE_USER_AUTH=${HZN_ORG_ID}/${HZN_USER_ID}:${HZN_EXCHANGE_APIKEY}
hzn node list
```
