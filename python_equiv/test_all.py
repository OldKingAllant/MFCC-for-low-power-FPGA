import numpy as np
import matplotlib.pyplot as plt
import math
from scipy.fftpack import dct

fft_size = 512
wave = [32767 if i > (fft_size / 2)-3 and  i < (fft_size / 2)+3 else 0 for i in range(fft_size)]

signal = []
signal.extend(wave)
signal.extend(wave)
signal.extend(wave)
signal.extend(wave)

total_frames = len(signal) // fft_size
frame_step = 170

frames = []
curr_frame_start = 0
for _ in range(total_frames):
    frame = []
    for index in range(fft_size):
        frame.append(float(signal[curr_frame_start + index]))
    frames.append(frame)
    curr_frame_start += 170

#####################################
frames = np.array(frames)

window_length = frames.shape[1]
n = np.arange(0, window_length)

# set window coefficients
h = 0.54 - 0.46 * np.cos(2 * np.pi * n / (window_length - 1))

# perform windowing
frames *= h
#frames /= 256
##################################

frames_fft = []
for frame in frames:
    fft_frame = np.fft.fft(frame)
    fft_frame.real = fft_frame.real* fft_frame.real
    fft_frame.imag = fft_frame.imag * fft_frame.imag
    magnitudes = fft_frame.real + fft_frame.imag
    magnitudes /= fft_size // 2
    magnitudes *= 256
    frames_fft.append(magnitudes)

print(len(frames_fft[0]))

###################################

def hz2mel(f):
    return 2595 * math.log10(1.0 + f / 700.0)

def mel2hz(mel):
    return 700.0 * (10.0**(mel / 2595.0) - 1.0)

numfilters = 16
lowf = hz2mel(50)
highf = hz2mel(6500)
sf = 16000
nfft = 257
precision = 8
centre_freqs = [mel2hz(lowf + (highf - lowf)/(numfilters + 1)*i) for i in range(numfilters + 2)]
fft_bin_freqs = [sf/2.0/(nfft - 1)*i for i in range(nfft)]

fbank = []
for filt in range(numfilters):
    curr_filter = []
    for i in range(nfft):
        if fft_bin_freqs[i] < centre_freqs[filt]:
            curr_filter.append(0)
        elif fft_bin_freqs[i] <= centre_freqs[filt + 1]:
            curr_filter.append((fft_bin_freqs[i] - centre_freqs[filt]) / (centre_freqs[filt + 1] - centre_freqs[filt]))
        elif fft_bin_freqs[i] <= centre_freqs[filt + 2]:
            curr_filter.append((centre_freqs[filt + 2] - fft_bin_freqs[i]) / (centre_freqs[filt + 2] - centre_freqs[filt + 1]))
        else:
            curr_filter.append(0)
    fbank.append(curr_filter)

frame_coeffs = []
for frame in frames_fft:
    coeffs = []
    for i in range(len(fbank)):
        coeffs.append(0)
        for j in range(len(fbank[0])):
            coeffs[i] += fbank[i][j] * frame[j]
        if coeffs[i] < 1.0:
            coeffs[i] = 1.0
    frame_coeffs.append(coeffs)

#####################################

log_frames = np.log10(frame_coeffs)


#####################################

frames_dct = np.array(dct(log_frames, 2))

#####################################

lifted_coeffs = np.zeros(frames_dct.shape)

n = np.arange(1, lifted_coeffs.shape[1] + 1)
D = 22
w = 1 + (D / 2) * np.sin(np.pi * n / D)

# lift coefficients
lifted_coeffs = frames_dct * w

print(lifted_coeffs)

#####################################

final_coeffs = lifted_coeffs.flatten()   
x_axis = [i for i in range(len(final_coeffs))]

#final_coeffs = np.array(frame_coeffs).flatten()   
#x_axis = [i for i in range(len(final_coeffs))]

plt.plot(x_axis, final_coeffs)
plt.show()

