#!/bin/bash
#watch -n1 "awk 'NR==3 {printf(\"WiFi Signal Strength = %.0f%%\\n\",\$3*10/7)}' /proc/net/wireless"
if [ -e '/proc/net/wireless' ]; then
  awk 'NR==3 {printf("WiFi Signal Strength = %.0f%%",\$3*10/7)}' /proc/net/wireless
else
  echo "No /proc/net/wireless"
  cat /proc/net/netstat
fi
