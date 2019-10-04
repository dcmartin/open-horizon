#!/bin/bash

lsdf()
{
df -Ph | jq -R -s ' [split("\n")|.[]|if test("^/") then gsub(" +"; " ")|split(" ")|{mount:.[0],spacetotal:.[1],spaceavail:.[3]} else empty end]'
}

if [ -z $(command -v "df") ]; then
  echo '{"df":null}'
  exit 1
fi
echo -n '{"lsdf":' $(lsdf 2> /dev/null) '}'
exit 0
