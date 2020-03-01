#!/bin/bash

process_alpr_results()
{
  local json=${1}.json
  local jpeg=${1}.jpg
  local result

  if [ -s "${json}" ] && [ -s "${jpeg}" ]; then
    local plates=$(jq '[.results[]|{"tag":.plate,"confidence":.confidence,"top":[.coordinates[].y]|min,"left":[.coordinates[].x]|min,"bottom":[.coordinates[].y]|max,"right":[.coordinates[].x]|max}]' ${json})
    local tags=$(echo "${plates:-null}" | jq -r '.[].tag?')
    local colors=(blue red white yellow green orange magenta cyan)
    local count=0
    local output=

    for t in ${tags}; do
      local plate=$(echo "${plates:-null}" | jq '.[]|select(.tag=="'${t}'")')
      local top=$(echo "${plate:-null}" | jq -r '.top')
      local left=$(echo "${plate:-null}" | jq -r '.left')
      local bottom=$(echo "${plate:-null}" | jq -r '.bottom')
      local right=$(echo "${plate:-null}" | jq -r '.right')

      if [ ${count} -eq 0 ]; then
        file=${jpeg%%.*}-${count}.jpg
        cp -f ${jpeg} ${file}
      else
        rm -f ${file}
        file=${output}
      fi
      output=${jpeg%%.*}-$((count+1)).jpg
      convert -pointsize 24 -stroke ${colors[${count}]} -fill none -strokewidth 5 -draw "rectangle ${left},${top} ${right},${bottom} push graphic-context stroke ${colors[${count}]} fill ${colors[${count}]} translate ${right},${bottom} rotate 40 path 'M 10,0  l +15,+5  -5,-5  +5,-5  -15,+5  m +10,0 +20,0' translate 40,0 rotate -40 stroke none fill ${colors[${count}]} text 3,6 '${t}' pop graphic-context" ${file} ${output}
      if [ ! -s "${output}" ]; then
        echo "Failed"
        exit 1
      fi
      count=$((count+1))
      if [ ${count} -ge ${#colors[@]} ]; then count=0; fi
    done
    if [ ! -z "${output:-}" ]; then
      rm -f ${file}
      result=${jpeg%%.*}-alpr.jpg
      mv ${output} ${result}
    fi
  fi
  echo "${result:-null}"
}

if [ ! -z "${*}" ]; then
  process_alpr_results ${*}
else
  echo "Usage: ${0} <sample>; for example: ${0} samples/h786poj" &> /dev/stderr
fi
