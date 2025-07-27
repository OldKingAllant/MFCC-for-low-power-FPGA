import numpy as np
import numpy as np
import matplotlib.pyplot as plt

fft_size = 512
x = np.linspace(-1, 1, fft_size)
wave = np.cos(x)
#wave = np.concatenate((wave, np.cos(x)))

print(wave)

dout_scipy = np.fft.fft(wave)
dout_scipy.real = dout_scipy.real* dout_scipy.real
dout_scipy.imag = dout_scipy.imag * dout_scipy.imag
sum_re_im = dout_scipy.real + dout_scipy.imag
plt.plot(sum_re_im)
plt.show()
