const { network, ethers } = require("hardhat")
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if (chainId == 31337) {
    } else {
    }
    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
    log("----------------------------------------------------")
    const arguments = [
        networkConfig[chainId]["router"],
        networkConfig[chainId]["linkAddress"],
    ]
    const voting = await deploy("Voting", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })


    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY && process.env.POLYGONSCAN_API_KEY) {
        log("Verifying...")
        await verify(voting.address, arguments)
    }

    const networkName = network.name == "hardhat" ? "localhost" : network.name

}

module.exports.tags = ["all", "voting"]
