#!/usr/bin/python

## system
import sys,os
sys.path.append(os.path.join(os.environ("DARKNET"),'/python'))

## why?
import pdb

import json, codecs

## darknet
import darknet as dn

## input
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
  config = "manual"
else:
  config = cfg

if narg > 5:
  data = sys.argv[5]
  config = "manual"
else:
  config = cfg

if config == "tiny-v2" or config == "tiny":
  cfg = os.environ("DARKNET_TINYV2_CONFIG")
  weights = os.environ("DARKNET_TINYV2_WEIGHTS")
  data = os.environ("DARKNET_TINYV2_DATA")

if config == "tiny-v3":
  cfg = os.environ("DARKNET_TINYV3_CONFIG")
  weights = os.environ("DARKNET_TINYV3_WEIGHTS")
  data = os.environ("DARKNET_TINYV3_DATA")

if config == "v2":
  cfg = os.environ("DARKNET_V2_CONFIG")
  weights = os.environ("DARKNET_V2_WEIGHTS")
  data = os.environ("DARKNET_V2_DATA")

if config == "v3":
  cfg = os.environ("DARKNET_V3_CONFIG")
  weights = os.environ("DARKNET_V3_WEIGHTS")
  data = os.environ("DARKNET_V3_DATA")

try:
  gpu=os.environ['NVIDIA_VISIBLE_DEVICES'];
  try:
    dn.set_gpu(1)
  except:
    dn.set_gpu(0)
except:
  dn.set_gpu(0)

net = dn.load_net(cfg, weights, 0)
meta = dn.load_meta(data)

raw = dn.detect(net, meta, filename, threshold)

result = {}
result['config'] = config
result['cfg'] = cfg
result['weights'] = weights
result['data'] = data
result['threshold'] = threshold
result['filename'] = filename
result['count'] = len(raw)

entities = []
for k in range(len(raw)):
  # Prepare info for the prediction image
  record = {}
  record['id'] = str(k)
  record['entity'] = raw[k][0]
  record['confidence'] = raw[k][1] * 100.0

  center = {}
  center['x'] = int(raw[k][2][0])
  center['y'] = int(raw[k][2][1])
  record['center'] = center
  record['width'] = int(raw[k][2][2])
  record['height'] = int(raw[k][2][3])

  entities.append(record)

result['results'] = entities

json.dump(result, codecs.open('/dev/stdout', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)
