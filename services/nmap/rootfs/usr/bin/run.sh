#!/bin/sh
socat TCP4-LISTEN:80,fork EXEC:/usr/bin/service.sh
