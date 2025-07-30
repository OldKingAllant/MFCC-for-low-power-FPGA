import numpy as np 

mfcc_lift = np.zeros((1, 16))

n = np.arange(1, mfcc_lift.shape[1] + 1)
D = 22
w = (1 + (D / 2) * np.sin(np.pi * n / D)) * (2**8)

for elem in w:
    elem = int(elem)
    print(f'{elem:x}', end=' ')
print()
