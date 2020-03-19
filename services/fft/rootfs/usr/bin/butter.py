#!/usr/bin/python3

###
### fft.py - perform FFT on WAV and calculate Butterworth filter
###
### pip3 install matplotlib numpy scipy pydub
###

## system for command-line arguments
import sys

## matplotlib
import matplotlib
# configure to use Tk canvas
matplotlib.use('Agg')

import matplotlib.pyplot as plt
import numpy as np
import json, codecs

from scipy import signal
from scipy.io import wavfile

from scipy.fftpack import fft, fftfreq
from pydub import AudioSegment

## input
narg = len(sys.argv)

if narg > 1:
  filename = sys.argv[1]
else:
  filename = "square"

if narg > 2:
  butter_level = float(sys.argv[2])
else:
  butter_level = 0.05

if narg > 3:
  print(sys.argv[:])
  if sys.argv[3] != '':
    butter_priors = json.loads(sys.argv[3])
  else:
    butter_priors = list()
else:
  butter_priors = list()

if len(butter_priors) < 1:
  butter_priors = json.loads("null")

## get file
wav_filename = filename + '.wav'
samplerate, raw = wavfile.read(wav_filename)

## size of raw data 
total_samples = len(raw)
limit = int((total_samples /2)-1)

## fft raw data
fft_abs = abs(fft(raw))
freqs = fftfreq(total_samples,1/samplerate)

## plot frequencies
plt.plot(freqs[:limit], fft_abs[:limit])
plt.savefig(filename + '-fft.png')

## dump fft 
freqs_list = freqs.tolist()
json.dump(freqs_list, codecs.open(filename + '-fft.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)

## BUTTERWORTH FILTER
b, a = signal.butter(3, butter_level)

# filter signal with with butter (b, a)
data_filtered = signal.filtfilt(b, a, raw)

## calculate new FFT
fft_abs_filtered = abs(fft(data_filtered))
freqs_filtered = fftfreq(total_samples,1/samplerate)

## plot butterworth PNG
plt.plot(freqs_filtered[:limit], fft_abs_filtered[:limit])
plt.savefig(filename + '-butter.png')

## dump butterworth data
freqs_list = freqs_filtered.tolist()
json.dump(freqs_list, codecs.open(filename + '-butter.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)
