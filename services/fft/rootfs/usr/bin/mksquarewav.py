#!/usr/bin/python3

###
### requirements: matplotlib, numpy, scipy
###

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

## packages
from scipy import signal
from scipy.io import wavfile

## use Tk canvas
matplotlib.use('Agg')

## define parameters
sampleRate = 44100
frequency = 1000
length = 5

## Samples per second, times number of secdonds
samples = sampleRate*length

## X Axis for numpy signal generator
x = np.arange(samples)
#  scipy.signal.square(t, duty=0.5)[source]¶
y = 100* signal.square(2 *np.pi * frequency * x / sampleRate )
# write output
wavfile.write('square.wav', sampleRate, y) 
