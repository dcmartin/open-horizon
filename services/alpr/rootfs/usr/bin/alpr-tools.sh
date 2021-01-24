#!/usr/bin/with-contenv bashio

alpr::countries() 
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local names=$(find ${OPENALPR:-}/runtime_data/config -name '*.conf' -print | while read; do file=${REPLY##*/} && echo "${file%%.*}"; done)
  local countries

  for name in ${names}; do
    if [ ! -z "${countries:-}" ]; then countries="${countries}"','; else countries='['; fi
    countries="${countries}"'"'${name}'"'
  done
  if [ ! -z "${countries:-}" ]; then countries="${countries}"']'; else countries='null'; fi

  echo "${countries:-null}"
}

alpr::config()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  case ${1} in
    us)
      OPENALPR_WEIGHTS="${OPENALPR_US_WEIGHTS_URL}"
      ALPR_WEIGHTS="${OPENALPR_US_WEIGHTS}"
      ALPR_CFG_FILE="${OPENALPR_US_CONFIG}"
      ALPR_DATA="${OPENALPR_US_DATA}"
    ;;
    eu)
      OPENALPR_WEIGHTS="${OPENALPR_EU_WEIGHTS_URL}"
      ALPR_WEIGHTS="${OPENALPR_EU_WEIGHTS}"
      ALPR_CFG_FILE="${OPENALPR_EU_CONFIG}"
      ALPR_DATA="${OPENALPR_EU_DATA}"
    ;;
    *)
      hzn::log.error "Invalid ALPR_COUNTRY: ${1}"
    ;;
  esac
  if [ ! -z "${ALPR_WEIGHTS:-}" ] && [ ! -s "${ALPR_WEIGHTS}" ]; then
    hzn::log.debug "ALPR config: ${1}; updating ${ALPR_WEIGHTS} from ${OPENALPR_WEIGHTS}"
    curl -fsSL ${OPENALPR_WEIGHTS} -o ${ALPR_WEIGHTS}
    if [ ! -s "${ALPR_WEIGHTS}" ]; then
      hzn::log.error "ALPR config: ${1}; failed to download: ${OPENALPR_WEIGHTS}"
    fi
  fi
}

alpr::process()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local PAYLOAD="${1}"
  local ITERATION="${2:-}"
  local MOCKS=($(find /usr/share/alpr/ -name "*.jpg" -print))
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
  if [ "${ALPR_SCALE}" != 'none' ]; then
    convert -scale "${ALPR_SCALE}" "${PAYLOAD}" "${JPEG}"
  else
    cp -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn::log.debug "JPEG: ${JPEG}; size:" $(wc -c "${JPEG}" | awk '{ print $1 }')

  # image information
  local info=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.mock="'${mock:-false}'"')

  # check configuration options
  if [ ! -z "${ALPR_COUNTRY:-}" ]; then CONFIG="-c ${ALPR_COUNTRY}"; fi
  if [ ! -z "${ALPR_PATTERN:-}" ]; then PATTERN="-p ${ALPR_PATTERN}"; fi
  if [ ! -z "${ALPR_CFG_FILE:-}" ]; then CFG_FILE="--config ${ALPR_CFG_FILE}"; fi
  local config='{"scale":"'${ALPR_SCALE}'","country":"'${ALPR_COUNTRY}'","pattern":"'${ALPR_PATTERN}'","cfg_file":"'${ALPR_CFG_FILE}'"}'

  ## do ALPR
  hzn::log.debug "OPENALPR: alpr --clock --json ${CFG_FILE} ${CONFIG} ${PATTERN} -n ${ALPR_TOPN} ${JPEG}"
  alpr --json ${CFG_FILE} ${CONFIG} ${PATTERN} -n ${ALPR_TOPN} ${JPEG} > "${OUT}" 2> "${TMPDIR}/alpr.$$.out"

  # test for output
  if [ -s "${OUT}" ]; then
    local time_ms=$(jq '.processing_time_ms?' ${OUT})
    local count=$(jq '.results?|length' ${OUT})

    if [ "${time_ms:-null}" != 'null' ] && [ ${time_ms%%.*} -gt 0 ]; then
      time_ms=$(echo "${time_ms} / 1000.0" | bc -l)
    fi
    if [ ${count:-0} -gt 0 ]; then
      local plates=$(jq -r '.results[].plate' ${OUT})

      for plate in ${plates}; do
        if [ "${detected:-null}" != 'null' ]; then detected="${detected},"; else detected='['; fi
        detected="${detected}"'"'${plate}'"'
      done
      if [ "${detected:-null}" != 'null' ]; then detected="${detected}"']'; fi
    fi
    hzn::log.debug "DETECTED: ${detected}"
    # initiate output
    result=$(mktemp)
    echo '{"count":'${count:-null}',"detected":'"${detected:-null}"',"results":'$(jq '.results' ${OUT})',"time":'${time_ms:-null}'}' \
      | jq '.info='"${info:-null}" \
      | jq '.config='"${config:-null}" > ${result}

    # annotated image
    local annotated=$(alpr::annotate ${OUT} ${JPEG})

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
    hzn::log.debug "alpr failed:" $(cat "${TMPDIR}/alpr.$$.out")
  fi

  echo "${result:-}"
}

alpr::annotate()
{
  local json=${1}
  local jpeg=${2}
  local result

  if [ -s "${json}" ] && [ -s "${jpeg}" ]; then
    local plates=$(jq '[.results[]|{"tag":.plate,"confidence":.confidence,"top":[.coordinates[].y]|min,"left":[.coordinates[].x]|min,"bottom":[.coordinates[].y]|max,"right":[.coordinates[].x]|max}]' ${json})
    local tags=$(echo "${plates:-null}" | jq -r '.[].tag?')
    local colors=(white yellow green orange magenta cyan lime pink gold blue red)
    local count=0
    local output=

    for t in ${tags}; do
      local plate=$(echo "${plates:-null}" | jq '.[]|select(.tag=="'${t}'")')
      local top=$(echo "${plate:-null}" | jq -r '.top')
      local left=$(echo "${plate:-null}" | jq -r '.left')
      local bottom=$(echo "${plate:-null}" | jq -r '.bottom')
      local right=$(echo "${plate:-null}" | jq -r '.right')

      if [ ${count} -eq 0 ]; then
        file=${jpeg%%.*}-${count}.jpg
        cp -f ${jpeg} ${file}
      else
        rm -f ${file}
        file=${output}
      fi
      output=${jpeg%%.*}-$((count+1)).jpg
      convert -font DejaVu-Sans-Mono -pointsize 24 -stroke ${colors[${count}]} -fill none -strokewidth 5 -draw "rectangle ${left},${top} ${right},${bottom} push graphic-context stroke ${colors[${count}]} fill ${colors[${count}]} translate ${right},${bottom} rotate 40 path 'M 10,0  l +15,+5  -5,-5  +5,-5  -15,+5  m +10,0 +20,0' translate 40,0 rotate -40 stroke none fill ${colors[${count}]} text 3,6 '${t}' pop graphic-context" ${file} ${output}
      if [ ! -s "${output}" ]; then
        hzn::log.error "${FUNCNAME[0]} - failure to annotate image; jpeg: ${jpeg}; json: " $(echo "${json}" | jq -c '.')
        output=""
        break
      fi
      count=$((count+1))
      if [ ${count} -ge ${#colors[@]} ]; then count=0; fi
    done
    if [ ! -z "${output:-}" ]; then
      rm -f ${file}
      result=${jpeg%%.*}-alpr.jpg
      mv ${output} ${result}
    fi
  fi
  echo "${result:-null}"
}
