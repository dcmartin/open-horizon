#!/usr/bin/env bash

# sanity
if [ -z "${OPENFACE}" ]; then echo "*** ERROR -- $0 $$ -- OPENFACE unspecified; set environment variable for testing"; fi

# defaults for testing
if [ -z "${FACE_THRESHOLD:-}" ]; then FACE_THRESHOLD=10; fi
if [ -z "${FACE_SCALE:-}" ]; then FACE_SCALE="320x240"; fi
if [ -z "${FACE_PERIOD:-}" ]; then FACE_PERIOD=30; fi

face_init() 
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  if [ -d "${OPENFACE}/runtime_data/config" ]; then
    local names=$(find ${OPENFACE}/runtime_data/config -name '*.conf' -print | while read; do file=${REPLY##*/} && echo "${file%%.*}"; done)
    local countries

    for name in ${names}; do
      if [ ! -z "${countries:-}" ]; then countries="${countries}"','; else countries='['; fi
      countries="${countries}"'"'${name}'"'
    done
    if [ ! -z "${countries:-}" ]; then countries="${countries}"']'; else countries='null'; fi
  fi

  # build configuation
  CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-}',"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"period":'${FACE_PERIOD}',"scale":"'${FACE_SCALE}'","threshold":'${FACE_THRESHOLD}',"services":'"${SERVICES:-null}"',"countries":'${countries:-null}'}'

  echo "${CONFIG}"
}

face_config()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  case ${1} in
    us)
      OPENFACE_WEIGHTS="${OPENFACE_US_WEIGHTS_URL}"
      FACE_WEIGHTS="${OPENFACE_US_WEIGHTS}"
      FACE_CFG_FILE="${OPENFACE_US_CONFIG}"
      FACE_DATA="${OPENFACE_US_DATA}"
    ;;
    eu)
      OPENFACE_WEIGHTS="${OPENFACE_EU_WEIGHTS_URL}"
      FACE_WEIGHTS="${OPENFACE_EU_WEIGHTS}"
      FACE_CFG_FILE="${OPENFACE_EU_CONFIG}"
      FACE_DATA="${OPENFACE_EU_DATA}"
    ;;
    *)
      hzn::log.info "Default configuration"
    ;;
  esac
  if [ ! -z "${FACE_WEIGHTS:-}" ] && [ ! -s "${FACE_WEIGHTS}" ]; then
    hzn::log.debug "FACE config: ${1}; updating ${FACE_WEIGHTS} from ${OPENFACE_WEIGHTS}"
    curl -fsSL ${OPENFACE_WEIGHTS} -o ${FACE_WEIGHTS}
    if [ ! -s "${FACE_WEIGHTS}" ]; then
      hzn::log.error "FACE config: ${1}; failed to download: ${OPENFACE_WEIGHTS}"
    fi
  fi
}

face_process()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local PAYLOAD="${1}"
  local ITERATION="${2:-}"
  local MOCKS=($(find /usr/share/face/ -name "*.jpg" -print))
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
  if [ "${FACE_SCALE}" != 'none' ]; then
    convert -scale "${FACE_SCALE}" "${PAYLOAD}" "${JPEG}"
  else
    cp -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn::log.debug "JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }')

  # image information
  local info=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.mock="'${mock:-false}'"')

  # check configuration options
  if [ ! -z "${FACE_COUNTRY:-}" ]; then CONFIG="-c ${FACE_COUNTRY}"; fi
  if [ ! -z "${FACE_PATTERN:-}" ]; then PATTERN="-p ${FACE_PATTERN}"; fi
  if [ ! -z "${FACE_CFG_FILE:-}" ]; then CFG_FILE="--config ${FACE_CFG_FILE}"; fi
  local config='{"scale":"'${FACE_SCALE}'","threshold":"'${FACE_THRESHOLD}'"}'

  ## do FACE
  hzn::log.debug "OPENFACE: face --clock --json ${CFG_FILE} ${CONFIG} ${PATTERN} -n ${FACE_THRESHOLD} ${JPEG}"
  face ${JPEG} > "${OUT}" 2> "${TMPDIR}/face.$$.out"

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
    local annotated=$(face_annotate ${OUT} ${JPEG})

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
    hzn::log.debug "face failed:" $(cat "${TMPDIR}/face.$$.out")
  fi

  echo "${result:-}"
}

face_annotate()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local json=${1}
  local jpeg=${2}
  local colors=(white yellow green orange magenta cyan lime pink gold blue red)

  local result

  if [ -s "${json}" ] && [ -s "${jpeg}" ]; then
    local length=$(jq '.results|length' ${json})
    faces=

    if [ ${length:0} -gt 0 ]; then
      local i=0
      local count=0

      while [ ${i} -lt ${length} ]; do
        local face=$(jq '.results['${i}']' ${json})
        local left=$(echo "${face:-null}" | jq -r '.x')
        local top=$(echo "${face:-null}" | jq -r '.y')
        local width=$(echo "${face:-null}" | jq -r '.width')
        local height=$(echo "${face:-null}" | jq -r '.height')
        local bottom=$((top+height))
        local right=$((left+width))
        local confidence=$(echo "${face:-null}" | jq -r '.confidence')

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
        result=${jpeg%%.*}-face.jpg
        mv ${output} ${result}
      fi
    fi
  fi      
  echo "${result:-null}"
}
