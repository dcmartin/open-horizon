#!/usr/bin/with-contenv /usr/bin/bashio

# ==============================================================================
set -o nounset  # Exit script on use of an undefined variable
set -o pipefail # Return exit status of the last command in the pipe that failed
set -o errexit  # Exit script when a command exits with non-zero status
set -o errtrace # Exit on error inside any functions or sub-shells

# ==============================================================================
# RUN LOGIC
# ------------------------------------------------------------------------------

main()
{
  bashio::log.debug "${FUNCNAME[0]}"
  local JSON
  local VALUE
  local PID

  # TIMEZONE
  VALUE=$(bashio::config "timezone")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE="GMT"; fi
  bashio::log.info "Setting timezone: ${VALUE}" >&2
  TIMEZONE=${VALUE}
  cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

  # PROJECT
  VALUE=$(bashio::config "project")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_PROJECT:-'MyProject'}; fi
  bashio::log.info "Setting project: ${VALUE}" >&2
  PROJECT=${VALUE}

  # HOST
  VALUE=$(bashio::config "host")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_HOST:-'0.0.0.0'}; fi
  bashio::log.info "Setting host: ${VALUE}" >&2
  HOST=${VALUE}

  # PORT
  VALUE=$(bashio::config "port")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_PORT:-'7998'}; fi
  bashio::log.info "Setting port: ${VALUE}" >&2
  PORT=${VALUE}

  # PROTOCOL
  VALUE=$(bashio::config "protocol")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_PROTOCOL:-'http://'}; fi
  bashio::log.info "Setting protocol: ${VALUE}" >&2
  PROTOCOL=${VALUE}

  # USERNAME
  VALUE=$(bashio::config "username")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_USERNAME:-'username'}; fi
  bashio::log.info "Setting username: ${VALUE}" >&2
  USERNAME=${VALUE}

  # PASSWORD
  VALUE=$(bashio::config "password")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_PASSWORD:-'password'}; fi
  bashio::log.info "Setting password: ${VALUE}" >&2
  PASSWORD=${VALUE}

  # INIT
  VALUE=$(bashio::config "init")
  if [ -z "${VALUE}" ] || [ "${VALUE}" == "null" ]; then VALUE=${LABELSTUDIO_INIT:-'--init'}; fi
  bashio::log.info "Setting init: ${VALUE}" >&2
  INIT=${VALUE}

  # START 
  JSON='{"log_level":"'$(bashio::config "log_level")'","hostname":"'"$(hostname)"'","arch":"'"$(arch)"'","date":'$(/bin/date +%s)
  # TIMEZONE
  JSON="${JSON}"',"timezone":"'"${TIMEZONE}"'"'
  # BODY
  JSON="${JSON}"',"labelstudio":{"directory":"'${LABEL_STUDIO}'","project":"'${PROJECT}'","host":"'${HOST}'","port":'${PORT}',"protocol":"'${PROTOCOL}'","username":"'${USERNAME}'","password":"'${PASSWORD}'","init":"'${INIT}'"}'
  # DONE
  JSON="${JSON}"'}'

  bashio::log.info "CONFIGURATION:" $(echo "${JSON}" | jq -c '.')

  cd ${LABEL_STUDIO} \
    && \
    label-studio start \
      --root-dir /data/labelstudio/ \
      --use-gevent \
      "${PROJECT}" \
      -b \
      --host "${HOST}" \
      --port "${PORT}" \
      --protocol "${PROTOCOL}" \
      --username "${USERNAME}" \
      --password "${PASSWORD}" \
      "${INIT}" &
  PID=$!

  bashio::log.info "Started; PID: ${PID}"

  # run forever
  while true; do
    sleep 120
    bashio::log.debug $(curl -sSL ${USERNAME}:${PASSWORD}@localhost:${PORT}/api/health)
    bashio::log.debug "Sleeping ..."
  done
}

main ${*}

# label-studio start 
# [-h] 
# [--version] 
# [-b] 
# [-d] 
# [--force]
# [--root-dir ROOT_DIR] [-v]
# [--template {image_keypoints,audio_trans_region,image_bbox,image_bbox_coco,adv_region_trans,image_mixedlabel,ts_loading_csv_notime,adv_nested_2level,html_video,text_multi_class,html_video_timeline,adv_nested_3level,ts_loading_json,ts_classification,ts_multi_step,adv_layouts_long_text,html_classification,adv_other_relations,text_classification,audio_transcribe,image_polygons,image_multi_class,text_named_entity,adv_text_classification,adv_layouts_sticky_left_column,text_summarization,ts_segmentation,html_website,adv_layouts_columns2,adv_nested_conditional,ts_rel_between_channels,adv_region_image,adv_layouts_sticky_header,adv_layouts_columns3,adv_other_pairwise,ts_loading_headless,html_document,image_classification,image_brushes,adv_other_filter,html_chatbot,text_alignment,ts_rel_text,adv_other_table2,html_pdf,audio_diarization,image_circular,text_taxonomy,audio_emotions,audio_classification,ts_loading_csv,adv_other_table,html_dialogues,adv_region_text}]
# [-c CONFIG_PATH] [-l LABEL_CONFIG] [-i INPUT_PATH]
# [-s {tasks-json,s3,gcs}] [--source-path SOURCE_PATH]
# [--source-params SOURCE_PARAMS]
# [-t {completions-dir,s3-completions,gcs-completions}]
# [--target-path TARGET_PATH]
# [--target-params TARGET_PARAMS]
# [--input-format {json,json-dir,text,text-dir,image-dir,audio-dir}]
# [-o OUTPUT_DIR]
# [--ml-backends ML_BACKENDS [ML_BACKENDS ...]]
# [--sampling {sequential,uniform}]
# [--log-level {DEBUG,INFO,WARNING,ERROR}]
# [--host HOST] [--protocol PROTOCOL] [-p PORT]
# [--cert CERT_FILE] [--key KEY_FILE]
# [--allow-serving-local-files] [--use-gevent]
# [--initial-project-description PROJECT_DESC]
# [--init] [--password PASSWORD] [--username USERNAME]
# project_name
# 
