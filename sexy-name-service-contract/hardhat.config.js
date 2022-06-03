require("@nomiclabs/hardhat-waffle");


module.exports = {
  solidity: "0.8.10",
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/buG7yaV1H1Ac8HCc6XirkcKvxmB7fVcU",
      accounts: ["YOUR ACCOUNT HERE"],
    }
  }
};