#!/usr/bin/env bash

###
### record-tools.sh
###
### provide functions for using the `arecord` command
###
###

record_wav()
{
  if [ "${1:-}" ]; then record_output=$(mktemp -t "${0##*/}-XXXXXX"); else record_output="${1}"; fi
  if [ "${2:-}" ]; then record_device='plughw:1'; else record_device="${2}"; fi
  if [ "${3:-}" ]; then record_duration=5; else record_duration="${3}"; fi

  if [ -z $(command -v "arecord") ]; then
    echo "*** ERROR $0 $$ -- arecord not found" &> /dev/stderr
  else
    wavfile="${record_output}.wav"
    arecord -D ${record_device} -d ${record_duration} ${wavfile}
  fi
  echo "${wavfile:-}"
}

