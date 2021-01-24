#!/bin/bash
if [ -z $(command -v "i2cdetect") ]; then
  echo '{"i2c":null}'
  exit 1
fi
echo -n '{"i2c":'
tmp=$(mktemp)
i2cdetect -y 1 2> /dev/null | sed 's/^..[^:]/key:/' | sed 's/\([^:]*\):/\1/' | sed 's/   / xx/g' | sed 's/ [ ]*/,/g' | sed 's/,$//' > ${tmp}
if [ -s "${tmp}" ]; then cat "${tmp}" | csvjson; else echo 'null'; fi
echo '}'
rm -f "${tmp}"
exit 0

