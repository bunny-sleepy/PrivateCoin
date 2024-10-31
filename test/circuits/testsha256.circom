pragma circom 2.2.0;

include "../../circomlib/circuits/sha256/sha256.circom";

template BigMerkle(log_num_leaves, num_sha_iters_per_subcircuit, inner_hash_size) {
    // Calculate the number of leaves as 2^log_num_leaves
    var num_leaves = 1 << log_num_leaves;

    // Define the signal inputs, which are the leaf data for each leaf node
    signal input d[num_leaves][256]; // Each leaf is a 256-bit input (32 bytes)

    // Define the output signal for the root
    signal output root[inner_hash_size]; // Output root, truncated to `inner_hash_size` bits

    // Components for leaf hashing, to apply iterative SHA256 on each leaf
    component leaf_hasher[num_leaves][num_sha_iters_per_subcircuit];
    signal leaf_digests[num_leaves][inner_hash_size];

    // Define all components for each level in advance
    // Since `log_num_leaves` is the depth, we need exactly `log_num_leaves` levels
    component parent_hash[log_num_leaves][num_leaves / 2];
    signal level_nodes[log_num_leaves + 1][num_leaves][inner_hash_size];

    // Initialize the leaf hasher components and calculate digests
    for (var i = 0; i < num_leaves; i++) {
        for (var j = 0; j < num_sha_iters_per_subcircuit; j++) {
            leaf_hasher[i][j] = Sha256(256); // Each Sha256 component takes 256 bits (32 bytes) input
            if (j > 0) {
                // Chain the hash outputs as input to the next iteration
                leaf_hasher[i][j].in <== leaf_hasher[i][j - 1].out;
            } else {
                // Initial input to the first iteration for each leaf
                leaf_hasher[i][j].in <== d[i];
            }
        }
        // Assign the final output of each iterated hash, truncated to `inner_hash_size` bits, to the leaf digest
        for (var k = 0; k < inner_hash_size; k++) {
            level_nodes[0][i][k] <== leaf_hasher[i][num_sha_iters_per_subcircuit - 1].out[k];
        }
    }

    // Construct each level of the Merkle tree up to the root
    var cur_level_nodes = num_leaves;
    for (var lvl = 0; lvl < log_num_leaves; lvl++) {
        var next_level_nodes = (cur_level_nodes) / 2;

        for (var i = 0; i < next_level_nodes; i++) {
            parent_hash[lvl][i] = Sha256(2 * inner_hash_size);

            // Access left_child and right_child directly from level_nodes to avoid dimension issues
            for (var j = 0; j < inner_hash_size; j++) {
                // Left child
                parent_hash[lvl][i].in[j] <== level_nodes[lvl][2 * i][j];

                // Right child, duplicate left_child if there’s an odd number of nodes at this level
                parent_hash[lvl][i].in[inner_hash_size + j] <== (2 * i + 1 < cur_level_nodes)
                    ? level_nodes[lvl][2 * i + 1][j]
                    : level_nodes[lvl][2 * i][j];
            }

            // Assign the output of each parent hash, truncated to `inner_hash_size` bits, to the next level
            for (var k = 0; k < inner_hash_size; k++) {
                level_nodes[lvl + 1][i][k] <== parent_hash[lvl][i].out[k];
            }
        }

        cur_level_nodes = next_level_nodes;
    }

    // Set the root output to the first node in the final level (which is the root)
    for (var m = 0; m < inner_hash_size; m++) {
        root[m] <== level_nodes[log_num_leaves][0][m]; // Truncate if necessary to `inner_hash_size`
    }
}

// Instantiate the main component
component main = BigMerkle(2, 2, 216); // Example usage with 2^2 (4) leaves, 2 iterations, 216-bit inner hash size
