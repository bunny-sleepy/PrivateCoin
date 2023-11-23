const { docopt } = require("docopt");
const { mimc2 } = require("./mimc.js");
const { SparseMerkleTree } = require("./sparse_merkle_tree.js");
const fs = require("fs");
const doc = `Usage:
  compute_spend_inputs.js [options] <depth> <transcript> <nullifier>
  compute_spend_inputs.js -h | --help

Options:
  -o <file>     name of the created witness file [default: input.json]
  -h --help     Print this message

Arguments:
   <depth>       The number of non-root layers in the merkle tree.
   <transcript>  The file containing transcript of all coins.
                 A file with a line for each coin.
                 Each coin is either a single number (the coin
                 itself) or it can be two space-separated number, which are, in
                 order, the nullifier and the nonce for the coin.

                 Example:

                     1839475893
                     1984375234 2983475298
                     3489725451 9834572345
                     3452345234

   <nullifier>   The nullifier to print a witness of validity for.
                 Must be present in the transcript.
`

/*
 * Computes inputs to the Spend circuit.
 *
 * Inputs:
 *   depth: the depth of the merkle tree being used.
 *   transcript: A list of all coins added to the tree.
 *               Each item is an array.
 *               If the array hash one element, then that element is the coin.
 *               Otherwise the array will have two elements, which are, in order:
 *                 the nullifier and
 *                 the nonce
 *               This list will contain **no** duplicate nullifiers or coins.
 *   nullifier: The nullifier to print inputs to validity verifier for.
 *              This nullifier will be one of the nullifiers in the transcript.
 *
 * Return:
 *   an object of the form:
 * {
 *   "digest"       : ...,
 *   "nullifier"    : ...,
 *   "nonce"        : ...,
 *   "sibling"      : [...],
 *   "direction"    : [...],
 * }
 * where each ... is a string-represented field element (number)
 *      and each [...] is an array of string-represented field elements
 * notes about each:
 *   "digest": the digest for the whole tree after the transcript is
 *       applied.
 *   "nullifier": the nullifier for the coin being spent.
 *   "nonce": the nonce for that coin
 *   "sibling": array of size depth, where the ith entry contains
 *       the sibling of the node on the path to this coin
 *       at the i'th level from the bottom.
 *   "direction": array of size depth, where the ith entry contains
*        "0" or "1" indicating whether that sibling is on the left.
 *       The "sibling" hashes correspond directly to the siblings in the
 *       SparseMerkleTree path.
 *       The "direction" keys the boolean directions from the SparseMerkleTree
 *       path, casted to string-represented integers ("0" or "1").
 */
function computeInput(depth, transcript, nullifier) {
    let merkle_tree = new SparseMerkleTree(depth);
    let nonce;
    for (let t of transcript) {
        if (t.length == 1) {
            merkle_tree.insert(t[0]);
        } else {
            merkle_tree.insert(mimc2(t[0], t[1]));
            if (t[0] == nullifier) {
                nonce = t[1];
            }
        }
    }
    let path = merkle_tree.path(mimc2(nullifier, nonce).toString());
    return {
        "digest"       : merkle_tree.digest,
        "nullifier"    : nullifier,
        "nonce"        : nonce,
        "sibling"      : path.map(node => node[0]),
        "direction"    : path.map(node => node[1] ? "1" : "0"),
    };
}

module.exports = { computeInput };

// If we're not being imported
if (!module.parent) {
    const args = docopt(doc);
    const transcript =
        fs.readFileSync(args["<transcript>"], { encoding: "utf8" } )
        .split(/\r?\n/)
        .filter(l => l.length > 0)
        .map(l => l.split(/\s+/));
    const depth = parseInt(args["<depth>"]);
    const nullifier = args["<nullifier>"];
    const input = computeInput(depth, transcript, nullifier);
    fs.writeFileSync(args["-o"], JSON.stringify(input) + "\n");
}
