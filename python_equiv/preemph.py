import numpy as np

test_samples = [32, 32, 32, 32]
prev_sample = 0

print(1.0 - (1.0 / 32))

for index in range(len(test_samples)):
    filtered = test_samples[index] - (1.0 - (1.0 / 32))*prev_sample
    prev_sample = test_samples[index]
    print(f'{int(filtered):x}')
