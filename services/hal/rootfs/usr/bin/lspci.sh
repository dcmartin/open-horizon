#!/bin/bash
if [ -z $(command -v "lspci") ]; then
  echo '{"lspci":null}'
  exit 1
fi
lspci -mm -nn | sed 's| "|,"|g' | sed 's| -[^ ,]*||g' > /tmp/lspci.$$ 2> /dev/null

if [[ $(wc -l "/tmp/lspci.$$" | awk '{ print $1 }') == 0 ]]; then
  rm -f /tmp/lspci.$$
  echo '{"lspci":null}'
  exit 1
fi

COLS=$(awk -F, 'END { print NF }' /tmp/lspci.$$)

echo -n '{"lspci":['
cat /tmp/lspci.$$ | while read -r; do
  if [ -n "${VAL:-}" ]; then echo -n ','; fi

  echo -n '{'
  SLOT=$(echo "$REPLY" | awk -F, '{ print $1 }')
  echo -n '"slot": "'$SLOT'"'
  if [ "${COLS}" == "6" ]; then
    VAL=$(echo "$REPLY" | awk -F, '{ print $2 }' | sed 's|"Class \(.*\)"|"device_class_id": "\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi
    VAL=$(echo "$REPLY" | awk -F, '{ print $3 }' | sed 's|"\(.*\)"|"vendor_class_id": "\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi
    VAL=$(echo "$REPLY" | awk -F, '{ print $4 }' | sed 's|"\(.*\)"|"device_id": "\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi
    VAL=$(echo "$REPLY" | awk -F, '{ print $5 }' | sed 's|"\(.*\)"|"vendor_id": "\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi

  elif [ "${COLS}" == "11" ]; then
    VMM=$(lspci -vmm 2> /dev/null | egrep -A 5 "$SLOT")
    VAL=$(echo "$VMM" | egrep "Rev:" | sed 's|.*Rev:[ \t]*\([^ \t]*\).*|\1|')
    if [ -n "${VAL}" ]; then echo -n ',''"revision": "'$VAL'"'; fi
    VAL=$(echo "$VMM" | egrep "ProgIf" | sed 's|.*ProgIf:[ \t]*\([^ \t]*\).*|\1|')
    if [ -n "${VAL}" ]; then echo -n ',''"interface": "'$VAL'"'; fi

    VAL=$(echo "$REPLY" | awk -F, '{ print $5 }')
    if [ ! -z "${VAL}" ] && [ "${VAL}" != "" ]; then
      VAL=$(echo "${VAL}" | sed 's|"\(.*\) \[\(.*\)\]"|"vendor_id": "\2","vendor_name":"\1"|')
      if [ "${VAL}" != "${VAL}" ]; then echo -n ','"${VAL}"; fi
    fi

    VAL=$(echo "$REPLY" | awk -F, '{ print $2 }' | sed 's|"\(.*\) \[\(.*\)\]"|"device_class_id": "\2","device_class":"\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi
    VAL=$(echo "$REPLY" | awk -F, '{ print $3 }' | sed 's|"\(.*\) \[\(.*\)\]"|"vendor_class_id": "\2","vendor_class":"\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi
    VAL=$(echo "$REPLY" | awk -F, '{ print $4 }' | sed 's|"\(.*\) \[\(.*\)\]"|"device_id": "\2","device_name":"\1"|')
    if [ "${VAL}" != "${REPLY}" ]; then echo -n ','"${VAL}"; fi
  fi
  echo -n '}'
done
echo ']}'

rm -f /tmp/lspci.$$
exit 0
