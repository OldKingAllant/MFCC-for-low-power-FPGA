import matplotlib.pyplot as plt
import numpy as np
from scipy.fftpack import dct

frame_1 = [10.98046875, 11.02734375, 11.0703125, 11.10546875, 11.12890625, 11.140625, 11.1171875, 11.06640625, 10.953125, 10.75390625, 10.37890625, 9.6015625, 9.8125, 10.40234375, 10.5390625, 10.25]
frame_2 = [9.9765625, 10.0234375, 10.06640625, 10.1015625, 10.125, 10.1328125, 10.11328125, 10.05859375, 9.94921875, 9.74609375, 9.37109375, 8.59375, 8.8203125, 9.40234375, 9.5390625, 9.23828125]
frame_3 = [9.93359375, 9.98046875, 10.0234375, 10.05859375, 10.08203125, 10.09375, 10.0703125, 10.01953125, 9.91015625, 9.7109375, 9.33984375, 8.578125, 8.74609375, 9.33984375, 9.4765625, 9.18359375]
frame_4 = [10.984375, 11.02734375, 11.0703125, 11.10546875, 11.12890625, 11.140625, 11.1171875, 11.06640625, 10.953125, 10.75390625, 10.37890625, 9.59765625, 9.80859375, 10.40234375, 10.53515625, 10.23828125]

log_coeffs = np.array([frame_1, frame_2, frame_3, frame_4])

def discrete_cos_transformation(frames: np.array):
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
        weights[:, k] = np.sqrt(2/N) * np.cos(np.pi * (n - 1 / 2) * k / N)
    
    dct_signal = np.zeros((rows, N))

    for index, frame in enumerate(frames):
        for filt in range(len(weights[0])):
            for cepstra in range(len(weights)):
                dct_signal[index][cepstra] += weights[cepstra][filt] * frame[filt]
    #dct_signal = np.dot(frames, weights)

    return dct_signal

coeffs_dct = discrete_cos_transformation(log_coeffs)

lifted_coeffs = np.zeros(coeffs_dct.shape)

n = np.arange(1, lifted_coeffs.shape[1] + 1)
D = 22
w = 1 + (D / 2) * np.sin(np.pi * n / D)

# lift coefficients
lifted_coeffs = coeffs_dct * w

final_coeffs = lifted_coeffs.flatten()

for index, coeff in enumerate(coeffs_dct.flatten()):
    print(coeff)
    if index % 16 == 15 and index > 0:
        print('\n')

indices = [i for i in range(len(final_coeffs))]

plt.plot(indices, final_coeffs)
plt.show()
