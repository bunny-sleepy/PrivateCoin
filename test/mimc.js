const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const path = require("path");
const snarkjs = require("snarkjs");
const compiler = require("circom_tester").wasm;
const bigInt = require("big-integer");
const { mimc2, mimc_cipher } = require("../src/mimc.js");

chai.should();

describe("MiMC2 function", () => {
    it("should run on integers", async () => {
        mimc2(0, 0)
    });
    it("should run on strings", async () => {
        mimc2("0", "1")
    });
    it("should run on big integers", async () => {
        mimc2(bigInt("0"), bigInt("1"))
    });
});

describe("MiMC(x^7) cipher circuit", () => {
    var mimc;

    before(async () => {
        mimc = await compiler(
            path.join(__dirname, "circuits", "mimc_cipher.circom"));
    });

    it("shouldn't crash when witnessing", async () => {
        const input = {
            "x_in": "0",
            "k": "0",
        };
        const witness = await mimc.calculateWitness(input);
    });

    it("should agree with the function on 0, 1", async () => {
        const input = {
            "x_in": "0",
            "k": "0",
        };
        const witness = await mimc.calculateWitness(input);
        const expected = mimc_cipher(bigInt(0n), bigInt(0n)).value;
        await mimc.assertOut(witness, {"out": expected});

    });
});

describe("MiMC2 circuit", () => {
    var mimc;

    before(async () => {
        mimc = await compiler(
            path.join(__dirname, "circuits", "mimc.circom"));
    });

    it("should have 364 constraints", async () => {
        await mimc.loadConstraints();
        mimc.constraints.length.should.equal(364);
    });

    it("shouldn't crash when witnessing", async () => {
        const input = {
            "in0": "0",
            "in1": "1",
        };
        const witness = await mimc.calculateWitness(input);
    });

    it("should agree with the function on 0, 1", async () => {
        const input = {
            "in0": "0",
            "in1": "1",
        };
        const witness = await mimc.calculateWitness(input);
        const expected = mimc2(0, 1);
        await mimc.assertOut(witness, {"out": expected});
    });
});
