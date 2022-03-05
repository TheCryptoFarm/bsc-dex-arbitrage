require("dotenv").config();

const ethers = require("ethers");
const WalletHelper = require("./helpers/wallet.helper");

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC);
const wallet = WalletHelper.getWallet();
const account = wallet.connect(provider);
const arbABI = new ethers.utils.Interface(require("./arbABI.json"));
const arbContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, arbABI, account);

const TOKEN = ""; // Address
const amount = ethers.parseUnits("1", "18"); // Watch Decimals

const funds = async () => {
    try {
        let tx = await arbContract.withdraw(amount, TOKEN, false);
        console.log("TxHash: " + tx.hash);
        console.log("-FIN-");
        process.exit();
    } catch (e) {
        console.log(e);
    }
};
funds();
