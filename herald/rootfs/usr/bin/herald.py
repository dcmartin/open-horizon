#
# Discovery service container
#
# Written by Glen Darling, December 2018.
# Copyright 2018, Glen Darling; all rights reserved.
#

from flask import Flask
import json
import socket
import os
import sys
import threading
import time

# UDP server and client
UDP_BUFFER_SIZE = 16384

# UDP server to collect responses from other nodes running this software
class UdpListenThread(threading.Thread):
  def run(self):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', HERALD_PORT))
    while True:
      data, address_and_port = sock.recvfrom(UDP_BUFFER_SIZE)
      address = address_and_port[0]
      js = { "address": str(address), "data": data }
      # If it already exists in the array, remove the old entry
      for i in range(len(announced)):
        if address == announced[i]["address"]:
          del announced[i]
      announced.append(js)

# UDP client to publish our node data to other nodes running this software
class UdpPublishThread(threading.Thread):
  def run(self):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.settimeout(5)

    while True:
      if os.path.isfile(ANNOUNCE_FILE):
        announce = json.load(ANNOUNCE_FILE)
        sock.sendto(announce.encode(), ('255.255.255.255', HERALD_PORT))
      time.sleep(HERALD_PERIOD)

# create web application server based on Flask
webapp = Flask(os.environ("SERVICE_LABEL"))

# A web server to make the discovery data available locally
@webapp.route("/v1/announced")
def get_announced():
  out = { "version": "1.0", "port": HERALD_PORT, "announced": announced}
  return json.dumps(out) + '\n'

@wepapp.route("/v1/announce", methods= ['POST']))
def post_announce():
    if request.headers['Content-Type'] == 'application/json':
	with open(ANNOUNCE_FILE,'w') as outfile:
	  json.dump(request.json, outfile)
        return "200 OK"
    else:
        return "415 Unsupported Media Type"

# check for temporary directory
if os.path.isdir('/tmpfs'):
  tmpdir = '/tmpfs'
else:
  tmpdir = '/tmp'

# location of data to announce
ANNOUNCE_FILE=os.path.join(tmpdir,os.environ("SERVICE_LABEL"),os.getpid,'.json')

# environment variable for service
SERVICE_PORT=os.environ("SERVICE_PORT")

# service variables
HERALD_PORT=os.environ("HERALD_PORT")
HERALD_PERIOD=os.environ("HERALD_PERIOD")

# what has been announce'd by others
announced = list()

# Main program (to instantiate and start the 3 threads)
if __name__ == '__main__':
  udp_listener = UdpListenThread()
  udp_publisher = UdpPublishThread()
  udp_listener.start()
  udp_publisher.start()
  webapp.run(host='0.0.0.0', port=SERVICE_PORT)

