
import numpy as np
import matplotlib.pyplot as plt
from librosa.feature import mfcc
import seaborn as sns

fft_size = 512
wave = [32767.0 if i > (fft_size / 2)-3 and  i < (fft_size / 2)+3 else 0.0 for i in range(fft_size)]

wave_temp = wave.copy()
wave = []
wave.extend(wave_temp)
wave.extend(wave_temp)

features = mfcc(y=np.array(wave), sr=16000, n_mfcc=16, lifter=22, n_fft=512, \
                hop_length=170, n_mels=16, fmin=50, fmax=6500, htk=False)

test = features[:,0:4]

#sns.heatmap(test)

x_axis = [i for i in range(len(features[:,3]))]

plt.plot(x_axis, features[:,3])
plt.show()

