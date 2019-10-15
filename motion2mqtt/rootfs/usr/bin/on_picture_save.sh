#!/bin/bash

source /usr/bin/motion-tools.sh

# 
# on_picture_save on_picture_save.sh %$ %v %f %n %K %L %i %J %D %N
#
# %Y = year, %m = month, %d = date,
# %H = hour, %M = minute, %S = second,
# %v = event, %q = frame number, %t = thread (camera) number,
# %D = changed pixels, %N = noise level,
# %i and %J = width and height of motion area,
# %K and %L = X and Y coordinates of motion center
# %C = value defined by text_event
# %f = filename with full path
# %n = number indicating filetype
# Both %f and %n are only defined for on_picture_save, on_movie_start and on_movie_end
#

###
### MAIN
###

hzn.log.trace "$0 $$ - started program"

# get arguments
CN="${1}"
EN="${2}"
IF="${3}"
IT="${4}"
MX="${5}"
MY="${6}"
MW="${7}"
MH="${8}"
SZ="${9}"
NL="${10}"

# image identifier, timestamp, seqno
ID=${IF##*/} && ID=${ID%.*}
TS=$(echo "${ID}" | sed 's/\(.*\)-.*-.*/\1/') 
SN=$(echo "${ID}" | sed 's/.*-..-\(.*\).*/\1/')
NOW=$($dateconv -i '%Y%m%d%H%M%S' -f "%s" "$TS")
MOTION_DEVICE=${MOTION_DEVICE:-$(hostname)}

hzn.log.debug "device: ${MOTION_DEVICE}; timestamp: ${TS}; now: ${NOW}"

## create JSON
IJ="${IF%.*}.json"
echo '{"device":"'${MOTION_DEVICE}'","camera":"'"${CN}"'","type":"jpeg","date":'"${NOW}"',"seqno":"'"${SN}"'","event":"'"${EN}"'","id":"'"${ID}"'","center":{"x":'"${MX}"',"y":'"${MY}"'},"width":'"${MW}"',"height":'"${MH}"',"size":'${SZ}',"noise":'${NL}'}' > "$IJ"

# post JSON
mqtt_pub -q 2 -r -t "$MOTION_GROUP/$MOTION_DEVICE/$CN/event/image" -f "$IJ"

if [ $(jq -r '.post_pictures' "$MOTION_JSON_FILE") = "on" ]; then
  # post JPEG
  mqtt_pub -q 2 -r -t "$MOTION_GROUP/$MOTION_DEVICE/$CN/image" -f "${IF}"
fi


hzn.log.trace "$0 $$ - completed program"
