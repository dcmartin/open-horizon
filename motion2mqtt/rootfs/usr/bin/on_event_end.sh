#!/bin/tcsh

if ( -d "/tmpfs" ) then 
  set TMPDIR = "/tmpfs"
else
  set TMPDIR = "/tmp"
endif 

set tmpdir = "${TMPDIR}/$0:t/$$."`date +%s`
mkdir -p "${tmpdir}"

unsetenv DEBUG
unsetenv DEBUG_MQTT

if ($?DEBUG) then
  set message = ( "START" `date` )
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

## REQUIRES date utilities
if ( -e /usr/bin/dateutils.dconv ) then
   set dateconv = /usr/bin/dateutils.dconv
else if ( -e /usr/bin/dateconv ) then
   set dateconv = /usr/bin/dateconv
else if ( -e /usr/local/bin/dateconv ) then
   set dateconv = /usr/local/bin/dateconv
else
  if ($?DEBUG) then
    set message = "no dateutils(1) found; exiting"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  # quit
  goto done
endif

## ARGUMENTS
#
# on_event_end.sh %$ %v %Y %m %d %H %M %S
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

set CN = "$1"
set EN = "$2"
set YR = "$3"
set MO = "$4"
set DY = "$5"
set HR = "$6"
set MN = "$7"
set SC = "$8"
set TS = "${YR}${MO}${DY}${HR}${MN}${SC}"

# in seconds
if ($#TS && "$TS" != "") then
  set NOW = `$dateconv -i '%Y%m%d%H%M%S' -f "%s" "${TS}"`
else
  goto done
endif

set dir = "/var/lib/motion"

##
## find all images during event
##

# find all event jsons (YYYYMMDDHHMMSS-##.json)
set jsons = ( `echo "$dir"/??????????????"-${EN}".json` )

if ($?DEBUG) then
  set message = "processing directory: ${dir}; camera: ${CN}; event: ${EN}; events: $#jsons"
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

# find event start
if ($#jsons) then
  set EVENT_JSON = $jsons[$#jsons]
  if (! -s "$EVENT_JSON") then
    if ($?DEBUG) then
      set message = "cannot find last JSON ${EVENT_JSON}; exiting"
      echo "$0:t $$ -- $message" >& /dev/stderr
      if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
    endif
    goto done
  else
    set START = `jq -r '.start' $EVENT_JSON`
  endif
  set jpgs = ( `echo "${dir}"/*"-${EN}-"*.jpg` )
else
  if ($?DEBUG) then
    set message = "found no events; exiting"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  goto done
endif

if ($?DEBUG) then
  set message = "found $#jpgs candidate images for camera $CN in $dir for event $EN"
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

## process frames

set frames = ()
set elapsed = 0
if ($#jpgs) then
  @ i = $#jpgs
  while ($i > 0) 
    set jpg = "$jpgs[$i]"
    set jsn = "$jpg:r.json"
    if ( ! -s "$jsn" ) then
      if ($?DEBUG) then
	set message = "cannot locate JSON $jsn for camera $CN image $jpg; skipping.."
	echo "$0:t $$ -- $message" >& /dev/stderr
	if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
      endif
      @ i--
      continue
    endif
    set THIS = `echo "$jpg:t:r" | sed 's/\(.*\)-.*-.*/\1/'`
    set THIS = `$dateconv -i '%Y%m%d%H%M%S' -f "%s" $THIS`
    if ($?LAST == 0) set LAST = $THIS
    @ seconds = $THIS - $START
    # test for breaking conditions
    if ( $seconds < 0 ) break
    # add frame to this interval
    set frames = ( "$jpg:t:r" $frames )
    if ( $seconds > $elapsed ) set elapsed = $seconds
    @ i--
  end
else
  if ($?DEBUG) then
    set message = "no candidate images ($#jpgs) found for camera $CN; date $NOW; exiting"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  goto done
endif

if ($?DEBUG) then
  set message = "found $#frames frames for camera $CN at date $NOW elapsed $elapsed"
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

###
### PROCESS 
###

set jpgs = ()
set maxjpgsz = 0
foreach f ( $frames )
  set jpg = "$dir/$f.jpg" 
  if (-e "$jpg:r.json") then
    set jpgsz = ( `jq -r '.size' "$jpg:r.json"` )
    if ( $jpgsz > $maxjpgsz ) then
      set maxjpgsz = $jpgsz
      set BESTJPG = $jpg
    endif
    set jpgs = ( $jpgs "$jpg" )
  else
    if ($?DEBUG) then
      set message = "failed to find JSON $jpg:r.json; skipped"
      echo "$0:t $$ -- $message" >& /dev/stderr
      if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
    endif
  endif
end

## test quantity
if ($#jpgs < 1) then
  if ($?DEBUG) then
    set message = "insufficient ($#jpgs) images from $#frames frames; exiting"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  got done
else
  if ($?DEBUG) then
    set message = "found $#jpgs images from $#frames frames"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
endif

##
## POST PICTURE
##
set IF = "$jpgs[1]"
set post = "first"
switch ( "${MOTION_POST_PICTURES}" )
  case "center":
    @ h = $#jpgs / 2
    if ( $h >= 1 && $h <= $#jpgs ) then
      set post = "center"
      set IF = "$jpgs[$h]"
    endif
    breaksw
  case "best":
    if ($?BESTJPG) then
      set post = "best"
      set IF = "${BESTJPG}"
    endif
    breaksw
  case "last":
    set post = "last"
    set IF = "$jpgs[$#jpgs]"
    breaksw
endsw

# test
if ( "${post}" != "${MOTION_POST_PICTURES}" ) then
  if ($?DEBUG) then
    set message = "unable to find ${MOTION_POST_PICTURES} image; using ${post} image: ${IF}"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
endif

# PUBLISH 
if ( -s "${IF}" ) then
  set MQTT_TOPIC = "${MOTION_GROUP}/${MOTION_CLIENT}/${CN}/image"
  motion2mqtt_pub.sh -q 2 -r -t "${MQTT_TOPIC}" -f "${IF}"
  if ($?DEBUG) then
    set message = "sent file ${IF} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  if ( -s "$IF:r.json" ) set POST_IMAGE_JSON = "$IF:r.json"
else
  if ($?DEBUG) then
    set message = "cannot locate file: ${IF}; exiting"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  goto done
endif

## minimum frame count
if ($#jpgs < 2) then
  if ($?DEBUG) then
    set message = "insufficient images ($#jpgs) for motion analysis; going to update"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  goto update
endif

###
### calculate AVERAGE and BLEND images
###

## AVERAGE 
set average = "$tmpdir/$EVENT_JSON:t:r"'-average.jpg'
convert $jpgs -average $average >&! ${tmpdir}/$$.out
if ( ! -s "$average") then
  if ($?DEBUG) then
    set message = `cat "${tmpdir}/$$.out"`
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
else
  set MQTT_TOPIC = "$MOTION_GROUP/${MOTION_CLIENT}/${CN}/image-average"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "$average"
  if ($?DEBUG) then
    set message = "sent file ${average} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
endif
rm -f "${tmpdir}/$$.out"

## BLEND
set blend = "$tmpdir/$EVENT_JSON:t:r"'-blend.jpg'
convert $jpgs -compose blend -define 'compose:args=50' -alpha on -composite $blend >&! ${tmpdir}/$$.out
if ( ! -s "$blend") then
  if ($?DEBUG) then
    set message = `cat "${tmpdir}/$$.out"`
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
else 
  set MQTT_TOPIC = "$MOTION_GROUP/${MOTION_CLIENT}/${CN}/image-blend"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "$blend"
  if ($?DEBUG) then
    set message = "sent file ${blend} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
endif
rm -f "${tmpdir}/$$.out"

###
### GIF
###

# find frames per second for this camera
set fps = `echo "$#frames / $elapsed" | bc -l`
set rem = `echo $fps:e | sed "s/\(.\).*/\1/"`
if ($rem >= 5) then
  @ fps = $fps:r + 1
else
  set fps = $fps:r
endif
# calculate ticks (1/100 second)
set delay = `echo "100.0 / $fps" | bc -l`
set delay = $delay:r

## animated GIF
set gif = "$tmpdir/$EVENT_JSON:t:r.gif"
convert -loop 0 -delay $delay $jpgs $gif
if ( ! -s "$gif" ) then
  if {$?DEBUG) then
    set message = "Failed to convert $#jpgs into GIF: $gif" 
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
else 
  set MQTT_TOPIC = "$MOTION_GROUP/${MOTION_CLIENT}/${CN}/image-animated"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "$gif"
  if ($?DEBUG) then
    set message = "sent file ${gif} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  cp -f "$gif" "$EVENT_JSON:r.gif"
endif

goto update

###
### DIFFS
###

# calculate all frame-to-frame differences
set fuzz = 20
set avgdiff = 0
set maxdiff = 0
set changed = ()
set avgsize = 0
set maxsize = 0
set biggest = ()
set totaldiff = 0
set totalsize = 0
set ps = ()
set diffs = ()

set i = 1
while ( $i <= $#jpgs )

  # calculate difference
  set diffs = ( $diffs "$tmpdir/$jpgs[$i]:t:r"'-mask.jpg' )
  set p = ( `compare -metric fuzz -fuzz "$fuzz"'%' "$jpgs[$i]" "$average" -compose src -highlight-color white -lowlight-color black "$diffs[$#diffs]" |& awk '{ print $1 }'` )
  # keep track of differences
  set ps = ( $ps $p:r )
  @ totaldiff += $ps[$#ps]
  if ( $maxdiff < $p:r ) then
    set maxdiff = $p:r
    set changed = "$jpgs[$i]"
  endif
  # retrieve size
  set size = `jq -r '.size' "$jpgs[$i]:r".json`
  # keep track of size
  @ totalsize += $size
  if ( $maxsize < $size ) then
    set maxsize = $size
    set biggest = "$jpgs[$i]"
  endif

  # update image JSON
  set IMGJSON = "$jpgs[$i]:r.json"
  set TEMPJSON = "${tmpdir}/$jpgs[$i]:t:r.json"
  set diff = '{"pixels":'${p}',"size":'${size}'}'
  jq '.diff='"${diff}" "${IMGJSON}" > "${TEMPJSON}"
  jq -c '.' "${TEMPJSON}" >! "${IMGJSON}"
  rm -f "${TEMPJSON}"

  # debug
  if ($?DEBUG) then
    set message = "calculated difference for $jpgs[$i] as $diff"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif

  # increment and continue
  @ i++
end

# calculate average difference
if ($#ps) @ avgdiff = $totaldiff / $#ps
if ($#ps) @ avgsize = $totalsize / $#ps

set AVGJSON = '{"count":'$#jpgs',"difference":'${avgdiff}',"size":'${avgsize}'}'

if {$?DEBUG) then
  set message = "averages: ${AVGJSON}"
  echo "$0:t $$ -- ${message}" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"${message}"'"}'
endif

## COMPOSITE 

# composite these images
set srcs = ( $jpgs )
set masks = ( $diffs )
# start with average
set composite = "$tmpdir/$EVENT_JSON:t:r"'-composite.jpg'
cp -f "$average" "$composite"

# KEY FRAMES or NOT
if ($?ALL_FRAMES == 0) then
  set kjpgs = ()
  set kdiffs = ()
  @ i = 1
  while ( $i <= $#jpgs )
    # keep track of jpgs w/ change > average
    if ($ps[$i] > $avgdiff) then
      set kjpgs = ( $kjpgs $jpgs[$i] )
      set kdiffs = ( $kdiffs $diffs[$i] )
    endif
    @ i++
  end
  set srcs = ( $kjpgs )
  set masks = ( $kdiffs )
endif

# process sources
if ($?DEBUG) echo "$0:t $$ -- Compositing $#srcs sources with $#masks masks" >& /dev/stderr
@ i = 1
while ( $i <= $#srcs )
  set c = $composite:r.$i.jpg
  if ($?DEBUG) echo "$0:t $$ -- Compositing ${i} ${c} from $srcs[$i] and $masks[$i]" >& /dev/stderr
  convert "$composite" "$srcs[$i]" "$masks[$i]" -composite "$c"
  mv -f $c $composite
  @ i++
end
# success or failure
if (! -s "$composite") then
  if {$?DEBUG) then
    set message = "Failed to convert $#jpgs into a composite: $composite"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"${message}"'"}'
  endif
else 
  set MQTT_TOPIC = "$MOTION_GROUP/${MOTION_CLIENT}/${CN}/image-composite"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "$composite"
  if ($?DEBUG) then
    set message = "sent file ${composite} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"${message}"'"}'
  endif
endif

## animated GIF mask
set mask = $tmpdir/$EVENT_JSON:t:r.mask.gif
pushd "$dir" >& /dev/null
convert -loop 0 -delay $delay $diffs $mask
popd >& /dev/null
if (! -s "$mask") then
  if ($?DEBUG) then
    set message = "failed to convert $#jpgs into a mask: $mask"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"${message}"'"}'
  endif
else
  set MQTT_TOPIC = "$MOTION_GROUP/${MOTION_CLIENT}/${CN}/image-animated-mask"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "$mask"
  if ($?DEBUG) then
    set message = "sent file ${mask} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
    echo "$0:t $$ -- ${message}" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"${message}"'"}'
  endif
endif

###
### UPDATE EVENT
###

update:

## build images array
if ($#jpgs) then
  unset images
  foreach jpg ( $jpgs )
    if ($?images) then
      set images = "${images}"','
    else
      set images = '['
    endif
    set images = "${images}"'"'"$jpg:t:r"'"'
  end
  set images = "${images}"']'
else
  set images = 'null'
endif

if ( ! -s "${EVENT_JSON}" ) then
  # no event JSON
  set message = "empty or not found: ${EVENT_JSON}"
  echo "$0:t $$ -- ${message}" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  goto done
endif

#############

set date = `date +%s`

if ( $?POST_IMAGE_JSON ) then
  set noglob
  set PIJ = ( `jq -c '.' "${POST_IMAGE_JSON}"` )
  jq '.image='"${PIJ}"'|.elapsed='${elapsed}'|.end='${LAST}'|.date='${date}'|.images='"${images}" "${EVENT_JSON}" > "${tmpdir}/pij.$$.json"
  unset noglob
else
  jq '|.elapsed='${elapsed}'|.end='${LAST}'|.date='${date}'|.images='"${images}" "${EVENT_JSON}" > "${tmpdir}/pij.$$.json"
endif

rm -f "${EVENT_JSON}"
jq -c '.' "${tmpdir}/pij.$$.json" > "${EVENT_JSON}"
rm -f "${tmpdir}/pij.$$.json"

#############

## do MQTT
set MQTT_TOPIC = "${MOTION_GROUP}/${MOTION_CLIENT}/${CN}/event/end"
motion2mqtt_pub.sh -q 2 -r -t "${MQTT_TOPIC}" -f "${EVENT_JSON}"
if ($?DEBUG) then
  set message = "sent file ${EVENT_JSON} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
  echo "$0:t $$ -- ${message}" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

## remove JSON's and JPEG's
for jpeg in $(jq -r '.images' ${EVENT_JSON}); do
  rm -f ${dir}/${jpeg}.*
done
rm -f "${EVENT_JSON}"

###
### ALL DONE
###

done:

if ($?tmpdir) then
  rm -fr "${tmpdir}"
endif

if ($?DEBUG) then
  set message = ( "FINISH" `date` )
  echo "$0:t $$ -- ${message}" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

