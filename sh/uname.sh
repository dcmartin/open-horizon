#!/bin/bash
#     -a      Behave as though all of the options -mnrsv were specified.
#
#     -m      print the machine hardware name.
#
#     -n      print the nodename (the nodename may be a name that the system is known by to a communications network).
#
#     -p      print the machine processor architecture name.
#
#     -r      print the operating system release.
#
#     -s      print the operating system name.
#
#     -v      print the operating system version.

echo '{' \
  '"hardware":"'$(uname -m)'",' \
  '"nodename":"'$(uname -n)'",' \
  '"processor":"'$(uname -p)'",' \
  '"os_release":"'$(uname -r)'",' \
  '"os_name":"'$(uname -s)'",' \
  '"os_version":"'$(uname -v)'"' \
  '}'

