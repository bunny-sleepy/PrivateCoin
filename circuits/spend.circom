pragma circom 2.1.0;

include "./mimc.circom";

/*
 * IfThenElse sets `out` to `true_value` if `condition` is 1 and `out` to
 * `false_value` if `condition` is 0.
 *
 * It enforces that `condition` is 0 or 1.
 *
 */
template IfThenElse() {
    signal input condition;
    signal input true_value;
    signal input false_value;
    signal output out;

    // implementation
    signal tmp;
    condition * (condition - 1) === 0;
    tmp <== condition * true_value;
    out <== tmp + (1 - condition) * false_value;
}

/*
 * SelectiveSwitch takes two data inputs (`in0`, `in1`) and produces two outputs.
 * If the "select" (`s`) input is 1, then it inverts the order of the inputs
 * in the ouput. If `s` is 0, then it preserves the order.
 *
 * It enforces that `s` is 0 or 1.
 */
template SelectiveSwitch() {
    signal input in0;
    signal input in1;
    signal input s;
    signal output out0;
    signal output out1;

    // implementation
    s * (s - 1) === 0;

    component comp0 = IfThenElse();
    comp0.condition <== s;
    comp0.true_value <== in1;
    comp0.false_value <== in0;

    component comp1 = IfThenElse();
    comp1.condition <== 1 - s;
    comp1.true_value <== in1;
    comp1.false_value <== in0;

    out0 <== comp0.out;
    out1 <== comp1.out;
}

/*
 * Verifies the presence of H(`nullifier`, `nonce`) in the tree of depth
 * `depth`, summarized by `digest`.
 * This presence is witnessed by a Merkle proof provided as
 * the additional inputs `sibling` and `direction`, 
 * which have the following meaning:
 *   sibling[i]: the sibling of the node on the path to this coin
 *               at the i-th level from the bottom.
 *   direction[i]: "0" or "1" indicating whether that sibling is on the left.
 *       The "sibling" hashes correspond directly to the siblings in the
 *       SparseMerkleTree path.
 *       The "direction" keys the boolean directions from the SparseMerkleTree
 *       path, casted to string-represented integers ("0" or "1").
 */
template Spend(depth) {
    signal input digest;
    signal input nullifier;
    signal input nonce; // private
    signal input sibling[depth]; // private
    signal input direction[depth]; // private
    // hashers for merkle tree
    component hasher[depth];
    // hasher for merkle leaf
    component hasher_leaf = MiMC2();
    // selective switchers for merkle tree
    component switcher[depth];
    // initialize components
    for (var i = 0; i < depth; i++) {
        hasher[i] = MiMC2();
        switcher[i] = SelectiveSwitch();
    }
    // assign leaf hashes
    hasher_leaf.in0 <== nullifier;
    hasher_leaf.in1 <== nonce;
    // assign path hashes
    for (var i = 0; i < depth; i++) {
        if (i == 0) {
            switcher[i].in0 <== hasher_leaf.out;
        } else {
            switcher[i].in0 <== hasher[i - 1].out;
        }
        switcher[i].in1 <== sibling[i];
        switcher[i].s <== direction[i];
        hasher[i].in0 <== switcher[i].out0;
        hasher[i].in1 <== switcher[i].out1;
    }
    if (depth == 0) {
        digest === hasher_leaf.out;
    } else {
        digest === hasher[depth - 1].out;
    }
}

// template test() {
//     signal input a;
//     signal input b;
//     signal input c;
//     signal tmp;
//     tmp <-- (a & 1) * b;
//     c === tmp;
// }

// component main {public [digest,nullifier]} = Spend(10);