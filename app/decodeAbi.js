require("dotenv").config();
const Util = require("util");

const inputData = '';
const ethers = require("ethers");
const abi = new ethers.utils.Interface(require("./pancakePairABI.json"));
const decodedInput = abi.parseTransaction({
    data: inputData
  });

const amount0Out = ethers.utils.formatUnits(decodedInput.args['amount0Out'], "ether");
const amount1Out = ethers.utils.formatUnits(decodedInput.args['amount1Out'], "ether");
console.log(`Amount0Out: ${amount0Out}`);
console.log(`Amount1Out: ${amount1Out}`);
console.log(`To: ${decodedInput.args['to']}`);
console.log(`Call Data: ${decodedInput.args['data']}`);