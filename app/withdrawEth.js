require("dotenv").config();

const ethers = require("ethers");
const WalletHelper = require("./helpers/wallet.helper");

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC);
const wallet = WalletHelper.getWallet();
const account = wallet.connect(provider);
const arbABI = new ethers.utils.Interface(require("./arbABI.json"));
const arbContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, arbABI, account);
const WBNB = {
    97: { // BSC Testnet
        address: "0xae13d989dac2f0debff460ac112a837c89baa7cd"
    },
    56: { // BSC Mainnet
        address: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    }
}

// Amount to withdraw
const amount = ethers.parseEther("1");

const funds = async () => {
    const { chainId } = await provider.getNetwork();
    try {
        let tx = await arbContract.withdraw(amount, WBNB[chainId].address, true);
        console.log("TxHash: " + tx.hash);
        console.log("-FIN-");
        process.exit();
    } catch (e) {
        console.log(e);
    }
};
funds();
