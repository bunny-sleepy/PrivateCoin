pragma circom 2.2.0;

include "../../circomlib/circuits/sha256/sha256.circom";

// Define the IteratedHash template
template IteratedHash(num_iters, input_size, output_size) {
    signal input in[input_size];
    signal output out[output_size];

    component hasher[num_iters];
    for (var i = 0; i < num_iters; i++) {
        if (i == 0) {
            hasher[i] = Sha256(input_size);
            hasher[i].in <== in;
        } else {
            hasher[i] = Sha256(256);
            hasher[i].in <== hasher[i - 1].out;
        }
    }

    for (var j = 0; j < output_size; j++) {
        out[j] <== hasher[num_iters - 1].out[j];
    }
}

// Define the BigMerkle template
template BigMerkle(log_num_leaves, num_sha_iters_per_subcircuit, inner_hash_size) {
    // Calculate the number of leaves as 2^log_num_leaves
    var num_leaves = 1 << log_num_leaves;

    // Define the signal inputs, which are the leaf data for each leaf node
    signal input d[num_leaves][512]; // Each leaf is a 256-bit input (32 bytes)

    // Define the output signal for the root
    signal output root[inner_hash_size]; // Output root, truncated to `inner_hash_size` bits

    // Components for leaf hashing, applying iterative SHA256 on each leaf using IteratedHash
    component leaf_hasher[num_leaves];
    // Define components for each level of the Merkle tree
    component parent_hasher[log_num_leaves][num_leaves / 2];
    signal level_nodes[log_num_leaves][num_leaves][inner_hash_size];

    // Initialize leaf hasher components with IteratedHash
    for (var i = 0; i < num_leaves; i++) {
        leaf_hasher[i] = IteratedHash(num_sha_iters_per_subcircuit, 512, inner_hash_size);
        leaf_hasher[i].in <== d[i];

        // Assign the output to the leaf digest
        for (var k = 0; k < inner_hash_size; k++) {
            level_nodes[0][i][k] <== leaf_hasher[i].out[k];
        }
    }

    // Construct each level of the Merkle tree up to the root
    var cur_level_nodes = num_leaves;
    for (var lvl = 0; lvl < log_num_leaves; lvl++) {
        var next_level_nodes = (cur_level_nodes) / 2;

        for (var i = 0; i < next_level_nodes; i++) {
            // Initialize iterative hashing for each parent node
            parent_hasher[lvl][i] = IteratedHash(num_sha_iters_per_subcircuit, 2 * inner_hash_size, inner_hash_size);

            // Concatenate left and right children, duplicating left child if odd number
            for (var j = 0; j < inner_hash_size; j++) {
                parent_hasher[lvl][i].in[j] <== level_nodes[lvl][2 * i][j];
                parent_hasher[lvl][i].in[inner_hash_size + j] <== (2 * i + 1 < cur_level_nodes)
                    ? level_nodes[lvl][2 * i + 1][j]
                    : level_nodes[lvl][2 * i][j];
            }

            // Assign the output of the parent hash to the next level
            for (var k = 0; k < inner_hash_size; k++) {
                if (lvl == log_num_leaves - 1) {
                    // If this is the last level, assign the output to the root
                    root[k] <== parent_hasher[lvl][i].out[k];
                } else {
                    level_nodes[lvl + 1][i][k] <== parent_hasher[lvl][i].out[k];
                }
            }
        }

        cur_level_nodes = next_level_nodes;
    }
}

// Instantiate the main component
component main = BigMerkle(2, 2, 216); // Example usage with 2^2 (4) leaves, 2 iterations, 216-bit inner hash size
