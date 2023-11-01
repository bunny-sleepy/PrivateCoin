const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const path = require("path");
const fs = require("fs");
const compiler = require("circom_tester").wasm;

const expect = chai.expect;

chai.should();
chai.use(chaiAsPromised);

describe("Spend", () => {
    const tests = [
        { id: 0, depth: 0 },
        { id: 1, depth: 4 },
        { id: 2, depth: 25 },
    ];
    for (const { id, depth } of tests) {
        it(`witness computable for depth ${id}`, async () => {
            const circ = await compiler(
                path.join(__dirname, "circuits", `spend${depth}.circom`));
            const inPath = path.join(
                __dirname, "compute_spend_inputs", `out${id}.txt`)
            const input = JSON.parse(fs.readFileSync(inPath, { encoding: 'utf8' }));
            const witness = await circ.calculateWitness(input);
        });
     }
    it(`witness not computable for bad input`, async () => {
        const circ = await compiler(
                path.join(__dirname, "circuits", `spend25.circom`));
        const inPath = path.join(
            __dirname, "compute_spend_inputs", `out-bad.txt`)
        const input = JSON.parse(fs.readFileSync(inPath, { encoding: 'utf8' }));
        await expect(circ.calculateWitness(input)).to.be.rejectedWith(
            "Error: Assert Failed."
        );
    });
});