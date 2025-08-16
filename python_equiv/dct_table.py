import numpy as np
from scipy.fftpack import fft, dct

def discrete_cos_transformation(precision):
    """
    Applies DCT to input frames

    :param frames: Input frames
    :return: DCT frames
    """

    rows, cols = (1, 16)

    N = cols
    n = np.arange(1, N + 1)

    weights = np.zeros((N, N))
    for k in np.arange(0, N):
        weights[:, k] = np.sqrt(2/N) * np.cos(np.pi * (n - 1 / 2) * k / N) * (2**precision)

    for row in weights:
        for weight in row:
            print(f'{int(weight)}', end=' ')
        print()
    return


values = [i*256 for i in range(0, 16)]
frames = np.array(values)
print(frames)

discrete_cos_transformation(8)

#print('\n\n')
#print(dct_res / 2**32)
#for elem in dct_res:
#    elem = int(elem)
#    print(f'{elem:x}')

print(dct(frames, 2) / 2**8)
