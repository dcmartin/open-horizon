#!/usr/bin/with-contenv bashio

yolo::init() 
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  ## configure YOLO
  local which=${1:-tiny-v2}
  local darknet=$(yolo::config ${which})

  local weights=$(echo "${darknet}" | jq -r '.weights')
  local weights_url=$(echo "${darknet}" | jq -r '.weights_url')
  local weights_md5=$(echo "${darknet}" | jq -r '.weights_md5')
  local namefile=$(echo "${darknet}" | jq -r '.names')

  local OUT="$(mktemp).$$.out"
  local CONF_FILE=/etc/yolo.conf
  local CONFIG
  local NAMES
  local attempts=0

  hzn::log.debug "${FUNCNAME[0]} config: ${which}; weights: ${weights}; attempts: ${YOLO_ATTEMPTS:-2}"

  while [ ${attempts} -le ${YOLO_ATTEMPTS:-2} ]; do
    if [ -s "${weights}" ]; then
      local md5=$(md5sum ${weights} | awk '{ print $1 }')

      if [ "${md5}" != "${weights_md5}" ]; then
        hzn::log.warning "${FUNCNAME[0]}: ${which}; attempt: ${attempts}; failed checksum: ${md5} != ${weights_md5}"
        rm -f ${weights}
      else
        hzn::log.info "${FUNCNAME[0]}: downloaded; model: ${which}; weights: ${weights}"
        break
      fi
    fi

    # download
    hzn::log.notice "${FUNCNAME[0]}: config: ${which}; downloading ${weights} from ${weights_url}"
    curl -fsSL ${weights_url} -o ${weights}
    attempts=$((attempts+1))
  done

  if [ ! -s "${weights}" ]; then
    hzn::log.warning "${FUNCNAME[0]}: YOLO config: ${which}; failed to download after ${YOLO_ATTEMPTS:-2}; defaulting to ${YOLO_DEFAULT:-tiny-v2}"
    yolo::config ${YOLO_DEFAULT:-tiny-v2}
  fi

  # get namefile of entities that can be detected
  if [ -s "${namefile}" ]; then
    hzn::log.debug "${FUNCNAME[0]}: model: ${which}; names: ${namefile}"
    NAMES='['$(awk -F'|' '{ printf("\"%s\"", $1) }' "${namefile}" | sed 's|""|","|g')']'
  fi
  if [ -z "${NAMES:-}" ]; then 
    hzn::log.warning "${FUNCNAME[0]}: NO NAMES; using 'person'; model: ${which}; names: ${namefile}"
    NAMES='["person"]'
  fi

  # done
  echo '{"darknet":'"${darknet}"', "period":'${YOLO_PERIOD:-null}', "entity":"'${YOLO_ENTITY:-}'", "scale":"'${YOLO_SCALE:-none}'", "resolution":"'${YOLO_RESOLUTION:-384x288}'","device":"'${YOLO_DEVICE:-/dev/video0}'", "names":'"${NAMES}"'}'
}

yolo::config()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local model=${1:-tiny}

  case ${model} in
    tiny|tiny-v2)
      YOLO_WEIGHTS_URL="${DARKNET_TINYV2_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_TINYV2_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_TINYV2_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_TINYV2_CONFIG}"
      YOLO_DATA="${DARKNET_TINYV2_DATA}"
      YOLO_NAMES="${DARKNET_TINYV2_NAMES}"
    ;;
    tiny-v3)
      YOLO_WEIGHTS_URL="${DARKNET_TINYV3_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_TINYV3_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_TINYV3_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_TINYV3_CONFIG}"
      YOLO_DATA="${DARKNET_TINYV3_DATA}"
      YOLO_NAMES="${DARKNET_TINYV3_NAMES}"
    ;;
    v2)
      YOLO_WEIGHTS_URL="${DARKNET_V2_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_V2_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_V2_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_V2_CONFIG}"
      YOLO_DATA="${DARKNET_V2_DATA}"
      YOLO_NAMES="${DARKNET_V2_NAMES}"
    ;;
    v3)
      YOLO_WEIGHTS_URL="${DARKNET_V3_WEIGHTS_URL}"
      YOLO_WEIGHTS_MD5="${DARKNET_V3_WEIGHTS_MD5}"
      YOLO_WEIGHTS="${DARKNET_V3_WEIGHTS}"
      YOLO_CFG_FILE="${DARKNET_V3_CONFIG}"
      YOLO_DATA="${DARKNET_V3_DATA}"
      YOLO_NAMES="${DARKNET_V3_NAMES}"
    ;;
    *)
      hzn::log.error "${FUNCNAME[0]}: unknown model: ${model}"
    ;;
  esac
  echo '{"threshold":'${YOLO_THRESHOLD:-}',"weights_url":"'${YOLO_WEIGHTS_URL:-}'","weights":"'${YOLO_WEIGHTS:-}'","weights_md5":"'${YOLO_WEIGHTS_MD5:-}'","cfg":"'${YOLO_CFG_FILE:-}'","data":"'${YOLO_DATA:-}'","names":"'${YOLO_NAMES:-}'"}'
}

yolo::process()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local PAYLOAD="${1:-}"
  local ITERATION="${2:-}"
  local output='{}'
  local MOCK=
  local JPEG=$(mktemp).jpeg
  local MOCKS=( dog giraffe kite eagle horses person scream )

  # test image
  if [ ! -s "${PAYLOAD}" ]; then
    if [ -z "${ITERATION}" ]; then MOCK_INDEX=0; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    MOCK=${MOCKS[${MOCK_INDEX}]}
    hzn::log.debug "${FUNCNAME[0]} - no payload; using mock: ${DARKNET}/data/${MOCK}.jpg"
    cp -f "${DARKNET}/data/${MOCK}.jpg" ${PAYLOAD}
    MOCK='"'${MOCKS[${MOCK_INDEX}]}'"'
  else
    MOCK=null
  fi

  # scale image
  if [ "${YOLO_SCALE:-none}" != 'none' ]; then
    local err=$(mktemp)
    convert -scale "${YOLO_SCALE}" "${PAYLOAD}" "${JPEG}" &> ${err}
    if [ ! -s ${JPEG} ]; then
      hzn::log.error "${FUNCNAME[0]}: scale conversion failed; reverting to original; error: " $(cat err)
      cp -f "${PAYLOAD}" "${JPEG}"
    fi
    rm -f ${err}
  else
    cp -f "${PAYLOAD}" "${JPEG}"
  fi
  hzn::log.debug "${FUNCNAME[0]}: PAYLOAD: ${PAYLOAD}; size: $(wc -c ${PAYLOAD} | awk '{ print $1 }'); JPEG: ${JPEG}; size: $(wc -c ${JPEG} | awk '{ print $1 }')"

  # image information
  local info=$(identify "${JPEG}" | awk '{ printf("{\"type\":\"%s\",\"size\":\"%s\",\"bps\":\"%s\",\"color\":\"%s\"}", $2, $3, $5, $6) }' | jq -c '.mock="'${mock:-false}'"')

  local config='{"scale":"'${YOLO_SCALE:-none}'","threshold":"'${YOLO_THRESHOLD:-}'"}'

  ## do YOLO
  local before=$(date +%s.%N)
  local OUT=$(mktemp)
  local err=$(mktemp)

  ## TODO: Change to Detector3 to check use with gifs
  hzn::log.debug "${FUNCNAME[0]}: OPENYOLO: /usr/bin/detector.py ${JPEG} ${YOLO_THRESHOLD} ${YOLO_CONFIG}"
  cd ${OPENYOLO} && /usr/bin/detector.py ${JPEG} ${YOLO_THRESHOLD} ${YOLO_CONFIG} > "${OUT}" 2> ${err}

  local after=$(date +%s.%N)
  local seconds=$(echo "${after} - ${before}" | bc -l)

  hzn::log.debug "${FUNCNAME[0]}: time: ${seconds}; output:" $(jq -c '.' ${OUT})

  # test for output
  if [ -s "${OUT}" ]; then
    local count=$(jq -r '.count' ${OUT})
    local results=$(jq '.results' ${OUT})

    hzn::log.info "${FUNCNAME[0]}: COUNT: ${count}; RESULTS:" $(echo "${results}" | jq -c '.')

    if [ ! -z "${count:-}" ] && [ "${results:-null}" != 'null' ]; then
      local detected=$(for e in $(jq -r '.results|map(.entity)|unique[]' ${OUT}); do jq '{"entity":"'${e}'","count":[.results[]|select(.entity=="'${e}'")]|length}' ${OUT} ; done | jq -s '.')

      hzn::log.debug "${FUNCNAME[0]} - DETECTED:" $(echo "${detected}" | jq -c '.')
    else
      hzn::log.debug "${FUNCNAME[0]}: nothing seen"
    fi
  
    # initiate output
    result=$(mktemp).result
    echo '{"count":'${count:-null}',"detected":'"${detected:-null}"',"results":'${results:-null}',"time":'${time_ms:-null}'}' \
        | jq '.info='"${info:-null}" \
        | jq '.config='"${config:-null}" > ${result}
  
    # annotated image
    local annotated=$(yolo::annotate ${OUT} ${JPEG})
  
    if [ "${annotated:-null}" != 'null' ]; then
      local b64file=$(mktemp).b64
  
      echo -n '{"image":"' > "${b64file}"
      base64 -w 0 -i ${annotated} >> "${b64file}"
      echo '"}' >> "${b64file}"
      jq -s add "${result}" "${b64file}" > "${result}.$$" && mv -f "${result}.$$" "${result}"
      rm -f ${b64file} ${annotated}
    fi
    rm -f "${JPEG}" "${OUT}"
  else
    hzn::log.error "${FUNCNAME[0]}: yolo failed:" $(cat ${err})
  fi

  echo "${result:-}"
}

yolo::annotate()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local json=${1}
  local jpeg=${2}
  local colors=(lime greenyellow yellow gold goldenrod orange darkorange coral orangered crimson red)
  local rtg=(FF0000 FF1100 FF2300 FF3400 FF4600 FF5700 FF6900 FF7B00 FF8C00 FF9E00 FFAF00 FFC100 FFD300 FFE400 FFF600 F7FF00 E5FF00 D4FF00 C2FF00 B0FF00 9FFF00 8DFF00 7CFF00 6AFF00 58FF00 47FF00 35FF00 24FF00 12FF00 00FF00)
  local nrtg=${#rtg[@]}

  local result

  if [ -s "${json}" ] && [ -s "${jpeg}" ]; then
    local length=$(jq '.results|length' ${json})
    yolos=

    if [ ${length:0} -gt 0 ]; then
      local i=0
      local count=0
      local sorted=$(jq '.results|sort_by(.confidence)|reverse' ${json})

      while [ ${i} -lt ${length} ]; do
        local yolo=$(echo "${sorted}" | jq '.['${i}']')
        local left=$(echo "${yolo:-null}" | jq -r '((.center.x - .width/2)|floor)')
        local top=$(echo "${yolo:-null}" | jq -r '((.center.y - .height/2)|floor)')
        local width=$(echo "${yolo:-null}" | jq -r '.width')
        local height=$(echo "${yolo:-null}" | jq -r '.height')
        local bottom=$((top+height))
        local right=$((left+width))
        local confidence=$(echo "${yolo:-null}" | jq -r '.confidence|floor')
        local entity=$(echo "${yolo:-null}" | jq -r '.entity')
        local display="${entity}: ${confidence}%"
        local pointsize=16

        if [ ${i} -eq 0 ]; then
          file=${jpeg%%.*}-${i}.jpg
          cp -f ${jpeg} ${file}
        else
          rm -f ${file}
          file=${output}
        fi
        output=${jpeg%%.*}-$((i+1)).jpg
        convert -font DejaVu-Sans-Mono -pointsize ${pointsize} -stroke ${colors[${count}]} -fill none -strokewidth 2 -draw "rectangle ${left},${top} ${right},${bottom} push graphic-context stroke ${colors[${count}]} fill ${colors[${count}]} translate ${left},$((top+pointsize/2)) text 3,6 '${display}' pop graphic-context" ${file} ${output}
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
        result=${jpeg%%.*}-yolo.jpg
        mv ${output} ${result}
      fi
    fi
  fi
  echo "${result:-null}"
}
