module.exports = async ({ getNamedAccounts, deployments}) => {
  const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    // ChiToken only seems to work correctly on mainnet, due to assembly usage
    const bsc_mainnet_chiToken = "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c";
    // array of whitelisted wallets who also can swap
    // Contract deployer wallet is automatically whitelisted on contract creation
    // Notice:  All swapped funds are sent to contract and onlyOwner can withdraw
    const arbWallets = []; 
    await deploy("Arbitrage", {
      from: deployer,
      log: true,
      args: [bsc_mainnet_chiToken, arbWallets]
    });
  };
  module.exports.tags = ["Arbitrage"];
  