const fs = require('fs');
const { ethers, utils } = require('ethers');

const standardPath = "m/44'/60'/0'/0";

class WalletHelper {
  constructor() {
    this.init();
  }

  init() {
    try {
      this.mnemonic = fs.readFileSync('../mnemonic.txt').toString().trim();
    } catch (e) {
      console.error("☢️ Error: No mnemonic.txt found!");
      process.exit();
    }
    this.masterNode = utils.HDNode.fromMnemonic(this.mnemonic);
  }

  getWallet() {
    return this.getWalletByIndex(0);
  }

  getWalletByIndex(index) {
    const path = `${standardPath}/${index}`;
    const key =  this.masterNode.derivePath(path);
    return new ethers.Wallet(key);
  }
}

module.exports = new WalletHelper();
