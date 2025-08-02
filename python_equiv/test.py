from core_functions.mfcc_utility_functions import mel_filter, discrete_cos_transformation, sin_liftering, stft, \
    signal_power_to_db
import numpy as np
import matplotlib.pyplot as plt

def mel_filter(frames, f_min, f_max, n_mels, fs):
    """
    Applies Mel filter to input spectrogram frames.

    :param frames: Input spectrogram frames
    :param f_min: Minimum frequency of Mel filter
    :param f_max: Maximum frequency of Mel filter
    :param n_mels: Number of filters in Mel filter
    :param fs: Sampling frequency
    :return: Mel filtered frames, start-end frequencies of each Mel filter
    """

    n_fft = frames.shape[0] - 1
    # convert Hz to Mel frequency
    mel_lf = 2595 * np.log10(1 + f_min / 700)
    mel_hf = 2595 * np.log10(1 + f_max / 700)

    mel_points = np.linspace(mel_lf, mel_hf, n_mels + 2)

    # convert back Mel to Hz
    hz_points = 700 * (np.power(10, mel_points / 2595) - 1)

    fft_bank_bin = np.floor((n_fft + 1) * hz_points / (fs / 2))
    fft_bank_bin[-1] = n_fft

    # create filter banks
    f_bank = np.zeros((n_mels, n_fft + 1))
    for i in np.arange(1, n_mels + 1):
        left_f = int(fft_bank_bin[i - 1])
        center_f = int(fft_bank_bin[i])
        right_f = int(fft_bank_bin[i + 1])

        for k in np.arange(left_f, center_f + 1):
            f_bank[i - 1, k] = (k - left_f) / (center_f - left_f)

        for k in np.arange(center_f, right_f + 1):
            f_bank[i - 1, k] = (-k + right_f) / (-center_f + right_f)

        # scale filter bank by its width
        f_bank[i - 1] /= (hz_points[i] - hz_points[i-1])

    # filter frames
    filtered_frames = np.dot(frames, f_bank.T)

    # correct 0 values
    filtered_frames += np.finfo(float).eps

    return filtered_frames, hz_points

fft_size = 512
wave = [32767 if i > (fft_size / 2)-3 and  i < (fft_size / 2)+3 else 0 for i in range(fft_size)]
dout_scipy = np.fft.fft(wave)
dout_scipy.real = dout_scipy.real* dout_scipy.real
dout_scipy.imag = dout_scipy.imag * dout_scipy.imag
sum_re_im = dout_scipy.real + dout_scipy.imag
sum_re_im /= 2**8

print(max(sum_re_im))

x_axis = [i for i in range(len(sum_re_im))]

plt.plot(x_axis, sum_re_im)
plt.show()

