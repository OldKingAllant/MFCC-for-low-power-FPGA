import numpy as np
import matplotlib.pyplot as plt

fft_size = 512
wave = [32767 if i > (fft_size / 2)-3 and  i < (fft_size / 2)+3 else 0 for i in range(fft_size)]

print(wave)

tst = list(map(np.int32, wave))
dout_scipy = np.fft.fft(tst)
dout_scipy.real = dout_scipy.real* dout_scipy.real
dout_scipy.imag = dout_scipy.imag * dout_scipy.imag
sum_re_im = dout_scipy.real + dout_scipy.imag
plt.plot(sum_re_im)
plt.show()
