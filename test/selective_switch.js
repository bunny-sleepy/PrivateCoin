const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const path = require("path");
const compiler = require("circom_tester").wasm;
const bigInt = require("big-integer");

const expect = chai.expect;

chai.should();
chai.use(chaiAsPromised);

describe("SelectiveSwitch", () => {
    var circ;

    before(async () => {
        circ = await compiler(
            path.join(__dirname, "circuits", "selective_switch.circom"));
    });

    it("should not switch when s = 0", async () => {
        const input = {
            "s": "0",
            "in0": "10",
            "in1": "11",
        };
        const witness = await circ.calculateWitness(input);
        await circ.assertOut(witness, {"out0": "10", "out1": "11"});
    });

    it("should switch when s = 1", async () => {
        const input = {
            "s": "1",
            "in0": "10",
            "in1": "11",
        };
        const witness = await circ.calculateWitness(input);
        await circ.assertOut(witness, {"out0": "11", "out1": "10"});
    });

    it("should enforce that s in {0, 1}", async () => {
        const input = {
            "s": "2",
            "in0": "10",
            "in1": "11",
        };
        await expect(circ.calculateWitness(input)).to.be.rejectedWith(
            "Error: Assert Failed."
        );
    });
});

