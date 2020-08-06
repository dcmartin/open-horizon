#!/usr/bin/with-contenv bashio

###
## UPDATE (write YAML)
###

## SOURCES

yolo4motion::update.sources.video()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local video="${*}"
  local name=$(echo "${video:-null}" | jq -r '.name')
  local type=$(echo "${video:-null}" | jq -r '.type')
  local uri=$(echo "${video:-null}" | jq -r '.uri')
  local live=$(echo "${video:-null}" | jq -r '.live')

  echo "  ${name}:"
  echo '    uri: '${uri}
  echo '    type: '${type}
  echo '    live: '${live}
}

yolo4motion::update.sources.audio()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::update.sources()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local sources="${*}"

  if [ "${sources:-null}" != 'null' ]; then
    local nsource=$(echo "${sources}" | jq '.|length')
    local i=0

    # START OUTPUT
    echo 'sources:'

    while [ ${i} -lt ${nsource} ]; do
      local source=$(echo "${sources}" | jq '.['${i}']')


      if [ "${source:-null}" != 'null' ]; then
        local type=$(echo "${source}" | jq -r '.type')

        hzn::log.debug "Source: ${source}"
        case "${type:-null}" in
          'video'|'image')
            hzn::log.debug "Source: ${i}; type: ${type}"
            yolo4motion::update.sources.video "${source}"
            ;;
          'audio')
            hzn::log.debug "Source: ${i}; type: ${type}"
            yolo4motion::update.sources.audio "${source}"
            ;;
          *)
            hzn::log.warning "Source: ${i}; invalid source type: ${type}"
            ;;
        esac
      fi
      i=$((i+1))
    done
  else
    hzn::log.error "No sources defined; configuration:" $(echo "${config:-null}" | jq '.')
  fi
}

## AI_MODELS

yolo4motion::update.ai_models.audio()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::update.ai_models.video()
{
  hzn::log.trace "${FUNCNAME[0]}"

  local model="${*}"
  local name=$(echo "${model:-null}" | jq -r '.name')
  local labels=$(echo "${model:-null}" | jq -r '.labels')
  local entity=$(echo "${model:-null}" | jq -r '.entity')
  local top_k=$(echo "${model:-null}" | jq -r '.top_k')
  local tflite=$(echo "${model:-null}" | jq -r '.tflite')

  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"

  local edgetpu="${TFLITE_ROOT:-}/ai_models/${tflite}_edgetpu.tflite"

  tflite="${TFLITE_ROOT:-}/ai_models/${tflite}.tflite"

  if [ -s "${tflite}" ] && [ -s "${edgetpu}" ]; then
    echo "  ${name}:"
    echo '    model:'
    echo "      tflite: ${tflite}"
    echo "      edgetpu: ${edgetpu}"

    if [ "${labels:-null}" != 'null' ]; then
      labels="${TFLITE_ROOT:-}/ai_models/${labels}_labels.txt"

      if [ ! -s "${labels}" ]; then
        hzn::log.warning "${FUNCNAME[0]}: labels specified; NOT FOUND; path: ${labels}"
      else
        hzn::log.debug "${FUNCNAME[0]}: labels specified; path: ${labels}"
      fi
      echo "    labels: ${labels}"
    else
      hzn::log.debug "${FUNCNAME[0]}: no labels specified"
    fi
    echo '    top_k: '${top_k:-1}
  else
    hzn::log.error "${FUNCNAME[0]}: model specified, but not found; tflite: ${tflite:-}; edgetpu: ${edgetpu:-}"
  fi
}

yolo4motion::update.ai_models()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local ai_models="${*}"

  if [ "${ai_models:-null}" != 'null' ]; then
    local nai_model=$(echo "${ai_models}" | jq '.|length')
    local i=0

    # START OUTPUT
    echo 'ai_models:'

    while [ ${i} -lt ${nai_model} ]; do
      local ai_model=$(echo "${ai_models}" | jq '.['${i}']')

      hzn::log.debug "ai_model: ${i}" $(echo "${ai_model:-null}" | jq '.')

      if [ "${ai_model:-null}" != 'null' ]; then
        local type=$(echo "${ai_model}" | jq -r '.type')
        local src='null'

        case "${type:-null}" in
          'video')
            yolo4motion::update.ai_models.video "${ai_model}"
            ;;
          'audio')
            yolo4motion::update.ai_models.audio "${ai_model}"
            ;;
          *)
            hzn::log.warning "Invalid ai_model type: ${type}"
            ;;
        esac
      fi
      i=$((i+1))
    done
  else
    hzn::log.error "No ai_models defined; configuration:" $(echo "${config:-null}" | jq '.')
  fi
}

## PIPELINES

yolo4motion::update.pipelines.audio()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::update.pipelines.video.send()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::update.pipelines.video.detect()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local act="${*}"
  local ai_model=$(echo "${act:-null}" | jq -r '.ai_model')
  local entity=$(echo "${act:-null}" | jq -r '.entity')
  local confidence=$(echo "${act:-null}" | jq -r '.confidence')

  case "${entity:-null}" in
    'object')
      hzn::log.debug "ai_model: ${ai_model}; entity: ${entity}; confidence: ${confidence}"
      echo '    - detect_objects:'
      echo '        ai_model: '${ai_model}
      echo '        confidence_threshold: '${confidence}
      ;;
    'face')
      hzn::log.debug "ai_model: ${ai_model}; entity: ${entity}; confidence: ${confidence}"
      echo '    - detect_faces:'
      echo '        ai_model: '${ai_model}
      echo '        confidence_threshold: '${confidence}
      ;;
    *)
      hzn::log.warning "Action: ${name}; invalid entity: ${entity}"
      ;;
  esac
}

yolo4motion::update.pipelines.video.save()
{
  hzn::log.debug "${FUNCNAME[0]} ${*}"

  local act="${*}"
  local interval=$(echo "${act:-null}" | jq -r '.interval')
  local idle=$(echo "${act:-null}" | jq -r '.idle')

  echo '    - save_detections:'
  echo '        positive_interval: '${interval}
  echo '        idle_interval: '${idle}
}

yolo4motion::update.pipelines.video()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local pipeline="${*}"
  local name=$(echo "${pipeline:-null}" | jq -r '.name')
  local actions=$(echo "${pipeline:-null}" | jq '.actions')
  local source=$(echo "${pipeline:-null}" | jq -r '.source')
  local naction=$(echo "${actions:-null}" | jq '.|length')

  if [ ! -z "${name:-}" ] && [ ! -z "${source:-}" ] && [ "${actions:-null}" != 'null' ]; then
    local i=0

    hzn::log.debug "Pipeline: ${name}; source: ${source}; actions: ${naction}"

    # start output
    echo '  '${name}':'
    echo '    - source: '${source}

    while [ ${i} -lt ${naction} ]; do
      local action=$(echo "${actions}" | jq '.['${i}']')

      if [ "${action:-null}" != 'null' ]; then
        local act=$(echo "${action}" | jq -r '.act')

        hzn::log.debug "Pipeline: ${name}; action ${i}; act: ${act}"

        case "${act:-null}" in
          'detect')
            hzn::log.debug "Action: ${i}; act: ${action}"
            yolo4motion::update.pipelines.video.detect "${action}"
            ;;
          'save')
            hzn::log.debug "Action: ${i}; act: ${action}"
            yolo4motion::update.pipelines.video.save "${action}"
            ;;
          'send')
            hzn::log.debug "Action: ${i}; act: ${act}"
            yolo4motion::update.pipelines.video.send "${action}"
            ;;
          *)
            hzn::log.warning "Action: ${i}; invalid act: ${act}"
            ;;
        esac
      else
        hzn::log.error "Invalid action: ${action}"
      fi
      i=$((i+1))
    done
  else
    hzn::log.error "Invalid pipeline: ${pipeline}"
  fi
}

yolo4motion::update.pipelines()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local pipelines="${*}"

  if [ "${pipelines:-null}" != 'null' ]; then
    local npipeline=$(echo "${pipelines}" | jq '.|length')
    local i=0

    # START OUTPUT
    echo 'pipelines:'

    while [ ${i} -lt ${npipeline} ]; do
      local pipeline=$(echo "${pipelines}" | jq '.['${i}']')

      if [ "${pipeline:-null}" != 'null' ]; then
        local type=$(echo "${pipeline}" | jq -r '.type')

        case "${type:-null}" in
          'video')
            hzn::log.debug "Pipeline: ${i}; type: ${type}"
            yolo4motion::update.pipelines.video "${pipeline}"
            ;;
          'audio')
            hzn::log.debug "Pipeline: ${i}; type: ${type}"
            yolo4motion::update.pipelines.audio "${pipeline}"
            ;;
          *)
            hzn::log.warning "Pipeline: ${i}; invalid pipline type: ${type}"
            ;;
        esac
      fi
      i=$((i+1))
    done
  else
    hzn::log.notice "No pipelines defined; configuration:" $(echo "${config:-null}" | jq '.')
  fi
}

yolo4motion::update()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config="${*}"
  local result

  # sources
  yolo4motion::update.sources $(echo "${config}" | jq '.sources') >> ${yolo4motion}

  # ai_models
  yolo4motion::update.ai_models $(echo "${config}" | jq '.ai_models') >> ${yolo4motion}

  # pipelines
  yolo4motion::update.pipelines $(echo "${config}" | jq '.pipelines') >> ${yolo4motion}

  result='{"logging":"'${logging:-}'","log_level":"'$(hzn::log.level)'","path":"'${yolo4motion:-}'"}'

  echo ${result:-null}
}

###
## CONFIGURE (read JSON)
###

## SOURCES

yolo4motion::config.sources.audio()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::config.sources.video()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local source="${*}"
  local result
  local name=$(echo "${source:-null}" | jq -r '.name')

  if [ "${name:-null}" != 'null' ]; then
    hzn::log.debug "Name: ${name}"
    local uri=$(echo "${source:-null}" | jq -r '.uri')
    if [ "${uri:-null}" != 'null' ]; then
      hzn::log.debug "URI: ${uri}"
      local type=$(echo "${source:-null}" | jq -r '.type')
      if [ "${type:-null}" != 'null' ]; then
        hzn::log.debug "Type: ${type}"
        local live=$(echo "${source:-null}" | jq '.live')
        if [ "${live:-null}" != 'null' ]; then
          hzn::log.debug "Live: ${live}"

          result='{"name":"'${name}'","uri":"'${uri}'","type":"'${type}'","live":'${live}'}'

          hzn::log.debug "source: ${result}"
        else
          hzn::log.error "Live unspecified: ${source}"
        fi
      else
        hzn::log.error  "Type unspecified: ${source}"
      fi
    else
      hzn::log.error  "URI unspecified: ${source}"
    fi
  else
    hzn::log.error  "Name unspecified: ${source}"
  fi
  echo ${result:-null}
}

yolo4motion::config.sources()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"
  
  local sources=$(jq '.sources' ${__BASHIO_DEFAULT_ADDON_CONFIG})
  local result
  local srcs

  if [ "${sources:-null}" != 'null' ]; then
    local nsource=$(echo "${sources}" | jq '.|length')
    local i=0
    local j=0

    while [ ${i} -lt ${nsource} ]; do
      local source=$(echo "${sources}" | jq '.['${i}']')
      local type=$(echo "${source}" | jq -r '.type')
      local src

      case "${type:-null}" in
        'video'|'image')
          src=$(yolo4motion::config.sources.video "${source}")
          ;;
        'audio')
          src=$(yolo4motion::config.sources.audio "${source}")
          ;;
        *)
          hzn::log.warning "Invalid source type: ${type}"
          ;;
      esac
      if [ "${src:-null}" = 'null' ]; then
        hzn::log.warning "Source ${i}; type: ${type}; no source"
      else
        hzn::log.debug "Source ${i}; type: ${type}; source: ${src}"
        if [ ${j} -gt 0 ]; then srcs="${srcs},"; else srcs='['; fi
        srcs="${srcs}${src}"
        j=$((j+1))
      fi
      i=$((i+1))
    done
    if [ ! -z "${srcs:-}" ]; then srcs="${srcs}]"; else srcs='null'; fi
    hzn::log.debug "Sources: ${srcs}"
    result=${srcs}
  else
    hzn::log.notice "No sources defined"
  fi
  echo ${result:-null}
}

## AI_MODELS

yolo4motion::config.ai_models.audio()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::config.ai_models.video()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local model="${*}"
  local name=$(echo "${model:-null}" | jq -r '.name')
  local entity=$(echo "${model:-null}" | jq -r '.entity')
  local result

  if [ "${name:-null}" != 'null' ] && [ "${entity:-null}" != 'null' ]; then
    local tflite=$(echo "${model:-null}" | jq -r '.tflite')
    if [ "${tflite:-null}" = 'null' ]; then
      hzn::log.error "EdgeTPU and/or TFlite model unspecified: ${model}"
    else
      local labels=$(echo "${model:-null}" | jq -r '.labels')
      if [ "${labels:-null}" = 'null' ]; then
        hzn::log.debug "Labels unspecified: ${model}"
        labels='"labels":null'
      else 
        labels='"labels":"'${labels}'"'
      fi
      local top_k=$(echo "${model:-null}" | jq -r '.top_k')
      if [ "${top_k:-null}" = 'null' ]; then
        hzn::log.debug "top_k unspecified: ${model}"
        top_k='null'
      fi
      result='{"type":"video","entity":"'${entity}'","name":"'${name}'",'${labels:-}',"top_k":'${top_k}',"tflite":"'${tflite}'"}'
      hzn::log.debug "ai_model: ${result}"
    fi
  else
    hzn::log.error  "Name and/or entity unspecified: ${model}"
  fi
  echo ${result:-null}
}

yolo4motion::config.ai_models()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local ai_models=$(jq '.ai_models' ${__BASHIO_DEFAULT_ADDON_CONFIG})
  local result
  local models='['

  if [ "${ai_models:-null}" != 'null' ]; then
    local nmodel=$(echo "${ai_models}" | jq '.|length')
    local i=0
    local j=0

    while [ ${i:-0} -lt ${nmodel:-0} ]; do
      local model=$(echo "${ai_models}" | jq '.['${i}']')
      local type=$(echo "${model}" | jq -r '.type')
      local model

      case "${type:-null}" in
        'video')
          hzn::log.debug "ai_model ${i}; type: ${type}"
          model=$(yolo4motion::config.ai_models.video "${model}")
          ;;
        'audio')
          hzn::log.debug "ai_model ${i}; type: ${type}"
          model=$(yolo4motion::config.ai_models.audio "${model}")
          ;;
        *)
          hzn::log.warning "ai_model ${i}; invalid type: ${type}"
          ;;
      esac
      if [ "${model:-null}" = 'null' ]; then
        hzn::log.warning "FAILED to configure ai_model ${i}: ${model}"
      else
        hzn::log.debug "Configured ai_model ${i}: ${model}"
        if [ ${j} -gt 0 ]; then models="${models},"; fi
        models="${models}${model}"
        j=$((j+1))
      fi
      i=$((i+1))
    done
    models="${models}]"
    hzn::log.debug "AI Models: ${models}"
    result=${models}
  else
    hzn::log.notice "No ai_models defined"
  fi
  echo ${result:-null}
}

## PIPELINES

yolo4motion::config.pipelines.audio()
{
  hzn::log.warning "NOT IMPLEMENTED" "${FUNCNAME[0]}" "${*}"
}

yolo4motion::config.pipelines.video()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local action="${*}"
  local name=$(echo "${action:-null}" | jq -r '.name')
  local act=$(echo "${action:-null}" | jq -r '.act')
  local result

  case "${act:-null}" in
    'detect')
      # test for all detect attributes
      hzn::log.debug "Action: ${name}; act: ${act}"
      result=$(echo "${action}" | jq '{"act":.act,"type":.type,"entity":.entity,"ai_model":.ai_model,"confidence":.confidence}')
      ;;
    'save')
      # test for all save attributes
      hzn::log.debug "Action: ${name}; act: ${act}"
      result=$(echo "${action}" | jq '{"act":.act,"type":.type,"entity":.entity,"interval":.interval,"idle":.idle}')
      ;;
    *)
      hzn::log.warning "Action: ${name}; invalid act: ${act}"
      ;;
  esac
  echo ${result:-null}
}

yolo4motion::config.pipelines()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local pipelines=$(jq '.pipelines' ${__BASHIO_DEFAULT_ADDON_CONFIG})

  hzn::log.trace "pipelines:" $(echo "${pipelines:-null}" | jq '.')

  local result
  local ppls='['

 if [ "${pipelines:-null}" != 'null' ]; then
    local pplnames=$(echo "${pipelines}" | jq -r '.[].name' | sort | uniq)
    local ppls='['
    local k=0
    local type='null'

    hzn::log.debug "Pipeline names: ${pplnames}"

    for pplname in ${pplnames:-}; do
      hzn::log.debug "Pipeline: ${pplname}"
      local steps=$(echo "${pipelines}" | jq '[.[]|select(.name=="'${pplname}'")]')
      local acts=''
      local i=0
      local j=0
      local source

      # should be unique
      local action_names=$(echo "${steps:-null}" | jq -r '.[].action')
      local all_actions=$(jq '.actions' ${__BASHIO_DEFAULT_ADDON_CONFIG})

      hzn::log.debug "Pipeline: ${pplname}; actions: ${action_names}"

      for an in ${action_names}; do
        local action=$(echo "${all_actions}" | jq '.[]|select(.name=="'${an}'")')
        local src=$(echo "${steps:-null}" | jq -r '.['${i}'].source')
        local act='null'

        type=$(echo "${action}" | jq -r '.type')

        case "${type:-null}" in
          'video')
            act=$(yolo4motion::config.pipelines.video "${action}")
            hzn::log.debug "Pipeline ${k}: ${pplname}; action: ${an}; type: ${type}"
            ;;
          'audio')
            hzn::log.debug "Pipeline ${k}: ${pplname}; action: ${an}; type: ${type}"
            act=$(yolo4motion::config.pipelines.audio "${action}")
            ;;
          *)
            hzn::log.warning "Invalid pipeline type: ${type}"
            ;;
        esac
        if [ "${act:-null}" = 'null' ]; then
          hzn::log.warning "FAILED: Pipeline ${k}: ${pplname}; action ${i}: ${an}"
        else
          if [ "${src:-null}" != 'null' ]; then
            hzn::log.debug "Pipeline ${k}: ${pplname}; action ${i}: ${an}; source: ${src}"
            source="${src}"
#            act=$(echo "${act:-null}" | jq '.source="'${source}'"')
          else
            hzn::log.debug "Pipeline ${k}: ${pplname}; action ${i}: ${an}; no source"
          fi 
          hzn::log.debug "Pipeline ${k}: ${pplname}; action ${i}: ${an}; adding ${j}:" $(echo "${act}" | jq '.')
          if [ ${j} -gt 0 ]; then acts="${acts},"; else acts='['; fi
          acts="${acts}${act}"
          j=$((j+1))
        fi
        i=$((i+1))
      done
      if [ ${j} -gt 0 ]; then 
        acts="${acts}]"
      else
        hzn::log.warning "Pipeline ${k}: ${pplname}; no actions"
        acts='null'
      fi

      local ppl='{"name":"'${pplname}'","type":"'${type:-null}'","source":"'${source}'","actions":'"${acts:-null}"'}'

      hzn::log.debug "Configured pipeline:" $(echo "${ppl}" | jq '.')

      if [ ${k} -gt 0 ]; then ppls="${ppls},"; fi
      ppls="${ppls}${ppl}"
      k=$((k+1))
    done
    ppls="${ppls}]"
    result="${ppls}"
  else
    hzn::log.notice "No pipelines defined"
  fi
  echo "${result:-null}"
}

## configuration

yolo4motion::config.mqtt()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config="${*}"
  local mqtt 
  local value

  # host
  value=$(hzn::option 'mqtt.host')
  if [ "${value}" == "null" ] || [ -z "${value}" ]; then value="localhost"; fi
  hzn::log.info "Using mqtt at ${value}"
  mqtt='{"host":"'"${value}"'"'
  # username
  value=$(hzn::option 'mqtt.username')
  if [ "${value}" == "null" ] || [ -z "${value}" ]; then value="username"; fi
  hzn::log.info "Using mqtt username: ${value}"
  mqtt="${mqtt}"',"username":"'"${value}"'"'
  # password
  value=$(hzn::option 'mqtt.password')
  if [ "${value}" == "null" ] || [ -z "${value}" ]; then value="password"; fi
  hzn::log.info "Using mqtt password: ${value}"
  mqtt="${mqtt}"',"password":"'"${value}"'"'
  # port
  value=$(hzn::option 'mqtt.port')
  if [ "${value}" == "null" ] || [ -z "${value}" ]; then value=1883; fi
  hzn::log.info "Using mqtt port: ${value}"
  mqtt="${mqtt}"',"port":'"${value}"'}'
  
  echo "${mqtt:-null}"
}

###
## CONFIGURATION (read JSON)
###

yolo4motion::config()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local config='{"ipaddr":"'$(hostname -I | awk '{ print $1 }')'","hostname":"'$(hostname)'","arch":"'$(arch)'","timestamp":"'$(date -u +%FT%TZ)'","version":"'${AMBIANIC_VERSION}'"}'
  local timezone=$(hzn::option 'timezone')
  local workspace=$(hzn::option 'workspace')
  local result

  if [ -z "${timezone:-}" ] || [ "${timezone:-null}" == "null" ]; then 
    timezone="GMT"
    hzn::log.warning "timezone unspecified; defaulting to ${timezone}"
  fi
  if [ -s "/usr/share/zoneinfo/${timezone:-null}" ]; then
    cp /usr/share/zoneinfo/${timezone} /etc/localtime
    echo "${timezone}" > /etc/timezone
    hzn::log.info "TIMEZONE: ${timezone}"
  else
    hzn::log.error "No known timezone: ${timezone}"
  fi
  config=$(echo "${config:-null}" | jq '.timezone="'${timezone}'"')
  
  if [ "${workspace:-null}" != 'null' ]; then
    mkdir -p "${workspace}"
    if [ -d "${workspace}" ]; then
      hzn::log.info "Workspace: ${workspace}"

      config=$(echo "${config:-null}" | jq '.workspace="'${workspace}'"')
      local ok

      # configure ai_models
      ok=$(yolo4motion::config.ai_models)
      if [ "${ok:-null}" != 'null' ]; then
        hzn::log.debug "AI Models configured:" $(echo "${ok}" | jq '.') 
        # record in configuration
        config=$(echo "${config:-null}" | jq '.ai_models='"${ok}")

        # configure sources
        ok=$(yolo4motion::config.sources)
        if [ "${ok:-null}"  != 'null' ]; then
          hzn::log.debug "Sources configured:" $(echo "${ok}" | jq '.') 
          # record in configuration
          config=$(echo "${config:-null}" | jq '.sources='"${ok}")

          # configure pipelines
          ok=$(yolo4motion::config.pipelines)
          if [ "${ok:-null}" != 'null' ]; then
            # record in configuration
            config=$(echo "${config:-null}" | jq '.pipelines='"${ok}")
            # success
            result="${config}"
          else
            hzn::log.error "Failed to configure pipelines"
          fi
        else
          hzn::log.error "Failed to configure sources"
        fi
      else
        hzn::log.error "Failed to configure ai_models"
      fi
    else
      hzn::log.error "Failed to create workspace directory: ${workspace}"
    fi
  else
    hzn::log.error "YOLO4motion workspace is not defined"
  fi
  echo "${result:-null}"
}

###
## START
###

## start.proxy
yolo4motion::start.proxy()
{
  hzn::log.trace "${FUNCNAME[0]}" "${*}"

  local result
  local ok
  local proxy=${1:-peerjs.ext.http-proxy}
  local t=$(mktemp)

  python3 -m  ${proxy} &> ${t} &
  ok=$!; if [ ${ok:-0} -gt 0 ]; then
    hzn::log.debug "PeerJS proxy started; pid: ${ok}"
    result='{"proxy":"'${proxy}'","pid":'${ok}',"out":"'${t}'"}'
  else 
    hzn::log.error "PeerJS proxy failed to start" $(cat ${t})
    rm -f ${t}
  fi
  echo ${result:-null}
}

## start.yolo4motion
yolo4motion::start.yolo4motion()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config="${config:-null}"
  local update 
  local result

  if [ "${config:-null}" != 'null' ]; then
    # update YAML
    update=$(yolo4motion::update "${config}")
    if [ "${update:-null}" != 'null' ]; then 
      local yolo4motion=$(echo "${update}" | jq -r '.path')

      if [ ! -z "${yolo4motion:-}" ] && [ -e "${yolo4motion}" ]; then
        hzn::log.debug "${FUNCNAME[0]}: configuration YAML: ${yolo4motion}"
        local workspace=$(echo "${config}" | jq -r '.workspace')

        if [ -d "${workspace:-null}" ]; then
          hzn::log.debug "${FUNCNAME[0]}: workspace: ${workspace}"
          local t=$(mktemp)
          local pid

          # change to working directory
          pushd ${workspace} &> /dev/null
          # start python3
          #export AMBIANIC_DIR=${workspace}
          #export DEFAULT_DATA_DIR=${workspace}
	  python3 -m yolo4motion &> ${t} &
          # test
          pid=$!; if [ ${pid:-0} -gt 0 ]; then
            hzn::log.debug "${FUNCNAME[0]}: started; pid: ${pid}"
            result='{"config":'"${update}"',"pid":'${pid}',"out":"'${t}'"}'
          else
            hzn::log.error "${FUNCNAME[0]}: failed to start"
            rm -f ${t}
          fi
          # return
          popd &> /dev/null
        else
          hzn::log.error "${FUNCNAME[0]}: no workspace directory: ${workspace:-}"
        fi
      else
        hzn::log.error "${FUNCNAME[0]}: no configuration file: ${yolo4motion:-}"
      fi
    else
      hzn::log.error "${FUNCNAME[0]}: update failed"
    fi
  else
    hzn::log.error "${FUNCNAME[0]}: no configuration"
  fi
  echo "${result:-null}"
}

## start all
yolo4motion::start()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"

  local config="${*}"
  local result

  if [ "${config:-null}" != 'null' ]; then
    local ok
    # start yolo4motion
    ok=$(yolo4motion::start.yolo4motion "${config}")
    if [ "${ok:-null}" != 'null' ]; then
      hzn::log.info "${FUNCNAME[0]}: yolo4motion started:" $(echo "${ok}" | jq '.') 
      # update config
      config=$(echo "${config:-null}" | jq '.yolo4motion='"${ok}")
      # start proxy
      ok=$(yolo4motion::start.proxy)
      if [ "${ok:-null}" != 'null' ]; then
        hzn::log.info "${FUNCNAME[0]}: Proxy started:" $(echo "${ok}" | jq '.') 
        # update config
        result=$(echo "${config:-null}" | jq '.proxy='"${ok}")
      else 
        hzn::log.error "${FUNCNAME[0]}: Proxy failed to start"
      fi
    else 
      hzn::log.error "${FUNCNAME[0]}: YOLO4motion failed to start: ${ok}"
    fi
  else 
    hzn::log.error "${FUNCNAME[0]}: No configuration"
  fi
  echo ${result:-null}
}

###
# process options
###

yolo4motion::options()
{
  hzn::log.trace "${FUNCNAME[0]} ${*}"
  local tailen=${LOG_TAIL:-100}
  local config

  hzn::log.info "Configuring yolo4motion ..."
  config=$(yolo4motion::config)

  if [ "${config:-null}" != 'null' ]; then
    hzn::log.notice "${FUNCNAME[0]}: YOLO4motion configured:" $(echo "${config}" | jq '.')

    local out
    local pid
    local result=$(yolo4motion::start ${config})

    # record for posterity
    echo "${result}" | jq '.' > "/var/run/yolo4motion.json"

    hzn::log.debug "${FUNCNAME[0]}: yolo4motion::start result: ${result}"

    pid=$(echo "${result:-null}" | jq -r '.yolo4motion.pid')

    while true; do
      pid=$(echo "${result:-null}" | jq -r '.yolo4motion.pid')
 
      if [ "${pid:-null}" != 'null' ]; then
        local this=$(ps --pid ${pid} | tail +2 | awk '{ print $1 }')
  
        if [ "${this:-null}" == "${pid}" ]; then
          hzn::log.notice "${FUNCNAME[0]}: YOLO4motion PID: ${this}; running"

          out=$(echo "${result}" | jq -r '.yolo4motion.out')
          if [ -s "${out:-null}" ]; then 
            hzn::log.green "${FUNCNAME[0]}: OUTPUT: ${out}"
	    tail -${tailen}  "${out}" >&2
          else 
            hzn::log.info "${FUNCNAME[0]}: yolo4motion output empty: ${out}"
          fi

          out=$(echo "${result}" | jq -r '.workspace')/yolo4motion-log.txt
          if [ -s "${out:-null}" ]; then 
            hzn::log.green "${FUNCNAME[0]}: LOG: ${out}"
	    tail -${tailen} "${out}" >&2
          else 
            hzn::log.info "${FUNCNAME[0]}: empty output: ${out}"
          fi

          out=$(echo "${result}" | jq -r '.proxy.out')
          if [ -s "${out:-null}" ]; then 
            hzn::log.green "${FUNCNAME[0]}: PERRJS OUTPUT: ${out}"
	    tail -${tailen} "${out}" >&2
          else 
            hzn::log.info "${FUNCNAME[0]}: proxy output empty: ${out}"
          fi

          hzn::log.info "${FUNCNAME[0]}: watchdog sleeping for ${WATCHDOG_SECONDS:-30} seconds..."
          sleep ${WATCHDOG_SECONDS:-30}
        else
          hzn::log.warning "${FUNCNAME[0]}: YOLO4motion PID: ${pid}; not running"

          # configuration debugging
          out=$(echo "${result}" | jq -r '.yolo4motion.config.path')
          echo "YOLO4motion configuation YAML: ${out}" >&2
          if [ -e "${out}" ]; then cat "${out}" >&2; else echo "No file: ${out}" >&2; fi
  
          # cleanup yolo4motion
          out=$(echo "${result}" | jq -r '.yolo4motion.out')
          echo "YOLO4motion log: ${out}" >&2
          if [ -e "${out}" ]; then cat "${out}" >&2; else echo "No file: ${out}" >&2; fi
          rm -f "${out}"

          # cleanup proxy
          out=$(echo "${result}" | jq -r '.proxy.out')
          echo "Proxy log: ${out}" >&2
          if [ -e "${out}" ]; then cat "${out}" >&2; else echo "No file: ${out}" >&2; fi
          kill -9 $(echo "${result}" | jq -r '.proxy.pid')
          rm -f ${out}

	  # restart yolo4motion
          result=$(yolo4motion::start ${config})
	  
	  # record for posterity
	  echo "${result}" | jq '.' > "/var/run/yolo4motion.json"
        fi
      else
        hzn::log.error "${FUNCNAME[0]}: YOLO4motion failed to start"
        break
      fi
    done
  else
    hzn::log.error "${FUNCNAME[0]}: YOLO4motion configuration failed"
  fi
}
