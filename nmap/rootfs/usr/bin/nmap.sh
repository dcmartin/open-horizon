#!/bin/bash

exec 0>&- # close stdin
exec 1>&- # close stdout
exec 2>&- # close stderr

if [ -z "${NMAP_LAN:-}" ]; then NMAP_LAN='192.168.1.0'; fi
if [ -z "${NMAP_SUB:-}" ]; then NMAP_SUB=24; fi

temp=$(mktemp -t "${0##*/}-XXXXXX")
if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- running nmap -sn -T5 ${NMAP_LAN}/${NMAP_SUB}" &> /dev/stderr; fi
nmap -sn -T5 ${NMAP_LAN}/${NMAP_SUB} > ${temp}
if [ -s "${temp}" ]; then 
  cat ${temp} | gawk -f ${0%/*}/nmap.awk > ${temp}.$$ && mv -f ${temp}.$$ ${temp}
  if [ -s "${temp}" ]; then 
    if [ ! -z "${1:-}" ]; then
      mv -f ${temp} ${1}
    else
      cat ${temp}
    fi
  fi
  rm -f ${temp}
fi
