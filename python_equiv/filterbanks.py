import numpy as np
import math

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
#print(centre_freqs)

fft_bin_freqs = [sf/2.0/(nfft - 1)*i for i in range(nfft)]
#print(fft_bin_freqs)

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
        #curr_filter[i] = curr_filter[i] * 2**precision
    fbank.append(curr_filter)

#print(fbank[0])

import matplotlib.pyplot as plt

fft_size = 512
wave = [32767 if i > (fft_size / 2)-3 and  i < (fft_size / 2)+3 else 0 for i in range(fft_size)]

tst = list(map(np.int32, wave))
dout_scipy = np.fft.fft(tst)
dout_scipy.real = dout_scipy.real* dout_scipy.real
dout_scipy.imag = dout_scipy.imag * dout_scipy.imag
sum_re_im = dout_scipy.real + dout_scipy.imag
sum_re_im = sum_re_im[0:257]
print(max(sum_re_im))

frame = sum_re_im

coeffs = []
for i in range(len(fbank)):
    coeffs.append(0)
    for j in range(len(fbank[0])):
        coeffs[i] += fbank[i][j] * frame[j]
    if coeffs[i] < 1.0:
        coeffs[i] = 1.0

#coeffs = [math.log10(coeff / 2**16) for coeff in coeffs]

for coeff in coeffs:
    coeff = coeff / 2**8
    print(f'{int(coeff):x}')

x_axis = [i for i in range(len(coeffs))]

plt.plot(x_axis, coeffs)
plt.show()


