#!/bin/bash

## reset exchange database
exchange_db_reset()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local result=

  if [ -z "${password}" ] || [ -z "${url}" ]; then
    echo "${FUNCNAME[0]}: invalid arguments"
  else
    result=$(curl -sLX POST --header "Authorization:Basic ${account}:${password}" "${url}/admin/upgradedb" | jq -r '.msg')
    while true; do
      result=$(curl -sLX GET --header "Authorization:Basic ${account}:${password}" "${url}/admin/dropdb/token" | jq -r '.token')
      if [ -z "${result}" ]; then
	sleep 5
      else
	break
      fi
    done
    if [ -z "${result}" ]; then
      echo "${FUNCNAME[0]}: no dropdb token"
    else
      echo "${FUNCNAME[0]}: dropdb: ${result}"
    fi
    result=$(curl -sLX POST --header "Authorization:Basic ${account}:${password}" "${url}/admin/initdb" | jq -r '.msg')
    if [ -z "${result}" ]; then
      echo "${FUNCNAME[0]}: no response from initdb"
    else
      echo "${FUNCNAME[0]}: initializedb: ${result}"
    fi
  fi
  echo "${result:-false}"
}

exchange_create_org()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local type=${5:-}
  local result

  result=$(curl -sLX POST --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"label":"'${org}'","description":"","orgType":"'${type}'"}' "${url}/orgs/${org}" | jq -r '.msg')
  if [ -z "${result}" ]; then
    echo "${FUNCNAME[0]}: no response to creating org: ${org:-null}; type: ${type:-null}" &> /dev/stderr
  else
    echo "${FUNCNAME[0]}: creating org: ${org:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
  fi
  echo "${result:-false}"
}

exchange_delete_org()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local type=${5:-}
  local result

  result=$(curl -sLX DELETE --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"label":"'${org}'","description":"","orgType":"'${type}'"}' "${url}/orgs/${org}" | jq -r '.msg')
  if [ -z "${result}" ]; then
    echo "${FUNCNAME[0]}: no response to deleting org: ${org:-null}; type: ${type:-null}" &> /dev/stderr
  else
    echo "${FUNCNAME[0]}: deleting org: ${org:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
  fi
  echo "${result:-false}"
}

exchange_create_user()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local user=${5:-}
  local admin=${6:-false}
  local token=${7:-}
  local email=${8:-${user}@${org}}
  local result

  if [ -z "${account}" ] || [ -z "${password}" ] || [ -z "${url}" ] || [ -z "${org}" ] || [ -z "${user}" ]; then
    echo "${FUNCNAME[0]}: invalid arguments"
  else
    result=$(curl -sLX POST --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"password":"'${token}'","email":"'${email}'","admin":'${admin}'}' "${url}/orgs/${org}/users/${user}" | jq -r '.msg')
    if [ -z "${result}" ]; then
      echo "${FUNCNAME[0]}: no response to creating user: ${user:-null} in org: ${org:-null}" &> /dev/stderr
    else
      echo "${FUNCNAME[0]}: creating user: ${user:-null} in org: ${org:-null}; token: ${token:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
    fi
  fi
  echo "${result:-false}"
}

exchange_delete_user()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local user=${5:-}
  local admin=${6:-false}
  local token=${7:-}
  local email=${8:-}
  local result

  if [ -z "${account}" ] || [ -z "${password}" ] || [ -z "${url}" ] || [ -z "${org}" ] || [ -z "${user}" ]; then
    echo "${FUNCNAME[0]}: invalid arguments"
  else
    result=$(curl -sLX DELETE --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"password":"'${token}'","email":"'${email}'","admin":'${admin}'}' "${url}/orgs/${org}/users/${user}" | jq -r '.msg')
    if [ -z "${result}" ]; then
      echo "${FUNCNAME[0]}: no response to deleting user: ${user:-null} from org: ${org:-null}" &> /dev/stderr
    else
      echo "${FUNCNAME[0]}: deleting org: ${org:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
    fi
  fi
  echo "${result:-false}"
}

exchange_register_agbot()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local token=${5:-}
  local name=${6:-}
  local msgEndPoint=${7:-}
  local publicKey=${8:-}
  local result

  result=$(curl -sLX PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"token":"'${token}'","name":"'${name}'","msgEndPoint":"'${msgEndPoint}'","publicKey":"'${publicKey}'"}' "${url}/orgs/${org}/agbots/${name}" | jq -r '.msg')

  if [ -z "${result}" ]; then
    echo "${FUNCNAME[0]}: no response to registering agbot: ${name:-null}; type: ${type:-null}" &> /dev/stderr
  else
    echo "${FUNCNAME[0]}: registering agbot: ${name:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
  fi
  echo "${result:-false}"
}

exchange_register_allpattern()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local name=${5:-}
  local result

  result=$(curl -sLX POST --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"patternOrgid":"'${org}'","pattern":"*", "nodeOrgid": "'${org}'"}' "${url}/orgs/${org}/agbots/${name}/patterns" | jq -r '.msg')
  if [ -z "${result}" ]; then
    echo "${FUNCNAME[0]}: no response to registering agbot: ${name:-null}; type: ${type:-null}" &> /dev/stderr
  else
    echo "${FUNCNAME[0]}: registering agbot: ${name:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
  fi
  echo "${result:-false}"
}

exchange_register_allpolicy()
{
  local account=${1:-root/root} 
  local password=${2:-}
  local url=${3:-}
  local org=${4:-}
  local name=${5:-}
  local result

  result=$(curl -sLX POST --header 'Content-Type: application/json' --header 'Accept: application/json' -H "Authorization:Basic ${account}:${password}" -d '{"businessPolOrgid":"'${org}'","businessPol":"*", "nodeOrgid": "'${org}'"}' "${url}/orgs/${org}/agbots/${name}/businesspols" | jq -r '.msg')
  if [ -z "${result}" ]; then
    echo "${FUNCNAME[0]}: no response to registering agbot: ${name:-null}; type: ${type:-null}" &> /dev/stderr
  else
    echo "${FUNCNAME[0]}: registering agbot: ${name:-null}; type: ${type:-null}; result: ${result}" &> /dev/stderr
  fi
  echo "${result:-false}"
}

###
### MAIN
###

## EXCHANGE
ORG=${EXCHANGE_ORGANIZATION:-}
URL=${EXCHANGE_URL:-}
ROOT=${EXCHANGE_ROOT:-}
PASSWORD=${EXCHANGE_PASSWORD:-}

## test environment
if [ -z "${ORG:-}" ] || [ -z "${URL}" ] || [ -z "${ROOT}" ] || [ -z "${PASSWORD}" ]; then
  echo "Invalid environment; specified required variables"
  exit 1
fi

## USERS
ADMIN_USER=${EXCHANGE_ADMIN_USERNAME:-null}
ADMIN_PASSWORD=${EXCHANGE_ADMIN_PASSWORD:-null}
ADMIN_EMAIL=${EXCHANGE_ADMIN_EMAIL:-null}

## AGBOT
AGBOT_NAME=${EXCHANGE_AGBOT_NAME:-null}
AGBOT_TOKEN=${EXCHANGE_AGBOT_TOKEN:-null}

## EXCHANGEDB
if [ "${EXCHANGE_DB_RESET:-false}" = 'true' ]; then
  echo "Reseting database" &> /dev/stderr
  exchange_db_reset "${ROOT}" "${PASSWORD}" "${URL}"
else
  echo "Deleting existing organization: ${ORG:-null}; user: ${ADMIN_USER:-null}" &> /dev/stderr
  exchange_delete_org "${ROOT}" ${PASSWORD} ${URL} "${ORG}"
  exchange_delete_user "${ROOT}" ${PASSWORD} ${URL} "${ORG}" "${ADMIN_USER}" true "${ADMIN_PASSWORD}" "${ADMIN_EMAIL}"
fi

## ORG
result=$(exchange_create_org ${ROOT} ${PASSWORD} ${URL} ${ORG})
if [ "${result:-}"  = 'false' ]; then
  echo "Failed to create organization: ${ORG:-null}; url: ${URL:-null}" &> /dev/stderr
  exit 1
fi

## create administrative user
result=$(exchange_create_user ${ROOT} ${PASSWORD} ${URL} ${ORG} ${ADMIN_USER} true ${ADMIN_PASSWORD})
if [ "${result:-}"  = 'false' ]; then
  echo "Failed to create user: ${ADMIN_USER:-null}; admin: true; password: ${ADMIN_PASSWORD:-null}" &> /dev/stderr
  exit 1
fi

## AGBOT
result=$(exchange_register_agbot ${ORG}/${ADMIN_USER} ${ADMIN_PASSWORD} ${URL} ${ORG} ${AGBOT_TOKEN} ${AGBOT_NAME})
if [ "${result:-}"  = 'false' ]; then
  echo "Failed to register agbot: ${AGBOT_NAME:-null}; org: ${ORG:-null}; user: ${ADMIN_USER:-null}; url: ${URL:-null}"
  exit 1
fi

result=$(exchange_register_allpattern ${ORG}/${ADMIN_USER} ${ADMIN_PASSWORD} ${URL} ${ORG} ${AGBOT_NAME})
if [ "${result:-}"  = 'false' ]; then
  echo "Failed to register all patterns for url: ${URL:-null}; org: ${ORG:-null}; user: ${ADMIN_USER:-null}; password: ${ADMIN_PASSWORD:-null}" &> /dev/stderr
  exit 1
fi
result=$(exchange_register_allpolicy ${ORG}/${ADMIN_USER} ${ADMIN_PASSWORD} ${URL} ${ORG} ${AGBOT_NAME})
if [ "${result:-}"  = 'false' ]; then
  echo "Failed to register all policies for url: ${URL:-null}; org: ${ORG:-null}; user: ${ADMIN_USER:-null}; password: ${ADMIN_PASSWORD:-null}" &> /dev/stderr
  exit 1
fi


