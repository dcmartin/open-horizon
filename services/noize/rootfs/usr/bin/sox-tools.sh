#!/usr/bin/env bash

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### sox-tools.sh
###
##
## sox_spectrogram()
## sox_record_wav()
## sox_detect_noise()
##

## make spectrogram
# fullpath to file filename (w/ extension)
sox_spectrogram()
{
  if [ ! -z "${1:-}" ]; then 
    sox_srcfile="${1}"
    sox_srcname="${sox_srcfile%.*}"
    sox_pngfile="${sox_srcname}.png"
    rm -f "${sox_pngfile}"
    if [ -s "${sox_srcfile}" ]; then
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- making spectrogram; src: ${sox_srcfile}; png: ${sox_pngfile}" >> ${LOGTO} 2>&1; fi
      sox "${sox_srcfile}" -n spectrogram -t "${sox_srcname##*/}" -o ${sox_pngfile}
    else
      if [ "${DEBUG:-}" = true ]; then echo "*** ERROR -- $0 $$ -- no WAV file found: ${sox_srcfile}" >> ${LOGTO} 2>&1; fi
    fi
    if [ ! -s "${sox_pngfile:-}" ]; then sox_pngfile=; fi
  fi
  echo "${sox_pngfile:-}"
}

## record sound of duration into file
# filename w/o extension (.wav appended); trim start (default 0); trim duration (default 5)
sox_record_wav()
{
  if [ -z "${1:-}" ]; then 
    if [ "${DEBUG}" = true ]; then echo "*** ERROR -- $0 $$ -- no output argument provided" >> ${LOGTO} 2>&1; fi
  else
    # set output
    sox_output="${1}"
    # test other arguments
    if [ -z "${2:-}" ]; then sox_trim_start='0'; fi
    if [ -z "${3:-}" ]; then sox_trim_duration='5'; fi
    if [ ! -z "${4:-}" ]; then sox_frequency_min="sinc ${4}"; fi
    if [ ! -z "${5:-}" ]; then sox_sample_rate='19200'; else sox_sample_rate=${5}; fi
    if [ ! -z "${6:-}" ]; then sox_audio_channels='1'; else sox_audio_channels=${6}; fi

    rec -c ${sox_audio_channels} \
	-r ${sox_sample_rate} \
	${sox_output}.wav \
	${sox_frequency_min:-} \
	trim ${sox_trim_start} ${sox_trim_duration} >> ${LOGTO} 2>&1
  fi
  echo "${sox_output:-}"
}

## sox_detect_noise()
# detect and record noise forever
# directory for output files; start percent (1.0); start seconds (0.1); finish percent (1.0; finish seconds (5.0)
# optional: minimum_frequency in Hz (or KHz w/ 'k' appended); sample rate: default 19200
# returns PID; kill to stop
sox_detect_noise()
{
  PID=0
  if [ -z "${1:-}" ]; then 
    if [ "${DEBUG}" = true ]; then echo "*** ERROR -- $0 $$ -- no directory argument provided" >> ${LOGTO} 2>&1; fi
  else
    sox_filepath="${1}"
    if [ -z "${2:-}" ]; then sox_start_level='1.0'; fi
    if [ -z "${3:-}" ]; then sox_start_seconds='0.1'; fi
    if [ -z "${5:-}" ]; then sox_trim_duration='5'; fi
    if [ ! -z "${6:-}" ]; then sox_frequency_min="sinc ${6}"; fi
    if [ ! -z "${7:-}" ]; then sox_sample_rate='19200'; else sox_sample_rate=${7}; fi
    if [ ! -z "${8:-}" ]; then sox_audio_channels='1'; else sox_audio_channels=${8}; fi

rec -c1 -r 192000 record.wav silence 1 0.1 1% trim 0 5 : newfile : restart

    # continuously record and create new WAV files in the specified directory
    rec -c ${sox_audio_channels:-1} \
	-r ${sox_sample_rate:-19200} \
	${sox_filepath}.wav \
	${sox_frequency_min:-} \
	silence 1 \
	${sox_start_seconds:-0.1} ${sox_start_level:-1}'%' \
	trim ${sox_trim_start:-0} ${sox_trim_duration:-5} \
	: newfile : restart >> ${LOGTO} 2>&1 &
    PID=$!
  fi
  echo "${PID}"
}
