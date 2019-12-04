#!/usr/bin/python3

###
### welch.py - perform FFT on WAV and calculate Welch power spectral density
###
### pip3 install matplotlib numpy scipy pydub
###

## system
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
  welch_nperseg = int(sys.argv[2])
else:
  welch_nperseg = 128

if narg > 3:
  print(sys.argv[:])
  if sys.argv[3] != '':
    welch_priors = json.loads(sys.argv[3])
  else:
    welch_priors = list()
else:
  welch_priors = list()

if len(welch_priors) < 1:
  welch_priors = json.loads("null")

## get file
wav_filename = filename + '.wav'
samplerate, raw = wavfile.read(wav_filename)

## size of data
total_samples = len(raw)
limit = int((total_samples /2)-1)

## calculate Welch
bins, scores = signal.welch(raw, fs=samplerate, window="hanning", nperseg=welch_nperseg, noverlap=None, nfft=None, detrend="constant", return_onesided=True, scaling="density", axis=-1)

## plot fft
fft_abs = abs(fft(raw))
freqs = fftfreq(total_samples,1/samplerate)
plt.plot(freqs[:limit], fft_abs[:limit])
plt.savefig(filename + '-fft.png')

## dump fft
data_list = freqs.tolist()
json.dump(data_list, codecs.open(filename + '-fft.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)

## plot welch
plt.plot(bins[:limit],scores[:limit])
plt.savefig(filename + '-welch.png')

## dump bins
data_list = bins.tolist(), scores.tolist()
json.dump(data_list, codecs.open(filename + '-welch.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)
