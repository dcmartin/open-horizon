#!/bin/sh

exec 0>&- # close stdin
exec 1>&- # close stdout
exec 2>&- # close stderr

if [ ! -z ${SOCAT_LISTENER} ]; then
  socat TCP4-LISTEN:${SOCAT_LISTENER},fork EXEC:./node-id.sh &
fi
