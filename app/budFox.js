require("dotenv").config();

const ethers = require("ethers");
const WalletHelper = require("./helpers/wallet.helper");

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC);
const wallet = WalletHelper.getWallet();
const account = wallet.connect(provider);
const arbABI = new ethers.utils.Interface(require("./arbABI.json"));
const arbContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, arbABI, account);

const budFox = async () => {
    try {
        const path = [
            "0xae13d989dac2f0debff460ac112a837c89baa7cd",
            "0x8babbb98678facc7342735486c851abd7a0d17ca",
            "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7",
        ];
        const pairPath = [
            "0xb27F628C12573594437B180A1eA1542d15E0cb78",
            "0x6a9D99Db0bD537f3aC57cBC316A9DD8b11A703aC"
        ];
        const fees = [25, 25];

        let tx = await arbContract.budFox(
            ethers.utils.parseUnits(process.env.PURCHASE_AMOUNT, "ether"),
            0,
            path,
            pairPath,
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
budFox();
