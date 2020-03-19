#!/usr/bin/env bash

###
### MOTION tools
### 

MOTION_CONF_FILE="/etc/motion/motion.conf"

motion_init()
{
  # start motion
  DIR=/var/lib/motion
  TEMPDIR="${TMPDIR}/${0##*/}.$$/motion"
  rm -fr "${DIR}" "${TEMPDIR}"
  mkdir -p "${TEMPDIR}"
  ln -s "${TEMPDIR}" "${DIR}"
  # set configuration parameters
  if [ "${MOTION_THRESHOLD_TUNE:-}" == 'true' ]; then sed -i "s|.*threshold_tune.*|threshold_tune on|" "${MOTION_CONF_FILE}";fi
  if [ "${MOTION_NOISE_TUNE:-}" == 'true' ]; then sed -i "s|.*noise_tune.*|noise_tune on|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_THRESHOLD}" ]; then sed -i "s|.*threshold.*|threshold ${MOTION_THRESHOLD}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_NOISE_LEVEL}" ]; then sed -i "s|.*noise_level.*|noise_level ${MOTION_NOISE_LEVEL}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_EVENT_GAP}" ]; then sed -i "s|.*event_gap.*|event_gap ${MOTION_EVENT_GAP}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_LOG_LEVEL}" ]; then sed -i "s|.*log_level.*|log_level ${MOTION_LOG_LEVEL}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_LOG_TYPE}" ]; then sed -i "s|.*log_type.*|log_type ${MOTION_LOG_TYPE}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_FRAMERATE}" ]; then sed -i "s|.*framerate.*|framerate ${MOTION_FRAMERATE}|" "${MOTION_CONF_FILE}"; fi
  if [ ! -z "${MOTION_LOCATE_MODE}" ]; then 
    case ${MOTION_LOCATE_MODE} in
      off)
        sed -i "s|.*locate_motion_mode.*|locate_motion_mode off|" "${MOTION_CONF_FILE}" 
        ;;
      box|cross|redbox|redcross)
        sed -i "s|.*locate_motion_mode.*|locate_motion_mode on|" "${MOTION_CONF_FILE}"
        sed -i "s|.*locate_motion_style.*|locate_motion_style ${MOTION_LOCATE_MODE}|" "${MOTION_CONF_FILE}"
	;;
      *)
	if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN -- $0 $$ -- MOTION_LOCATE_MODE: ${MOTION_LOCATE_MODE}" &> /dev/stderr; fi
        ;;
    esac
  fi
}
