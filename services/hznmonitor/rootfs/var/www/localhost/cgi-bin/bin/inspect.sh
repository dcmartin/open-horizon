#!/bin/bash

if [ -z "${HZNMONITOR_EXCHANGE_URL:-}" ]; then HZNMONITOR_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"; fi

lsnodes()
{
  curl -fsSL -u "${HZNMONITOR_EXCHANGE_ORG}/${HZNMONITOR_EXCHANGE_USER:-iamapikey}:${HZNMONITOR_EXCHANGE_APIKEY}" "${HZNMONITOR_EXCHANGE_URL%/}/orgs/${HZNMONITOR_EXCHANGE_ORG}/nodes" \
    | jq '{"nodes":[.nodes|to_entries[]|.value.id=.key|.value]|sort_by(.lastHeartbeat)|reverse}'
}

nodestatus()
{
  ID="${1}"
  curl -sL -u "${HZNMONITOR_EXCHANGE_ORG}/${HZNMONITOR_EXCHANGE_USER:-iamapikey}:${HZNMONITOR_EXCHANGE_APIKEY}" "${HZNMONITOR_EXCHANGE_URL%/}/orgs/${HZNMONITOR_EXCHANGE_ORG}/nodes/${ID}/status" \
    | jq '.={"status":.}' | jq '.name="'${1}'"|.org="'${HZNMONITOR_EXCHANGE_ORG}'"|.user="'${HZNMONITOR_EXCHANGE_USER}'"|.url="'${HZNMONITOR_EXCHANGE_URL}'"'
}

mkinspect()
{
  output='<html><head></head><body>'
  if [ ! -z "${1:-}" ]; then
    name="${1}"
    n=$(lsnodes | jq '.nodes[]|select(.name=="'${name}'")')
    if [ "${n:-null}" != 'null' ]; then
      output="${output}"'<h1>Name: <code>'$(echo "${n}" | jq -r '.name')'</code></h1>'
      output="${output}"'<h2>Owner: <code>'$(echo "${n}" | jq -r '.owner')'</code></h1>'
      output="${output}"'<h2>Last Heartbeat: <code>'$(echo "${n}" | jq -r '.lastHeartbeat')'</code></h2>'
      output="${output}"'<h2>Pattern: <code>'$(echo "${n}" | jq -r '.pattern')'</code></h2>'
      output="${output}"'<h2>Status</h2>'
      ns=$(nodestatus "${name}")
      if [ "${ns:-null}" != 'null' ]; then
	output="${output}"'<h3>Organization: <code>'$(echo "${ns}" | jq -r '.org')'</code></h3>'
	output="${output}"'<h3>Exchange: <code>'$(echo "${ns}" | jq -r '.url')'</code></h3>'
	output="${output}"'<h3>Last Updated: <code>'$(echo "${ns}" | jq -r '.status.lastUpdated')'</code></h3>'
	if [ $(echo "${ns}" | jq '.status.services|length>0') = true ]; then
	  output="${output}"'<h3>Services:</h3>'
	  output="${output}"'<ul>'
	  surls=$(echo "${ns}" | jq -r '.status.services[].serviceUrl')
	  for surl in ${surls}; do
	    output="${output}"'<li>'"${surl}"
	    service=$(echo "${ns}" | jq '.status.services[]|select(.serviceUrl=="'${surl}'")')
	    aid=$(echo "${service}" | jq -r '.agreementId')
	    orgid=$(echo "${service}" | jq -r '.orgid')
	    version=$(echo "${service}" | jq -r '.version')
	    arch=$(echo "${service}" | jq -r '.arch')
	    output="${output}"'<ul>'
	    output="${output}"'<li>Agreement: '"${aid}"'</li>'
	    output="${output}"'<li>Version: '"${version}"'</li>'
	    output="${output}"'<li>Architecture: '"${arch}"'</li>'
	    output="${output}"'<li>URL: '"${surl}"'</li>'
	    output="${output}"'<li>Images:'
	    csa=$(echo "${service}" | jq '.containerStatus')
	    if [ $(echo "${csa:-null}" | jq '.|length>0') = true ]; then
	      cis=$(echo "${csa}" | jq -r '.[].image')
	      output="${output}"'<ul>'
	      for ci in ${cis}; do
		cs=$(echo "${csa}" | jq '.[]|select(.image=="'${ci}'")')
		output="${output}"'<li>Name: '$(echo "${cs}" | jq -r '.name')'</li>'
		output="${output}"'<li>Image: '$(echo "${cs}" | jq -r '.image')'</li>'
		tse=$(echo "${cs}" | jq -r '.created')
		if [ ! -z "${tse:-}" ] && [ "${tse}" -gt 0 ]; then
		  output="${output}"'<li>Created: '$(datediff -i %s ${tse} now -f "%d days; %H hours")'</li>'
		fi
		output="${output}"'<li>State: '$(echo "${cs}" | jq -r '.state')'</li>'
	      done
	      output="${output}"'</ul>'
	    fi
	    output="${output}"'</ul>'
	    output="${output}"'</li>'
	  done
	  output="${output}"'</ul>'
	fi
      else
	output="${output}<h3>No status</h3>"
      fi
      // add delete button
      output="${output}"'<form action="/cgi-bin/delete"><input type="hidden" name="node" value="'${name}'"><input type="submit" value="DELETE"></form>'
    else
      output="${output}<b>No node</b>; node: <code>${name}</code>"
    fi
  else
    output="${output}<b>Null node</b>"
  fi
  output="${output}"'</body></html>'
  echo "${output}"
}

###
### MAIN
###

if [ -z "${1}" ]; then
  echo "*** ERROR -- $0 $$ -- provide node name to inspect" &> /dev/stderr
  exit 1
fi

# create output
mkinspect "${1}"
