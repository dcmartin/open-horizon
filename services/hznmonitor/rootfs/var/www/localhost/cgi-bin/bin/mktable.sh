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
    | jq '.={"status":.}' | jq '.org="'${HZNMONITOR_EXCHANGE_ORG}'"|.url="'${HZNMONITOR_EXCHANGE_URL}'"'
}

mktable()
{
  # get args
  if [ -z "${1:-}" ]; then width=1024; else width=${1}; fi

  # number of buckets (max 255)
  buckets=255

  # get nodes
  nodes=$(lsnodes)
  nodecount=$(echo "${nodes}" | jq '.nodes|length')
  if [ "${nodes:-null}" = 'null' ] || [ ${nodecount:-0} -eq 0 ]; then
    echo "*** ERROR -- $0 $$ -- no nodes" &> /dev/stderr
    exit 1
  fi

  # calculate size of matrix
  sqrt=$(echo "sqrt(${nodecount})" | bc -l)
  if [ ! -z "${sqrt##*.}" ]; then sqrt=${sqrt%.*} && sqrt=$((sqrt+1)); fi
  rows=${sqrt}
  columns=${rows}
  cell_size=$((width/rows))
  cell_border=$((cell_size/3))
  cell_size=$((cell_size-cell_border))

  # minimum
  if [ ${cell_size} -lt 4 ]; then cell_size=4; cell_border=1; fi
  if [ ${cell_size} -lt 20 ]; then NOTEXT=true; else NOTEXT=false; fi

  # debug
  echo "--- INFO -- $0 $$ -- table: rows: ${rows}; columns: ${columns}; cell cell_size: ${cell_size}; cell border: ${cell_border}" &> /dev/stderr

  # get time in seconds between now and oldest node
  now=$(date +%s)
  oldest=$(echo "${nodes}" | jq -r '.nodes|sort_by(.lastHeartbeat)|first|.lastHeartbeat')
  newest=$(echo "${nodes}" | jq -r '.nodes|sort_by(.lastHeartbeat)|reverse|first|.lastHeartbeat')
  echo "--- INFO -- $0 $$ -- oldest: ${oldest}; newest: ${newest}" &> /dev/stderr
  range=$(datediff "${oldest}" "${newest}" -f "%S") && range=${range#-}
  duration=$(datediff "${newest}" 'now' -f "%S") && duration=${duration#-}
  increment=$((range/buckets))
  echo "--- INFO -- $0 $$ -- range: ${range}; increment: ${increment}" &> /dev/stderr

  output='<table>'
  k=0; i=0; while [ ${i} -lt ${rows} ]; do
    output="${output}"'<tr>'
    j=0; while [ ${j} -lt ${columns} ]; do
      if [ ${k} -lt ${nodecount} ]; then
	info=
	color="ffffff"
	border="ffffff"
	node=$(echo "${nodes}" | jq '.nodes['${k}']')
	id=$(echo "${node}" | jq -r '.id')
	lhb=$(echo "${node}" | jq -r '.lastHeartbeat')
	if [ ! -z "${lhb:-}" ]; then
	  name=$(echo "${node}" | jq -r '.name')

	  # calculate how old
	  seconds=$(datediff "${lhb}" 'now' -f %S) && seconds=${seconds#-}
	  pct=$(echo "${seconds} / ${duration} * 100.0" | bc -l | awk '{printf("%d",$1)}')
	  echo "--- INFO -- $0 $$ -- seconds: ${ago}; duration: ${duration}; pct: ${pct}; lastHeartbeat; ${lhb}" &> /dev/stderr

	  # calculate cell exterior color; progressive from green to yellow to red
	  green=100; if [ ${pct:-0} -gt 50 ]; then red=100; green=$((green-(pct-50))); else red=$((pct)); fi
	  echo "--- INFO -- $0 $$ -- seconds: ${seconds}; pct=${pct}; red=${red}; green=${green}" &> /dev/stderr
	  # convert to hex
	  red=$(echo "${red} / 100.0 * ${buckets}" | bc -l | awk '{ printf("%02x", $1) }')
	  green=$(echo "${green} / 100.0 * ${buckets}" | bc -l | awk '{ printf("%02x", $1) }')
	  echo "--- INFO -- $0 $$ -- seconds: ${seconds}; pct=${pct}; red=${red}; green=${green}" &> /dev/stderr
	  # assign color to cell interior
	  border="${red}${green}00"

	  ns=$(nodestatus ${name})
	  if [ ! -z "${ns:-}" ]; then
	    if [ $(echo "${ns:-null}" | jq '.error?==null') != true ]; then
	      echo "+++ WARN -- $0 $$ -- status error; id: ${id}; name: ${name}; error: " $(echo ${ns:-null} | jq '.error') &> /dev/stderr
	      link=
	      color="ffff00"
	    else  
	      update=$(echo "${ns}" | jq -r '.status.lastUpdated')
	      if [ ! -z "${update}" ]; then
		# calculate how old
	        ago=$(datediff "${update}" "${newest}" -f %S) && ago=${ago#-}
                pct=$(echo "${ago} / ${range} * 100.0" | bc -l | awk '{printf("%d",$1)}')
		echo "--- INFO -- $0 $$ -- ago: ${ago}; range: ${range}; pct: ${pct}; lastUpdated; ${update}" &> /dev/stderr

		# calculate cell interior color; progressive from green to yellow to red
		green=100; if [ ${pct:-0} -gt 50 ]; then red=100; green=$((green-(pct-50))); else red=$((pct)); fi
	        echo "--- INFO -- $0 $$ -- ago: ${ago}; pct=${pct}; red=${red}; green=${green}" &> /dev/stderr

		# convert to hex
		red=$(echo "${red} / 100.0 * ${buckets}" | bc -l | awk '{ printf("%02x", $1) }')
		green=$(echo "${green} / 100.0 * ${buckets}" | bc -l | awk '{ printf("%02x", $1) }')
	        echo "--- INFO -- $0 $$ -- ago: ${ago}; pct=${pct}; red=${red}; green=${green}" &> /dev/stderr
		# assign color to cell interior
		color="${red}${green}00"

		# calculate time
		weeks=$((ago/604800)) && ago=$((ago-weeks*604800))
                if [ ${weeks:-0} -gt 0 ]; then info="${weeks}w"; fi
	        days=$((ago/86400)) && ago=$((ago-days*86400))
                if [ ${days:-0} -gt 0 ]; then info="${info:-}${days}d"; fi
	        hours=$((ago/3600)) && ago=$((ago-hours*3600))
                if [ ${weeks:-0} -eq 0 ] && [ ${hours:-0} -gt 0 ]; then info="${info:-}${hours}h"; fi
	        mins=$((ago/60)) && ago=$((ago-mins*60))
                if [ ${weeks:-0} -eq 0 ] && [ ${days:-0} -eq 0 ] && [ ${mins:-0} -gt 0 ]; then info="${info:-}${mins}m"; fi
                if [ ${weeks:-0} -eq 0 ] && [ ${days:-0} -eq 0 ] && [ ${hours:-0} -eq 0 ] && [ ${ago:-0} -gt 0 ]; then info="${info:-}${ago}s"; fi

		agreements=$(echo "${ns}" | jq '[.status.services[]|select(.agreementId!="")]|length')
		services=$(echo "${ns}" | jq '.status.services?|length')
		running=$(echo "${ns}" | jq '[.status.services[]|select(.containerStatus[].state=="running")]|length') 

		info="${info:-NONE}<br>${agreements:-0}:${running:-0}/${services:-0}"

	        echo "--- INFO -- $0 $$ -- node: ${name}; info: ${info}" &> /dev/stderr

		link=${name}
	      else
		echo "+++ WARN -- $0 $$ -- no lastUpdated; id: ${id}; name: ${name}; status: " $(echo ${ns:-null} | jq -c '.') &> /dev/stderr
		link=
		color="C0C0C0" # "magnesium"
	      fi 
	    fi
	  else
	    echo "+++ WARN -- $0 $$ -- no status response; id: ${id}; name: ${name}" &> /dev/stderr
	    link=
	    ago=$(datediff "${newest}" "${lhb}" -f %S) && ago=${ago#-}
	    days=$((ago/86400))
	    hours=$(echo "( ${ago} - ${days} * 86400 ) / 3600" | bc | awk '{ printf("%d", $1) }')
	    mins=$(echo "( ${ago} - ${days} * 86400 - ${hours} * 3600) / 60" | bc | awk '{ printf("%02d", $1) }')
            if [ ${days} -gt 0 ]; then days="${days}d<br>"; mins=; else days=; mins="${mins}m"; fi
            if [ ${hours} -gt 0 ]; then hours="${hours}h"; else hours=; fi
	    info="${days}${hours}${mins}"
	    color="C0C0C0" # "magnesium"
	  fi
	else
	  echo "+++ WARN -- $0 $$ -- no heartbeat; id: ${id}" &> /dev/stderr
	  color="C0C0C0" # "magnesium"
	  color="000000"
	fi
	k=$((k+1))
      else
	color="ffffff"
	border="ffffff"
	link=
	id="table-cell-${i}${j}"
	info=
      fi
      # STATUS CELL
      output="${output}"'<td bgcolor="'${border}'" valign="middle" align="center" id="'${id}'" width="'$((cell_size+cell_border*2))'" height="'$((cell_size+cell_border*2))'">'
      if [ ! -z "${link}" ]; then output="${output}"'<a href="/cgi-bin/inspect?node='${link}'">'; fi
      output="${output}"'<table><tr><td valign="middle" align="center" id="'${name}'" bgcolor="'${color}'" width="'${cell_size}'" height="'${cell_size}'">'
      if [ "${NOTEXT:-}" = false ]; then output="${output}${info:-}"; fi
      output="${output}"'</td></tr></table>'
      if [ ! -z "${link}" ]; then output="${output}"'</a>'; fi
      output="${output}"'</td>'
      j=$((j+1))
    done
    output="${output}"'</tr>'
    i=$((i+1))
  done

  output="${output}"'</table>'
  echo "${output}"
}

###
### MAIN
###

if [ -z "${1}" ]; then
  echo "*** ERROR -- $0 $$ -- provide file name for output" &> /dev/stderr
  exit 1
fi

# maximum size of table in pixels
WIDTH=1024

# create output
temp=$(mktemp -t "${0##*/}-XXXXXX")
mktable ${WIDTH} | tee ${temp}

# finalize output
mv -f ${temp} ${1}
