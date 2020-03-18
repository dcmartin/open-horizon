#
# Most of this code is the original (YOLO) darknet code, from:
#   https://github.com/pjreddie/darknet
# and specifically, in here:
#   https://github.com/pjreddie/darknet/blob/master/python/darknet.py
#
# Following the darknet code, I have added a shell that makes the
# "detect()" function available through a REST API using Python Flask.
#
# Search ahead for "Glen Darling" to see the added code.
#

from ctypes import *
import math
import random

def sample(probs):
    s = sum(probs)
    probs = [a/s for a in probs]
    r = random.uniform(0, 1)
    for i in range(len(probs)):
        r = r - probs[i]
        if r <= 0:
            return i
    return len(probs)-1

def c_array(ctype, values):
    arr = (ctype*len(values))()
    arr[:] = values
    return arr

class BOX(Structure):
    _fields_ = [("x", c_float),
                ("y", c_float),
                ("w", c_float),
                ("h", c_float)]

class DETECTION(Structure):
    _fields_ = [("bbox", BOX),
                ("classes", c_int),
                ("prob", POINTER(c_float)),
                ("mask", POINTER(c_float)),
                ("objectness", c_float),
                ("sort_class", c_int)]


class IMAGE(Structure):
    _fields_ = [("w", c_int),
                ("h", c_int),
                ("c", c_int),
                ("data", POINTER(c_float))]

class METADATA(Structure):
    _fields_ = [("classes", c_int),
                ("names", POINTER(c_char_p))]

    

#lib = CDLL("/home/pjreddie/documents/darknet/libdarknet.so", RTLD_GLOBAL)
lib = CDLL("libdarknet.so", RTLD_GLOBAL)
lib.network_width.argtypes = [c_void_p]
lib.network_width.restype = c_int
lib.network_height.argtypes = [c_void_p]
lib.network_height.restype = c_int

predict = lib.network_predict
predict.argtypes = [c_void_p, POINTER(c_float)]
predict.restype = POINTER(c_float)

set_gpu = lib.cuda_set_device
set_gpu.argtypes = [c_int]

make_image = lib.make_image
make_image.argtypes = [c_int, c_int, c_int]
make_image.restype = IMAGE

get_network_boxes = lib.get_network_boxes
get_network_boxes.argtypes = [c_void_p, c_int, c_int, c_float, c_float, POINTER(c_int), c_int, POINTER(c_int)]
get_network_boxes.restype = POINTER(DETECTION)

make_network_boxes = lib.make_network_boxes
make_network_boxes.argtypes = [c_void_p]
make_network_boxes.restype = POINTER(DETECTION)

free_detections = lib.free_detections
free_detections.argtypes = [POINTER(DETECTION), c_int]

free_ptrs = lib.free_ptrs
free_ptrs.argtypes = [POINTER(c_void_p), c_int]

network_predict = lib.network_predict
network_predict.argtypes = [c_void_p, POINTER(c_float)]

reset_rnn = lib.reset_rnn
reset_rnn.argtypes = [c_void_p]

load_net = lib.load_network
load_net.argtypes = [c_char_p, c_char_p, c_int]
load_net.restype = c_void_p

do_nms_obj = lib.do_nms_obj
do_nms_obj.argtypes = [POINTER(DETECTION), c_int, c_int, c_float]

do_nms_sort = lib.do_nms_sort
do_nms_sort.argtypes = [POINTER(DETECTION), c_int, c_int, c_float]

free_image = lib.free_image
free_image.argtypes = [IMAGE]

letterbox_image = lib.letterbox_image
letterbox_image.argtypes = [IMAGE, c_int, c_int]
letterbox_image.restype = IMAGE

load_meta = lib.get_metadata
lib.get_metadata.argtypes = [c_char_p]
lib.get_metadata.restype = METADATA

load_image = lib.load_image_color
load_image.argtypes = [c_char_p, c_int, c_int]
load_image.restype = IMAGE

rgbgr_image = lib.rgbgr_image
rgbgr_image.argtypes = [IMAGE]

predict_image = lib.network_predict_image
predict_image.argtypes = [c_void_p, IMAGE]
predict_image.restype = POINTER(c_float)

def classify(net, meta, im):
    out = predict_image(net, im)
    res = []
    for i in range(meta.classes):
        res.append((meta.names[i], out[i]))
    res = sorted(res, key=lambda x: -x[1])
    return res

def detect(net, meta, image, thresh=.5, hier_thresh=.5, nms=.45):
    im = load_image(image, 0, 0)
    num = c_int(0)
    pnum = pointer(num)
    predict_image(net, im)
    dets = get_network_boxes(net, im.w, im.h, thresh, hier_thresh, None, 0, pnum)
    num = pnum[0]
    if (nms): do_nms_obj(dets, num, meta.classes, nms);

    res = []
    for j in range(num):
        for i in range(meta.classes):
            if dets[j].prob[i] > 0:
                b = dets[j].bbox
                res.append((meta.names[i], dets[j].prob[i], (b.x, b.y, b.w, b.h)))
    res = sorted(res, key=lambda x: -x[1])
    free_image(im)
    free_detections(dets, num)
    return res
    
#
# Aside from the "load_net()" and "load_meta()" calls below, the rest of
# this source file is added code, whose purpose is to enable access to the
# existing "detect()" function (directly above) over a Python Flask REST API.
#
# Glen Darling <glendarling@us.ibm.com
#

import os
import sys
import json
import time
import base64
import requests
from flask import Flask
from flask import request
from flask import send_file
from io import BytesIO
from PIL import Image, ImageDraw

# Configuration constants
FLASK_BIND_ADDRESS = '0.0.0.0'
FLASK_PORT = 80
#LOGO_IMAGE = '/o-h.png'
#LOGO_SIZE = (11,10)
LOGO_IMAGE = '/ibm.png'
LOGO_SIZE = (27,12)
INCOMING_IMAGE = '/tmp/incoming.jpg'
OUTGOING_IMAGE = '/tmp/outgoing.jpg'
COLOR_OUTLINE = '#ffffff'
COLOR_LABEL = '#000000'

if __name__ == "__main__":

  # Consume ClI arguments
  if (4 != len(sys.argv)):
    print("Usage:  %s model.cfg model.weights classes.data" % sys.argv[0])
    sys.exit(1)
  config = sys.argv[1]
  weights = sys.argv[2]
  metadata = sys.argv[3]
  print("Model config file:   %s" % config)
  print("Model weights file:  %s" % weights)
  print("Class metadata file: %s" % metadata)

  # Load the neural network and metadata about the classes
  global net
  net = load_net(config, weights, 0)
  global meta
  meta = load_meta(metadata)

  # Configure REST server args
  webapp = Flask('yolov3')
  webapp.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

  # Pull in the logo image
  global logo
  biglogo = Image.open(LOGO_IMAGE)
  logo = biglogo.resize(LOGO_SIZE, Image.LANCZOS)

  # Force the timezone in the container to be UTC
  os.environ['TZ']='UTC'

  # Outline an entity, and label it with its name and confidence
  def outline(original, draw, entity, confidence, bl_x, bl_y, w, h):
    label = (" %s (%0.2f%%)" % (entity, 100.0 * confidence))
    print ("LABEL: %s" % (label))
    shape = [bl_x, bl_y, bl_x + w, bl_y + h]
    draw.rectangle(shape, fill=None, outline=COLOR_OUTLINE)
    shape = [bl_x, bl_y - 14, bl_x + w, bl_y]
    draw.rectangle(shape, fill=COLOR_OUTLINE, outline=None)
    draw.text((bl_x + LOGO_SIZE[0], bl_y - 12), label, fill=COLOR_LABEL)
    original.paste(logo, (int(bl_x + 3), int(bl_y - 12)))

  #
  # Expose the YoloV3 "detect()" function
  #
  # URL parameters (i.e., "?key=value&..."), required are prefixed with '*':
  #  * kind:        currently must be 'json' (later 'raw' images too)
  #  * url:         the url this code will use to retrieve the source image
  #    user:        if url requires HTTP basic auth, this is the user
  #    password:    if url requires HTTP basic auth, this is the password
  #    thresh:      detection confidence threshold in percent (i.e., 0..100)
  #    hierthresh:  hierarchical detection confidence threshold in % (0..100) 
  #    nms:         non-max suppression intersection-over-union threshold in %
  #
  # Usage example:
  #   curl http://localhost:5252/detect?kind=json&url=http%3A%2F%2Frestcam
  #
  @webapp.route("/detect", methods=['GET'])
  def get_detect():

    kind = request.args.get('kind', '')
    if (kind != 'json'):
      return (json.dumps({"error": "kind must be 'json'"}) + '\n', 400)
    url = request.args.get('url', '')
    print("URL is:   %s" % url)
    user = request.args.get('user', '')
    password = request.args.get('password', '')
    thresh = request.args.get('thresh', '')
    hierthresh = request.args.get('hierthresh', '')
    nms = request.args.get('nms', '')

    # Pull image from the provided camera URL
    print("\nPulling an image from the camera REST service...\n")
    if ('' != user):
      r = requests.get(url, auth=(user, password))
    else:
      r = requests.get(url)
    if (r.status_code > 299):
      return (json.dumps({"error": "unable to get image from camera"}) + '\n', 400)
    #if (r.headers['content-type'] != 'application/json; charset=utf8'):
    #  return (json.dumps({"error": "camera did not return 'json'"}) + '\n', 400)
    j = r.json()
    source_image_b64 = j['cam']['image']
    i = base64.b64decode(source_image_b64)
    buffer = BytesIO()
    buffer.write(i)
    buffer.seek(0)
    with open(INCOMING_IMAGE,'wb') as outfile:
      outfile.write(buffer.read())
    # @@@ Ideally detect() should use the image in memory instead of a file
    r = detect(net, meta, INCOMING_IMAGE)
    #print r
    # @@@ This should use Image.fromBytes instead of reading this phytsical file
    prediction_start = time.time()
    prediction = Image.open(INCOMING_IMAGE)
    prediction_end = time.time()
    # Process the prediction result, drawing outline boxes around entities
    # Construct the return JSON as we go too
    data = {}
    entity_data = []
    draw = ImageDraw.Draw(prediction)
    os.remove(INCOMING_IMAGE)
    for k in range(len(r)):
      # Prepare info for the prediction image
      entity =  r[k][0]
      confidence =  r[k][1]
      center_x = r[k][2][0]
      center_y = r[k][2][1]
      width =  r[k][2][2]
      height = r[k][2][3]
      bottomLeft_x = center_x - (width / 2)
      bottomLeft_y = center_y - (height / 2)
      outline(prediction, draw, entity, confidence, bottomLeft_x, bottomLeft_y, width, height)
      # Prepare info for the retuen JSON payload
      this_entity = {}
      this_entity['name'] = entity
      this_entity['confidence'] = confidence
      this_entity['cx'] = center_x
      this_entity['cy'] = center_y
      this_entity['w'] = width
      this_entity['h'] = height
      entity_data.append(this_entity)
    prediction.save(OUTGOING_IMAGE)
    buffer = BytesIO()
    prediction.save(buffer, format='JPEG')
    buffer.seek(0)
    prediction_image_b64 = base64.b64encode(buffer.read())
    detect_data = {}
    detect_data['device'] = os.environ['HZN_DEVICE_ID']
    detect_data['tool'] = 'yolov3-tiny'
    detect_data['date'] = int(time.time())
    detect_data['time'] = (prediction_end - prediction_start)
    detect_data['entities'] = entity_data
    #detect_data['source'] = ' ... base64-encoded original image ... '
    #detect_data['prediction'] = ' ... base64-encoded prediction image with entity outlines ... '
    detect_data['source'] = source_image_b64
    detect_data['prediction'] = prediction_image_b64
    data['detect'] = detect_data
    #print data
    json_data = json.dumps(data)
    return (json_data + '\n', 200)

  # Start up the REST server
  webapp.run(host=FLASK_BIND_ADDRESS, port=FLASK_PORT)

  # Prevent caching everywhere
  @webapp.after_request
  def add_header(r):
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r


