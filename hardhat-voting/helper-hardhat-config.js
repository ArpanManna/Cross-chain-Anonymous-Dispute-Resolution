const { ethers } = require("hardhat")

const networkConfig = {
    default: {
        name: "hardhat",
        keepersUpdateInterval: "30",
    },
    31337: {
        name: "localhost",
    },
    11155111: {
        name: "sepolia",
        router: "0x0bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59",
        linkAddress: "0x779877A7B0D9E8603169DdbD7836e478b4624789"
    },
    80001: {
        name: "mumbai",
        router: "0x1035cabc275068e0f4b745a29cedf38e13af41b1",
        linkAddress: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
    },
    43113: {
        name: "fuji",
        router: "0xf694e193200268f9a4868e4aa017a0118c9a8177",
        linkAddress: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"
    },
    1: {
        name: "mainnet",
        keepersUpdateInterval: "30",
    },
}

const developmentChains = ["hardhat", "localhost"]
const VERIFICATION_BLOCK_CONFIRMATIONS = 6
const frontEndContractsFile = "../nextjs-smartcontract-lottery-fcc/constants/contractAddresses.json"
const frontEndAbiFile = "../nextjs-smartcontract-lottery-fcc/constants/abi.json"

module.exports = {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
    frontEndContractsFile,
    frontEndAbiFile,
}
