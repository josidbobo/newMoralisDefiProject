require("@nomicfoundation/hardhat-toolbox");

//require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  optimizer: 200,
  solidity: {
    compilers: [
      {version: "0.6.7"}, 
      {version: "0.8.9"},
      {version: "0.8.3"}
    ],
  },
  networks: {
    testnetBinance: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      accounts: [process.env.Private_key],
      networkId: 97,
    }
     
  }
};
