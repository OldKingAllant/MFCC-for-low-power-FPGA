import sys
import statistics
from scipy.stats.mstats import gmean
import numpy as np

if len(sys.argv) != 3:
    exit()

numframes = 1

with open(sys.argv[1]) as python_fd, open(sys.argv[2]) as vhdl_fd:
    python_vals = []
    for line in python_fd:
        python_vals.extend(map(lambda string: float(string), line.split()))
    python_vals = python_vals[0:16*numframes]
    print(python_vals)
    vhdl_vals = []
    for line in vhdl_fd:
        vhdl_vals.extend(map(lambda string: float(string), line.split()))
    vhdl_vals = vhdl_vals[0:16*numframes]
    print(vhdl_vals)
    if len(python_vals) != len(vhdl_vals):
        print("Size mismatch")
        exit()
    absolute_errors = []
    percent_errors = []
    for correct, approx in zip(python_vals, vhdl_vals):
        diff = correct - approx
        absolute_errors.append(diff)
        percent = (1-(correct/approx))*100
        percent_errors.append(percent)
    print(absolute_errors)
    print(percent_errors)
    print("Max absolute error: " + str(np.max(np.absolute(absolute_errors))))
    print("Max percent error: " + str(np.max(np.absolute(percent_errors))))
    print("Error mean: " + str(statistics.mean(percent_errors)))
    print("Error std: " + str(statistics.stdev(percent_errors)))
    
