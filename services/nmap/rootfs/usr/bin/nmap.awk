BEGIN { i=0; FS="[[:space:]/()]+"; printf("{\"nmap\":["); }

/Nmap scan report/ {
  if (i++ == 0) printf("{");
  if (i > 1) printf("},{");
  printf("\"ip\":\"%s\"", $5);
}

/Host is up/ {
  printf(",\"latency\":\"%s\"", $4);
}

/MAC Address/ {
  printf(",\"mac\":\"%s\"", $3);
}

END {
  if (i > 0) printf("}");
  printf("]}\n");
}
