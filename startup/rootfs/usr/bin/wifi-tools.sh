wifi_signal()
{
  DEV='wlan0'
  OUTPUT=$(mktemp -t "${FUNCNAME[0]}-XXXXXX")
  echo '{"'${DEV}'":' >> ${OUTPUT}

  OUT=$(iwconfig 2> /dev/null | egrep -A 7 "^${DEV}" | egrep "Link Quality" | sed 's/Link Quality/linkQuality/' | sed 's/^[ ]*//' | sed 's/[ ]*$//' | sed 's/[ ]*Signal level/","signalLevel/' | awk -F= '{ printf("{\"%s\":\"%s\":\"%s\"}\n",$1,$2,$3) }')
  echo "${OUT:-null}"  >> ${OUTPUT}
  echo '}' >> ${OUTPUT}

  echo ${OUTPUT}
}

