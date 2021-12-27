// XXX Not used any more - we now use hardhat-deploy 

const { ethers } = require("hardhat");
const fs = require('fs');

const main = async () => {
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with the account: ${deployer.address}`);

    const balance = await deployer.getBalance();
    console.log(`Account balance: ${balance.toString()}`);

    const Arbitrage = await ethers.getContractFactory('Arbitrage');
    const arbitrage= await Arbitrage.deploy();
    console.log(`Contract address: ${arbitrage.address}`);

    console.log(`contract address: ${arbitrage.address}`);
console.log(`deployer address: ${arbitrage.deployTransaction.from}`);
console.log(`gas price: ${arbitrage.deployTransaction.gasPrice}`);
console.log(`gas used: ${arbitrage.deployTransaction.gasLimit}`);
    
    // const estimatedGas = await deployer.estimateGas(token)
    // console.log(`Gas: ${estimatedGas}`);

    const data = {
        address: arbitrage.address,
        abi: JSON.parse(arbitrage.interface.format('json'))
    };
    fs.writeFileSync('deployedArbitrage.json', JSON.stringify(data));
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
