#!/usr/bin/python3

## system
import sys, os, pdb, json, codecs, magic, subprocess, cv2, time
import numpy as np
from ctypes import *
from PIL import Image
from PIL import GifImagePlugin

###
## darknet.py from github.com/dcmartin/openyolo/tree/master/darknet/python/darknet.py
###

from ctypes import *
import math
import random

def c_array(ctype, values):
    arr = (ctype * len(values))()
    arr[:] = values
    return arr

def convertBack(x, y, w, h):
    xmin = int(round(x - (w / 2)))
    xmax = int(round(x + (w / 2)))
    ymin = int(round(y - (h / 2)))
    ymax = int(round(y + (h / 2)))
    return xmin, ymin, xmax, ymax

def cvDrawBoxes(detections, img):
    detection_locations = []
    for detection in detections:
        x, y, w, h = detection[2][0],\
            detection[2][1],\
            detection[2][2],\
            detection[2][3]
        xmin, ymin, xmax, ymax = convertBack(float(x), float(y), float(w), float(h))
        pt1 = (xmin, ymin)
        pt2 = (xmax, ymax)
        cv2.rectangle(img, pt1, pt2, (0, 255, 0), 1)
        cv2.putText(img,
                    detection[0].decode() +
                    " [" + str(round(detection[1] * 100, 2)) + "]",
                    (pt1[0], pt1[1] - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                    [0, 255, 0], 2)
        detection_locations.append(detection)
    return img, detection_locations

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


# find library
lib = CDLL(os.environ['DARKNET'] + "/libdarknet.so", RTLD_GLOBAL)

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

netMain = None
metaMain = None
altNames = None

# DARKNET functions
def network_width(net):
    return lib.network_width(net)

def network_height(net):
    return lib.network_height(net)

def array_to_image(arr):
    # need to return old values to avoid python freeing memory
    arr = arr.transpose(2,0,1)
    c, h, w = arr.shape[0:3]
    arr = np.ascontiguousarray(arr.flat, dtype=np.float32) / 255.0
    data = arr.ctypes.data_as(POINTER(c_float))
    im = IMAGE(w,h,c,data)
    im.w = w
    im.h = h
    return im, arr

def bash_cmd( command ):
    process = subprocess.Popen(command.split())
    output, error = process.communicate()
    if error:
        return error
    return output


def detect(net, meta, frame, thresh=.5, hier_thresh=.5, nms=.45):
    num = c_int(0)
    pnum = pointer(num)
    predict_image(net, frame)
    # dets = get_network_boxes(net, custom_image_bgr.shape[1], custom_image_bgr.shape[0], thresh, hier_thresh, None, 0, pnum, 0) # OpenCV
    dets = get_network_boxes(net, frame.w, frame.h, thresh, hier_thresh, None, 0, pnum, 0)
    num = pnum[0]
    if nms:
        do_nms_sort(dets, num, meta.classes, nms)
    res = []
    for j in range(num):
        for i in range(meta.classes):
            if dets[j].prob[i] > 0:
                b = dets[j].bbox
                if altNames is None:
                    nameTag = meta.names[i]
                else:
                    nameTag = altNames[i]
                res.append((nameTag, dets[j].prob[i], (b.x, b.y, b.w, b.h)))
    res = sorted(res, key=lambda x: -x[1])
    free_detections(dets, num)
    return res

filetypes = [ "mp4", "gif", "jpg", "png", "3gp" ]

def determine_filetype( file ):
    if not os.path.exists(file):
        print("File does not exist at location: {}".format(file))
        return FileNotFoundError
    return magic.from_file(file, mime=True).split("/")[1]

def VideoDetections( net, meta, filename, threshold ):

    cap = cv2.VideoCapture(filename)
    ret, frame_read = cap.read()
    if frame_read is None:
        print("You do not have a valid image or video")
    detection_locations = []
    i = 0
    while frame_read is not None:
        frame_rgb = cv2.cvtColor(frame_read, cv2.COLOR_BGR2RGB)
        frame_resized = cv2.resize(frame_rgb,
                                   (network_width(net),
                                    network_height(net)),
                                   interpolation=cv2.INTER_LINEAR)
        im, image = array_to_image(frame_resized)
        detections = detect(net, meta, im, threshold)
        img, detection_location = cvDrawBoxes(detections, frame_resized)
        ret, frame_read = cap.read()
        i += 1
        if detections:
            result = {}
            result['config'] = config
            result['cfg'] = cfg
            result['weights'] = weights
            result['data'] = data
            result['threshold'] = threshold
            result['filename'] = filename
            result['count'] = len(image)

            entities = []
            for detection in detection_location:
                # Prepare info for the prediction image
                record = {}
                record['id'] = str(detection)
                record['entity'] = detection[0].decode("utf-8")
                record['confidence'] = detection[1] * 100.0

                center = {}
                center['x'] = detection[2][0]
                center['y'] = detection[2][1]
                record['center'] = center
                record['width'] = detection[2][2]
                record['height'] = detection[2][3]

                entities.append(record)

            result['results'] = entities
            json.dump(result, codecs.open('/dev/stdout', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True,
                      indent=2)



def main(net, meta, filename, threshold):
    filetype = os.path.basename(filename).split(".")[1].lower()
    if filetype not in filetypes:
        print("I'm sorry we don't currently support your file extension: {}".format(filetype))
        sys.exit(1)
    try:
        filename = os.path.abspath(filename)
    except FileNotFoundError:
        print(FileNotFoundError)
        exit(1)

    VideoDetections(net, meta, filename, threshold)


if __name__ == '__main__':
    narg = len(sys.argv)

    if narg > 1:
        filename = sys.argv[1]
    else:
        filename = "data/horses.jpg"

    if narg > 2:
        threshold = float(sys.argv[2])
    else:
        threshold = 0.5

    if narg > 3:
        cfg = sys.argv[3]
        config = "manual"
    else:
        config = "tiny-v2"

    if narg > 4:
        weight = sys.argv[4]

    if narg > 5:
        data = sys.argv[5]

    if config == "tiny-v2" or config == "tiny":
        cfg = os.environ['DARKNET_TINYV2_CONFIG']
        weights = os.environ['DARKNET_TINYV2_WEIGHTS']
        data = os.environ['DARKNET_TINYV2_DATA']

    if config == "tiny-v3":
        cfg = os.environ['DARKNET_TINYV3_CONFIG']
        weights = os.environ['DARKNET_TINYV3_WEIGHTS']
        data = os.environ['DARKNET_TINYV3_DATA']

    if config == "v2":
        cfg = os.environ['DARKNET_V2_CONFIG']
        weights = os.environ['DARKNET_V2_WEIGHTS']
        data = os.environ['DARKNET_V2_DATA']

    if config == "v3":
        cfg = os.environ['DARKNET_V3_CONFIG']
        weights = os.environ['DARKNET_V3_WEIGHTS']
        data = os.environ['DARKNET_V3_DATA']

    if config == "manual":
        if narg > 4:
            weight = sys.argv[4]
        else:
            config = cfg

        if narg > 5:
            data = sys.argv[5]
        else:
            config = cfg

    try:
        gpu = os.environ['NVIDIA_VISIBLE_DEVICES']
    except:
        set_gpu(0)

    net = load_net(bytes(cfg, encoding='utf-8'), bytes(weights, encoding='utf-8'), 0)
    meta = load_meta(bytes(data, encoding='utf-8'))
    main(net, meta, filename, threshold)
