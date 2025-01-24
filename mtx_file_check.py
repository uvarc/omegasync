def validate_mtx_file(file_path):
    try:
        with open(file_path, 'r') as file:
            # Parse the file
            lines = file.readlines()

        # Extract the first line for metadata
        size_line = lines[0].strip()
        edge_lines = lines[1:]

        # Parse number of nodes and edges
        num_nodes, num_edges = map(int, size_line.split())

        # Parse the edges
        edges = []
        for edge_line in edge_lines:
            parts = list(map(int, edge_line.split()))
            if len(parts) != 3:
                raise ValueError(f"Invalid edge format: {edge_line}")
            if parts[2] == 0:
                raise ValueError(f"Zero weight found at edge: {edge_line}")
            edges.append(tuple(parts))

        # Validation checks
        validate_repeated_edges(edges)
        validate_duplicate_edges(edges)
        validate_self_loops(edges)
        validate_edge_weights(edges)


        return "The .mtx file passed all validation checks."
    except Exception as e:
        return f"Validation Error: {e}"


def validate_repeated_edges(edges):
    edge_set = set()
    for row, col, value in edges:
        edge = (min(row, col), max(row, col))
        if edge in edge_set:
            raise ValueError(f"Repeated edge found: {edge}")
        edge_set.add(edge)


def validate_duplicate_edges(edges):
    edge_set = set()
    for row, col, value in edges:
        edge = (row, col)
        if edge in edge_set:
            raise ValueError(f"Duplicate edge found: {edge}")
        edge_set.add(edge)



def validate_self_loops(edges):
    for row, col, value in edges:
        if row == col:
            print(f"Self-loop found at node: {row}")


def validate_edge_weights(edges):
    for row, col, value in edges:
        if not isinstance(row, int) or not isinstance(col, int):
            raise ValueError(f"Invalid node types at edge ({row}, {col}): Nodes must be integers.")
        if not isinstance(value, (float, int)):
            raise ValueError(f"Invalid weight type {value} at edge ({row}, {col}): Weights must be numeric.")
        if value == 0:
            raise ValueError(f"Zero weight found at edge ({row}, {col}).")



