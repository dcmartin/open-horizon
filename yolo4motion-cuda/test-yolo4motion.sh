#!/bin/bash

###
### THIS SCRIPT PROVIDES AN AUTOMATED SERVICE TEST FOR ANY SERVICE
###
### PROCESSES JSON TO PRODUCE TYPE-TREE FOR OUTPUT; COMPARE TO TEST SAMPLE
###
### DO __NOT__ CALL INTERACTIVELY
###

print_object() {
  key="${1}"
  type=$(echo "${OUT}" | jq -r ".${key}|type" 2> /dev/null)
  echo '"'${key##*.}'": '
  case "${type}" in 
    object)
      entries=$(echo "${OUT}" | jq -r ".${key}|to_entries[].key" 2> /dev/null)
      echo '{'
      subs=
      if [ ${DEPTH} -le 3 ]; then
        for e in ${entries}; do
          if [ ! -z "${subs}" ]; then subs="${subs}"','; fi
	  DEPTH=$((DEPTH+1))
          subs="${subs}""$(print_object "${key}.${e}")"
          DEPTH=$((DEPTH-1))
        done
      else
        subs="${subs}"'"'${e}'":"'${type}'"'
      fi 
      echo "${subs}"'}'
      ;;
    array)
      count=$(echo "${OUT}" | jq ".${key}|length" 2> /dev/null)
      echo '['
      i=0
      while [ ${i} -lt ${count} ]; do
	if [ ${i} -gt 0 ]; then echo ','; fi
        t=$(echo "${OUT}" | jq -r ".${key}[${i}]|type" 2> /dev/null)
	echo '"'${t}'"'
        i=$((i+1))
      done
      echo ']'
      ;;
    *)
      echo '"'${type}'"'
      ;;
  esac
}

### MAIN

# get input
REPLY=$(cat -)

# test input
if [ -z "${REPLY}" ]; then echo "false"; exit 1; fi

# process input
OUT="${REPLY}"
ENTRIES=$(echo "${OUT}" | jq -r '.|to_entries[].key' 2> /dev/null)
if [ "${ENTRIES}" == 'null' ]; then echo "entries: null"; break; fi
OUTPUT='{'
DEPTH=1
SUBS=; for E in ${ENTRIES}; do
    if [ ! -z "${SUBS}" ]; then SUBS="${SUBS}"','; fi
    SUBS="${SUBS}""$(print_object "${E}")"
done
OUTPUT="${OUTPUT}""${SUBS}"'}'
echo "${OUTPUT}" | jq -c '.' &> /dev/stderr

if [ $? == 0 ]; then echo 'true'; exit 0; else echo 'false'; exit 1; fi
