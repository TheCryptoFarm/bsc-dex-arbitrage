require("dotenv").config();

const ethers = require("ethers");
const WalletHelper = require("./helpers/wallet.helper");

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC);
const wallet = WalletHelper.getWallet();
const account = wallet.connect(provider);
const arbABI = new ethers.utils.Interface(require("./arbABI.json"));
const arbContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, arbABI, account);

const get = async () => {
    try {
        let fees = [];
        fees.push(process.env.FEES);
        let tx = await arbContract.hawk(
            ethers.utils.parseUnits(process.env.PURCHASE_AMOUNT, "ether"),
            process.env.TOKEN_BASE,
            process.env.TOKEN_TARGET,
            process.env.ROUTER,
            fees,
            Date.now() + 1000 * process.env.DEADLINE,
            {
                gasLimit: process.env.GAS_LIMIT,
                gasPrice: ethers.utils.parseUnits(process.env.GAS_PRICE, "gwei"),
            }
        );
        console.log("TxHash: " + tx.hash);
        console.log("-FIN-");
        process.exit();
    } catch (e) {
        console.log(e);
    }
};
get();
