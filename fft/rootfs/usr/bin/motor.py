#!/usr/bin/python3

###
### motor.py - perform FFT on WAV and calculate Welch power spectral density; compare current to prior:
###
### - prior[0]: frequency bin 1
### - prior[1]: frequency signal 1
### - prior[2]: frequency bin 2
### - prior[3]: frequency signal 2
### - prior[4]: previous bin 1 test result (unused)
### - prior[5]: previous signal 1 test result (unused)
### - prior[6]: previous bin 2 test result (unused)
### - prior[7]: previous signal 2 test result (unused)
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
  motor_delta = float(sys.argv[2])
else:
  motor_delta = 0.2

if narg > 3:
  if sys.argv[3] != '':
    motor_priors = json.loads(sys.argv[3])
  else:
    motor_priors = list()
else:
  motor_priors = list()

if len(motor_priors) < 1:
  motor_priors = json.loads("[999,0.99,2999,0.09]")

## get file
wav_filename = filename + '.wav'
samplerate, raw = wavfile.read(wav_filename)
    
## size of data
total_samples = len(raw)
limit = int((total_samples /2)-1)

## calculate Welch
bins, scores = signal.welch(raw, fs=samplerate, window="hanning", nperseg=128, noverlap=None, nfft=None, detrend="constant", return_onesided=True, scaling="density", axis=-1)

## transpose and sort descending
bin_scores = bins, scores
bin_scores = np.transpose(bin_scores)
bin_score_sorted = bin_scores[bin_scores[:,1].argsort()]
bin_score_sorted[:] = bin_score_sorted[::-1]

#TEST F1 Change
if motor_priors[0] != bin_score_sorted[0][0]:
  bin1 = 'true'
else:
  bin1 = 'false'
delta = (abs(motor_priors[1] - bin_score_sorted[0][1]) / motor_priors[1])
if delta > motor_delta:
  signal1 = 'true'
else:
  signal1 = 'false'

# TEST F2 Change
if motor_priors[2] != bin_score_sorted[1][0]:
  bin2 = 'true'
else:
  bin2 = 'false'
delta = (abs(motor_priors[3] - bin_score_sorted[1][1]) / motor_priors[3])
if delta > motor_delta:
  signal2 = 'true'
else:
  signal2 = 'false'

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
plt.savefig(filename + '-motor.png')

## dump data
data_list = bin_score_sorted[0][0],bin_score_sorted[0][1],bin_score_sorted[1][0],bin_score_sorted[1][1],bin1,signal1,bin2,signal2
json.dump(data_list, codecs.open(filename + '-motor.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)
