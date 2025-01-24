import numpy as np
import pandas as pd
import mtx_file_check as file_check
import sys
import json

# Input and output file paths
input_file = sys.argv[1]
output_file = sys.argv[1]
result=file_check.validate_mtx_file(input_file)

if "Validation Error" in result:
    data = [result, 8, 5]
    json_data = json.dumps(data)
    print(json_data)
    sys.exit()

# Read the file and separate metadata and edges
with open(input_file, 'r') as file:
    lines = file.readlines()

# Extract metadata (first row)
metadata = lines[0].strip().split()
num_nodes = int(metadata[0])
num_edges = int(metadata[1])

# Extract edges
edges = []
for line in lines[1:]:
    edges.append(list(map(int, line.strip().split())))

data = np.array(edges)

# Interchange the first and second columns
data[:, [0, 1]] = data[:, [1, 0]]

# Change the third column (weights) to negative if it exists
#if data.shape[1] == 3:
#    data[:, 2] = data[:, 2] * -1

# Sort rows by column 2, then by column 1
data = data[np.lexsort((data[:, 0], data[:, 1]))]

# Write the Matrix Market file
with open(output_file, 'w') as f:
    # Write the Matrix Market header
    f.write('%MatrixMarket matrix coordinate integer symmetric\n')
    f.write('% Graph adjacency matrix generated from edge list sorted by column 2 with negative weights\n')

    # Write the size of the matrix and the number of non-zero entries (edges)
    f.write(f'{num_nodes} {num_nodes} {num_edges}\n')

    # Write the edges to the file
    for edge in data:
        f.write(f'{edge[0]} {edge[1]} {edge[2]}\n')

data = [result, 8, 5]
json_data = json.dumps(data)
print(json_data)
