#!/bin/bash
if [ -z $(command -v "lsblk") ]; then
  echo '{"lsblk":null}'
  exit 1
fi
echo -n '{"lsblk":' $(lsblk -J 2> /dev/null | jq '.blockdevices') '}'
exit 0
