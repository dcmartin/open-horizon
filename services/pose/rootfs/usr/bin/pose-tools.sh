#!/usr/bin/env bash

# sanity
if [ -z "${OPENPOSE}" ]; then echo "*** ERROR -- $0 $$ -- OPENPOSE unspecified; set environment variable for testing"; fi

# defaults for testing
if [ -z "${POSE_THRESHOLD:-}" ]; then POSE_THRESHOLD=10; fi
if [ -z "${POSE_SCALE:-}" ]; then POSE_SCALE="320x240"; fi
if [ -z "${POSE_PERIOD:-}" ]; then POSE_PERIOD=30; fi

pose_init() 
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ -d "${OPENPOSE}/runtime_data/config" ]; then
    local names=$(find ${OPENPOSE}/runtime_data/config -name '*.conf' -print | while read; do file=${REPLY##*/} && echo "${file%%.*}"; done)
    local countries

    for name in ${names}; do
      if [ ! -z "${countries:-}" ]; then countries="${countries}"','; else countries='['; fi
      countries="${countries}"'"'${name}'"'
    done
    if [ ! -z "${countries:-}" ]; then countries="${countries}"']'; else countries='null'; fi
  fi

  # build configuation
  CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"period":'${POSE_PERIOD}',"scale":"'${POSE_SCALE}'","threshold":'${POSE_THRESHOLD}',"services":'"${SERVICES:-null}"',"countries":'${countries:-null}'}'

  echo "${CONFIG}"
}

pose_config()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  case ${1} in
    us)
      OPENPOSE_WEIGHTS="${OPENPOSE_US_WEIGHTS_URL}"
      POSE_WEIGHTS="${OPENPOSE_US_WEIGHTS}"
      POSE_CFG_FILE="${OPENPOSE_US_CONFIG}"
      POSE_DATA="${OPENPOSE_US_DATA}"
    ;;
    eu)
      OPENPOSE_WEIGHTS="${OPENPOSE_EU_WEIGHTS_URL}"
      POSE_WEIGHTS="${OPENPOSE_EU_WEIGHTS}"
      POSE_CFG_FILE="${OPENPOSE_EU_CONFIG}"
      POSE_DATA="${OPENPOSE_EU_DATA}"
    ;;
    *)
      hzn::log.info "Default configuration"
    ;;
  esac
  if [ ! -z "${POSE_WEIGHTS:-}" ] && [ ! -s "${POSE_WEIGHTS}" ]; then
    hzn::log.debug "POSE config: ${1}; updating ${POSE_WEIGHTS} from ${OPENPOSE_WEIGHTS}"
    curl -fsSL ${OPENPOSE_WEIGHTS} -o ${POSE_WEIGHTS}
    if [ ! -s "${POSE_WEIGHTS}" ]; then
      hzn::log.error "POSE config: ${1}; failed to download: ${OPENPOSE_WEIGHTS}"
    fi
  fi
}

pose_process()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local PAYLOAD="${1}"
  local ITERATION="${2:-}"
  local MOCKS=($(find /usr/share/pose/ -name "*.jpg" -print))
  local JPEG=$(mktemp).jpg
  local OUT=$(mktemp).jpg
  local output
  local config
  local info
  local result
  local mock

  # test image 
  if [ ! -s "${PAYLOAD}" ]; then 
    if [ -z "${ITERATION}" ]; then MOCK_INDEX=0; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    hzn::log.debug "MOCK index: ${MOCK_INDEX} of ${#MOCKS[@]}"
    MOCK="${MOCKS[${MOCK_INDEX}]}"
    hzn::log.debug "MOCK image: ${MOCK}"
    cp -f "${MOCK}" ${PAYLOAD}
    # update output to be mock
    mock=${MOCK##*/}
  fi

  # scale
  if [ "${POSE_SCALE}" != 'none' ]; then
    convert -scale "${POSE_SCALE}" "${PAYLOAD}" "${JPEG}"
  else
    cp -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn::log.debug "JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }')

  # image information
  local info=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.mock="'${mock:-false}'"')

  # check configuration options
  if [ ! -z "${POSE_COUNTRY:-}" ]; then CONFIG="-c ${POSE_COUNTRY}"; fi
  if [ ! -z "${POSE_PATTERN:-}" ]; then PATTERN="-p ${POSE_PATTERN}"; fi
  if [ ! -z "${POSE_CFG_FILE:-}" ]; then CFG_FILE="--config ${POSE_CFG_FILE}"; fi
  local config='{"scale":"'${POSE_SCALE}'","threshold":"'${POSE_THRESHOLD}'"}'

  ## do POSE
  hzn::log.debug "OPENPOSE: pose --clock --json ${CFG_FILE} ${CONFIG} ${PATTERN} -n ${POSE_THRESHOLD} ${JPEG}"
  pose ${JPEG} > "${OUT}" 2> "${TMPDIR}/pose.$$.out"

  # test for output
  if [ -s "${OUT}" ]; then
    local seconds=$(jq '.seconds' ${OUT})
    local count=$(jq '.count' ${OUT})
    local detected=$(jq '[.results[].confidence]' ${OUT})
    
    hzn::log.debug "${FUNCNAME[0]} - SECONDS: ${seconds}; COUNT: ${count}; DETECTED: ${detected}"

    # initiate output
    result=$(mktemp)
    echo '{"count":'${count:-null}',"detected":'"${detected:-null}"',"results":'$(jq '.results' ${OUT})',"time":'${time_ms:-null}'}' \
      | jq '.info='"${info:-null}" \
      | jq '.config='"${config:-null}" > ${result}

    # annotated image
    local annotated=$(pose_annotate ${OUT} ${JPEG})

    if [ "${annotated:-null}" != 'null' ]; then
      local b64file=$(mktemp)

      echo -n '{"image":"' > "${b64file}"
      base64 -w 0 -i ${annotated} >> "${b64file}"
      echo '"}' >> "${b64file}"
      jq -s add "${result}" "${b64file}" > "${result}.$$" && mv -f "${result}.$$" "${result}"
      rm -f ${b64file} ${annotated}
    fi
    rm -f "${JPEG}" "${OUT}" 
  else
    echo "+++ WARN $0 $$ -- no output:" $(cat ${OUT}) &> /dev/stderr
    hzn::log.debug "pose failed:" $(cat "${TMPDIR}/pose.$$.out")
  fi

  echo "${result:-}"
}

pose_annotate()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local json=${1}
  local jpeg=${2}
  local colors=(white yellow green orange magenta cyan lime pink gold blue red)

  local result

  if [ -s "${json}" ] && [ -s "${jpeg}" ]; then
    local length=$(jq '.results|length' ${json})
    poses=

    if [ ${length:0} -gt 0 ]; then
      local i=0
      local count=0

      while [ ${i} -lt ${length} ]; do
        local pose=$(jq '.results['${i}']' ${json})
        local left=$(echo "${pose:-null}" | jq -r '.x')
        local top=$(echo "${pose:-null}" | jq -r '.y')
        local width=$(echo "${pose:-null}" | jq -r '.width')
        local height=$(echo "${pose:-null}" | jq -r '.height')
        local bottom=$((top+height))
        local right=$((left+width))
        local confidence=$(echo "${pose:-null}" | jq -r '.confidence')

        if [ ${i} -eq 0 ]; then
          file=${jpeg%%.*}-${i}.jpg
          cp -f ${jpeg} ${file}
        else
          rm -f ${file}
          file=${output}
        fi
        output=${jpeg%%.*}-$((i+1)).jpg
        convert -font DejaVu-Sans-Mono -pointsize 16 -stroke ${colors[${count}]} -fill none -strokewidth 2 -draw "rectangle ${left},${top} ${right},${bottom} push graphic-context stroke ${colors[${count}]} fill ${colors[${count}]} translate ${right},${bottom} text 3,6 '${confidence}' pop graphic-context" ${file} ${output}
        if [ ! -s "${output}" ]; then
          hzn::log.error "${FUNCNAME[0]} - failure to annotate image; jpeg: ${jpeg}; json: " $(echo "${json}" | jq -c '.')
          output=""
          break
        fi
        i=$((i+1))
        count=$((count+1))
        if [ ${count} -ge ${#colors[@]} ]; then count=0; fi
      done
      if [ ! -z "${output:-}" ]; then
        rm -f ${file}
        result=${jpeg%%.*}-pose.jpg
        mv ${output} ${result}
      fi
    fi
  fi      
  echo "${result:-null}"
}
