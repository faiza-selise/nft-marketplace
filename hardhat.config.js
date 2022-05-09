require("@nomiclabs/hardhat-waffle");
const fs=require("fs");
const privatekey = fs.readFileSync(".secret").toString(); 

module.exports = {
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/hR6LH8un9K17bq9nGsvZ5Adg1KaZmXV9",
      accounts: [privatekey]
    },
    mainnet: {
      url: "",
      accounts: []
    }
  },
  solidity: "0.8.4",
};
