import numpy as np
from scipy.fftpack import fft, dct

def discrete_cos_transformation(frames: np.array, precision):
    """
    Applies DCT to input frames

    :param frames: Input frames
    :return: DCT frames
    """

    rows, cols = frames.shape

    N = cols
    n = np.arange(1, N + 1)

    weights = np.zeros((N, N))
    for k in np.arange(0, N):
        weights[:, k] = np.sqrt(2/N) * np.cos(np.pi * (n - 1 / 2) * k / N) * (2**precision)
    
    dct_signal = np.zeros((N))
    for filt in range(len(weights[0])):
        for cepstra in range(len(weights)):
            dct_signal[cepstra] += int(weights[cepstra][filt]) * frames[0][filt]
    #dct_signal = np.dot(frames, weights)

    return dct_signal


frames = np.full((1, 16), 2**16)
print(frames)

dct_res = discrete_cos_transformation(frames, 16)

print('\n\n')
print(dct_res / 2**32)
#for elem in dct_res:
#    elem = int(elem)
#    print(f'{elem:x}')

print(dct(frames[0], 3, norm='ortho') / 2**16)
