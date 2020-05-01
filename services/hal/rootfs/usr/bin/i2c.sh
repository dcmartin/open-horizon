#!/bin/bash
if [ -z $(command -v "i2cdetect") ]; then
  echo '{"i2c":null}'
  exit 1
fi
echo -n '{"i2c":'
i2cdetect -y 1 2> /dev/null | sed 's/^..[^:]/key:/' | sed 's/\([^:]*\):/\1/' | sed 's/   / xx/g' | sed 's/ [ ]*/,/g' | sed 's/,$//' | csvjson
echo '}'
exit 0

