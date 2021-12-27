module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const bsc_mainnet_chiToken = "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c";
    await deploy("Arbitrage", {
      from: deployer,
      log: true,
      args: [bsc_mainnet_chiToken]
    });
  };
  module.exports.tags = ["Arbitrage"];
  