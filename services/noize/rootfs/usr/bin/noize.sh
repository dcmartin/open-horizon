#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/noize-tools.sh

###
### noise-detect.sh - create multiple WAV files named `noise###.wav`
###
### NOIZE_START_LEVEL - percentage change between silence and non-silence
### NOIZE_START_SECONDS - number of seconds of non-silence to start noiseing
### NOIZE_TRIM_DURATION - maximum length of sound in seconds; default 5
### NOIZE_SAMPLE_RATE - sampling rate; default: 19200
### NOIZE_THRESHOLD - use high-pass filter to remove sounds below threshold
###

if [ -z "${NOIZE_START_LEVEL:-}" ]; then NOIZE_START_LEVEL='1.0'; fi
if [ -z "${NOIZE_START_SECONDS:-}" ]; then NOIZE_START_SECONDS='0.1'; fi
if [ -z "${NOIZE_TRIM_DURATION:-}" ]; then NOIZE_TRIM_DURATION='5'; fi
if [ -z "${NOIZE_SAMPLE_RATE:-}" ]; then NOIZE_SAMPLE_RATE='19200'; fi
if [ -z "${NOIZE_MOCK:-}" ]; then NOIZE_MOCK=false; fi
if [ -z ${NOIZE_THRESHOLD:-} ]; then NOIZE_THRESHOLD=; fi

## test client
if [ -z "${NOIZE_CLIENT}" ]; then NOIZE_CLIENT=${HZN_CLIENT_ID:-$(hostname)}; fi

###
### MAIN
###

## initialize horizon
hzn_init

## configure service
SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
CONFIG='{"timestamp":"'$(date -u +%FT%TZ)'","tmpdir":"'${TMPDIR}'","logto":"'${LOGTO:-}'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"group":"'${NOIZE_GROUP}'","client":"'${NOIZE_CLIENT}'","start":{"level":'${NOIZE_START_LEVEL:-0}',"seconds":'${NOIZE_START_SECONDS:-0}'},"trim":{"duration":'${NOIZE_TRIM_DURATION:-0}'},"sample_rate":"'${NOIZE_SAMPLE_RATE:-60}'","threshold":"'${NOIZE_THRESHOLD:-none}'","threshold_tune":false,"level_tune":false,"services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## create temporary directory for noise output
DIR=${TMPDIR}/${0##*/}-output
mkdir -p ${DIR}
## default name of file
WAVNAME='noise'
PID=$(noize_detect_noise ${DIR}/${WAVNAME})
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- started noize_detect_noise; BFP=${DIR}/${WAVNAME}; PID: ${PID}" >> ${LOGTO} 2>&1; fi

## start watchdog for generating mock data (and re-starting detector ... at some point)
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- starting watchdog; PID: ${PID}; BFP: ${DIR}/${WAVNAME}" >> ${LOGTO} 2>&1; fi
WATCHDOG=$(noize_detect_watchdog ${PID} ${DIR}/${WAVNAME})
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- started watchdog; WATCHDOG: ${WATCHDOG}" >> ${LOGTO} 2>&1; fi

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"pid":'${PID:-0}',"watchdog":'${WATCHDOG:-0}'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- initialized service; output:" $(jq -c '.' ${OUTPUT_FILE}) >> ${LOGTO} 2>&1; fi

## FOREVER
while true; do

  # update service
  service_update ${OUTPUT_FILE}

  # wait (forever) on changes in ${DIR}
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- waiting on directory: ${DIR}" >> ${LOGTO} 2>&1; fi
  inotifywait -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- inotifywait ${FULLPATH}" >> ${LOGTO} 2>&1; fi
    if [ ! -z "${FULLPATH}" ]; then
      # assume not mock
      MOCK=
      # process updates
      case "${FULLPATH##*/}" in
        *.wav)
	  WAVFILE=${FULLPATH}
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- WAV file detected: ${WAVFILE}" >> ${LOGTO} 2>&1; fi
          # test for null payload
          if [ -s "${WAVFILE}" ]; then
            # test for mock
	    if [[ "${WAVFILE##*/}" =~ mock* ]]; then 
              MOCK=${WAVFILE##*/} && MOCK=${MOCK##*-} && MOCK=${MOCK%.*}
              if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- using mock: ${MOCK}" >> ${LOGTO} 2>&1; fi
            fi
	    # process wav into png
            PNGFILE=$(sox_spectrogram ${WAVFILE})
            if [ ! -z "${PNGFILE}" ] && [ -s "${PNGFILE}" ]; then
              if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- spectrogram created: ${PNGFILE}" >> ${LOGTO} 2>&1; fi
            else
	      echo "+++ WARN $0 $$ -- no spectrogram: ${PNGFILE}; removing: ${WAVFILE}; continuing..." >> ${LOGTO} 2>&1
	      rm -f ${WAVFILE} ${PNGFILE}
	      continue
            fi
          else
            echo "+++ WARN $0 $$ -- empty WAV file: ${WAVFILE}; removing and continuing..." >> ${LOGTO} 2>&1
            rm -f ${WAVFILE}
            continue
          fi
          ;;
        *)
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- non-WAV file: ${FULLPATH}" >> ${LOGTO} 2>&1; fi
	  continue
	  ;;
      esac
    else
      echo "+++ WARN $0 $$ -- empty path" >> ${LOGTO} 2>&1
      continue
    fi

    # test WAV
    if [ ! -s "${WAVFILE}" ]; then
      echo "*** ERROR $0 $$ -- no WAV file found: ${WAVFILE}" >> ${LOGTO} 2>&1
      continue
    fi
    # encode for transport
    base64 -w 0 ${WAVFILE} > ${WAVFILE}.b64

    # test spectrogram
    if [ ! -s "${PNGFILE}" ]; then
      echo "*** ERROR $0 $$ -- no spectrogram found: ${PNGFILE}" >> ${LOGTO} 2>&1
      continue
    fi
    base64 -w 0 ${PNGFILE} > ${PNGFILE}.b64

    ## START output
    echo '{"timestamp":"'$(date -u +%FT%TZ)'","date":'$(date +%s)',"client":"'${NOIZE_CLIENT}'"' > ${OUTPUT_FILE}
    if [ ! -z "${MOCK:-}" ]; then
      echo ',"mock":"'${MOCK}'"' >> ${OUTPUT_FILE}
    fi
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- initialized output: ${OUTPUT_FILE}" >> ${LOGTO} 2>&1; fi

    # do audio
    if [ "${NOIZE_INCLUDE_WAV:-}" != false ]; then
      echo ',' >> ${OUTPUT_FILE}
      echo -n '"'${WAVNAME}'":"' >> ${OUTPUT_FILE}
      cat ${WAVFILE}.b64 >> ${OUTPUT_FILE}
      echo '"' >> ${OUTPUT_FILE}
    fi

    # do spectrogram
    if [ "${NOIZE_INCLUDE_PNG:-}" != false ]; then
      echo ',' >> ${OUTPUT_FILE}
      echo -n '"spectrogram":"' >> ${OUTPUT_FILE}
      cat ${PNGFILE}.b64 >> ${OUTPUT_FILE}
      echo '"' >> ${OUTPUT_FILE}
    fi

    # close dict
    echo '}' >> ${OUTPUT_FILE}

    # cleanup
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- cleaning:" ${WAVFILE%.*}* >> ${LOGTO} 2>&1; fi
    rm -f ${WAVFILE%.*}*

    ## DONE output
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- created output: ${OUTPUT_FILE}" $(jq -c '.'${WAVNAME}'=(.'${WAVNAME}'!=null)|.spectrogram=(.spectrogram!=null)' ${OUTPUT_FILE}) >> ${LOGTO} 2>&1; fi

    # update output
    service_update "${OUTPUT_FILE}"
  done
done
