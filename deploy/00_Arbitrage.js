module.exports = async ({ getNamedAccounts, deployments, getChainId}) => {
  const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId  = await getChainId();
    
    // ChiToken only seems to work correctly on mainnet, due to assembly usage
    let chiToken;
    if (chainId == 56) { 
      chiToken = "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c";
    } else if (chainId == 97) {
      chiToken = "0x83a23e36ca483779704378aa0573c4e0f37d729e";
    } else {
      console.log("Unknown ChainId - try again");
      process.exit();
    }
    
    // array of whitelisted wallets who also can swap
    // Contract deployer wallet is automatically whitelisted on contract creation
    // Notice:  All swapped funds are sent to contract and onlyOwner can withdraw
    const arbWallets = []; 
    await deploy("Arbitrage", {
      from: deployer,
      log: true,
      args: [chiToken, arbWallets]
    });
  };
  module.exports.tags = ["Arbitrage"];
  