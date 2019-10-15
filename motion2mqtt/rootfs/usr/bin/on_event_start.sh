#!/bin/bash

source /usr/bin/motion-tools.sh

#
# on_event_start.sh %$ %v %Y %m %d %H %M %S
#
# %$ - camera name
# %v - Event number. An event is a series of motion detections happening with less than 'gap' seconds between them. 
# %Y - The year as a decimal number including the century. 
# %m - The month as a decimal number (range 01 to 12). 
# %d - The day of the month as a decimal number (range 01 to 31).
# %H - The hour as a decimal number using a 24-hour clock (range 00 to 23)
# %M - The minute as a decimal number (range 00 to 59). >& /dev/stderr
# %S - The second as a decimal number (range 00 to 61). 
#

###
### MAIN
###

hzn.log.trace "started program"

CN="${1}"
EN="${2}"
YR="${3}"
MO="${4}"
DY="${5}"
HR="${6}"
MN="${7}"
SC="${8}"
TS="${YR}${MO}${DY}${HR}${MN}${SC}"

# get time
NOW=$($dateconv -i '%Y%m%d%H%M%S' -f "%s" "$TS")

hzn.log.debug "got timestamp: ${TS} and time: ${NOW}"

EJ="${MOTION_DATA_DIR}/${CN}/${TS}-${EN}.json"

hzn.log.debug "making event JSON: ${EJ}"

# make payload
MOTION_DEVICE=${MOTION_DEVICE:-$(hostname)}
echo '{"device":"'${MOTION_DEVICE}'","camera":"'${CN}'","event":"'${EN}'","start":'${NOW}'}' >! "${EJ}"

# `event/start`
mqtt_pub -q 2 -r -t "${MOTION_GROUP}/${MOTION_DEVICE}/${CN}/event/start" -f "$EJ"

hzn.log.trace "completed program"
