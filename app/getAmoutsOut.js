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
        const path = [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
            "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
          ];
          const pairPath = [
            "0x74E4716E431f45807DCF19f284c7aA99F18a4fbc",
            "0xA0C3Ef24414ED9C9B456740128d8E63D016A9e11"
          ];
        const fees = [25, 25];
        const amountIn = "1000000000000000000";
        const amounts = await arbContract.getAmountsOut(amountIn, path, pairPath, fees);
        console.log(amounts);
        const a0 = ethers.utils.formatUnits(amounts[0], "ether");
        const a1 = ethers.utils.formatUnits(amounts[1], "ether");
        const a2 = ethers.utils.formatUnits(amounts[2], "ether");
        console.log(a0);
        console.log(a1);
        console.log(a2);
        console.log("-FIN-");
        process.exit();
    } catch (e) {
        console.log(e);
    }
};
get();
