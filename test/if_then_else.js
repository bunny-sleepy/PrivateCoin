const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const path = require("path");
const compiler = require("circom_tester").wasm;
const bigInt = require("big-integer");

const expect = chai.expect;

chai.should();
chai.use(chaiAsPromised);

describe("IfThenElse", () => {
    var circ;

    before(async () => {
        circ = await compiler(
            path.join(__dirname, "circuits", "if_then_else.circom"));
    });

    it("should give `false_value` when `condition` = 0", async () => {
        const input = {
            "condition": "0",
            "false_value": "10",
            "true_value": "11",
        };
        const witness = await circ.calculateWitness(input);
        await circ.assertOut(witness, {"out": "10"});
    });

    it("should give `true_value` when `condition` = 1", async () => {
        const input = {
            "condition": "1",
            "false_value": "10",
            "true_value": "11",
        };
        const witness = await circ.calculateWitness(input);
        await circ.assertOut(witness, {"out": "11"});
    });

    it("should enforce that s in {0, 1}", async () => {
        const input = {
            "condition": "2",
            "false_value": "10",
            "true_value": "11",
        };
        await expect(circ.calculateWitness(input)).to.be.rejectedWith(
            "Error: Assert Failed."
        );
    });
});

