import sys
import matplotlib.pyplot as plt
import numpy as np

if len(sys.argv) != 2:
    exit()

file = sys.argv[1]

def chunks(num_list, chunk_size):
    for i in range(0, len(num_list), chunk_size):
        yield num_list[i:i + chunk_size]

with open(file) as input_fd:
    values = []
    for line in input_fd:
        numbers = map(lambda string: float(string), line.split())
        values.extend(numbers)
    print(values)
    #np.set_printoptions(suppress=True)
    #for chunk in chunks(values, 16):
    #    print(chunk)
    np.savetxt(f'{sys.argv[1]}.csv', np.array(list(chunks(values, 16))), delimiter=',', fmt='%.2f')
    plt.plot(values)
    plt.show()
        
