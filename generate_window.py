import sys
import os
import numpy as np

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Invalid number of arguments")
        print(f"Usage: {sys.argv[0]} <type> <size> <precision> <output_file>")
        exit(0)
    size = int(sys.argv[2])
    precision = int(sys.argv[3])
    if sys.argv[1] == "hamming":
        ty = "hamming"
    elif sys.argv[1] == "hanning":
        ty = "hanning"
    else:
        print("Invalid window type")
        exit(0)
    print(f"Generate window of size {size}, type {ty}")
    if ty == "hamming":
        win = np.hamming(size)
    else:
        win = np.hanning(size)
    height = 2**(precision + 1) - 1 #Used to convert from float to int
    win = (win * height).astype(int)
    win.tofile(sys.argv[4], '\n', '%08x')
    
