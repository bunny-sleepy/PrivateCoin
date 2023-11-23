POT_PATH=./powers_of_tau/powersOfTau
ARTIFACT_PATH=./artifacts
# change name HERE
CIRCUIT_PATH=./test/circuits
CIRCUIT_NAME=spend10
ORDER=13

0_1_compile:
	cd ${CIRCUIT_PATH} && circom ${CIRCUIT_NAME}.circom --r1cs --sym --wasm && cd ..

0_2_ptau:
	snarkjs powersoftau new bn128 ${ORDER} ${POT_PATH}_${ORDER}_0.ptau -v && snarkjs powersoftau prepare phase2 ${POT_PATH}_${ORDER}_0.ptau ${POT_PATH}_${ORDER}.ptau -v

0_3_zkey:
	snarkjs zkey new ${CIRCUIT_PATH}/${CIRCUIT_NAME}.r1cs ${POT_PATH}_${ORDER}.ptau ${ARTIFACT_PATH}/${CIRCUIT_NAME}_0.zkey -v

0_4_contribute:
	snarkjs zkey contribute -verbose ${ARTIFACT_PATH}/${CIRCUIT_NAME}_0.zkey ${ARTIFACT_PATH}/${CIRCUIT_NAME}.zkey -n="First phase2 contribution" -e="Wenhao"

0_5_verify:
	snarkjs zkey verify -verbose ${CIRCUIT_PATH}/${CIRCUIT_NAME}.r1cs ${POT_PATH}_${ORDER}.ptau ${ARTIFACT_PATH}/${CIRCUIT_NAME}.zkey

0_6_export:
	snarkjs zkey export verificationkey ${ARTIFACT_PATH}/${CIRCUIT_NAME}.zkey ./artifacts/verification_key_${CIRCUIT_NAME}.json -v

1_1_witness:
	node ${CIRCUIT_PATH}/${CIRCUIT_NAME}_js/generate_witness.js ${CIRCUIT_PATH}/${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm ./artifacts/input_${CIRCUIT_NAME}.json ./artifacts/witness_${CIRCUIT_NAME}.wtns

1_2_proof:
	snarkjs groth16 prove ${ARTIFACT_PATH}/${CIRCUIT_NAME}.zkey ${ARTIFACT_PATH}/witness_${CIRCUIT_NAME}.wtns ${ARTIFACT_PATH}/proof_${CIRCUIT_NAME}.json ${ARTIFACT_PATH}/public_${CIRCUIT_NAME}.json

1_3_verify:
	snarkjs groth16 verify ${ARTIFACT_PATH}/verification_key_${CIRCUIT_NAME}.json ${ARTIFACT_PATH}/public_${CIRCUIT_NAME}.json ${ARTIFACT_PATH}/proof_${CIRCUIT_NAME}.json

r1cs_info:
	snarkjs r1cs info ${CIRCUIT_PATH}/$(CIRCUIT_NAME).r1cs

clean: clean-npm
	echo "Done"

clean-npm:
	rm -rf node_modules && rm package-lock.json

bundle: clean
	rm -f project.zip && zip -r project.zip package.json src test circuits artifacts Makefile
