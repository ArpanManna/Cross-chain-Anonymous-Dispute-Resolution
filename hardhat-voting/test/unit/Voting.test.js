const { expect } = require("chai")
const { network, ethers } = require("hardhat")
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("./../../helper-hardhat-config")

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

describe("Voting Contract", function () {
    let Voting, voting, owner, disputeId
    const chainId = network.config.chainId

    before(async function () {
        [owner] = await ethers.getSigners()
        Voting = await ethers.getContractFactory("Voting")
        voting = await Voting.deploy(
            networkConfig[chainId]["router"],
            networkConfig[chainId]["linkAddress"]
        )
        await voting.deployed()
        console.log("voting address", voting.address)
    })

    it("Should initialize the constructor correctly", async function () {
        const routerAddress = networkConfig[chainId]["router"]
        const linkAddress = networkConfig[chainId]["linkAddress"]

        const router = await voting.router()
        const link = await voting.link()

        expect(ethers.utils.getAddress(link)).to.equal(ethers.utils.getAddress(linkAddress))
        expect(ethers.utils.getAddress(router)).to.equal(ethers.utils.getAddress(routerAddress))
    })

    it("Should check the ownership of the contract", async function () {
        const contractOwner = await voting.owner()
        expect(ethers.utils.getAddress(contractOwner)).to.equal(
            ethers.utils.getAddress(owner.address)
        )
    })

    const data = [
        {
            chain: "fuji",
            router: "0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8",
            cordinator: "0x2eD832Ba664535e5886b75D64C46EB9a228C2610",
            keyHash: "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61",
            subscriptionId: 845,
        },
        {
            chain: "mumbai",
            router: "0x70499c328e1E2a3c41108bd3730F6670a44595D1",
            cordinator: "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed",
            keyHash: "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
            subscriptionId: 6648,
        },
        {
            chain: "bsc",
            router: "0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2",
            cordinator: "0x6A2AAd07396B36Fe02a22b33cf443582f682c82f",
            keyHash: "0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314",
            subscriptionId: 3250,
        },
        {
            chain: "sepolia",
            router: "0xD0daae2231E9CB96b94C8512223533293C3693Bf",
            cordinator: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
            keyHash: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
            subscriptionId: 7583,
        },
    ]

    it("Should get the correct cordinator for routers", async function () {
        data.forEach(async (item) => {
            const getCordinator = await voting.getCordinator(item.router)
            expect(getCordinator).to.equal(item.cordinator)
        })
    })

    it("Should get the correct KeyHash for routers", async function () {
        data.forEach(async (item) => {
            const getKeyHash = await voting.getKeyHash(item.router)
            expect(getKeyHash).to.equal(item.keyHash)
        })
    })

    it("Should get the correct subscritpion Id for routers", async function () {
        data.forEach(async (item) => {
            const getSubsctiptionId = await voting.getSubsctiptionId(item.router)
            expect(getSubsctiptionId).to.equal(item.subscriptionId)
        })
    })

    it("Should compare two stings correctly", async function () {
        const getComparison1 = await voting.compare("A", "A")
        const getComparison2 = await voting.compare("B", "B")
        const getComparison3 = await voting.compare("asfdrgtgjhkl", "asfdgjhkl")
        const getComparison4 = await voting.compare("JHAGFghhvvefviJH", "JHAGFghhvvefviJH")

        expect(getComparison1).to.equal(true)
        expect(getComparison2).to.equal(true)
        expect(getComparison3).to.equal(false)
        expect(getComparison4).to.equal(true)
    })

    it.only("Should initialize dispute for voting correctly", async function () {

        const reason = "Test Reason"
        disputeId = ethers.utils.id(reason)
        console.log("disputeId", disputeId, reason)

        const raiseDispute = await voting.initializeVoting(disputeId, reason)
        console.log("raises", raiseDispute)

        await delay(25000) /// waiting 25 seconds for block confirmation.

        expect(raiseDispute).to.contains(hash)
    })

    it.only("Should get OngoingDispute voting correctly", async function () {
        const disputeProject = await voting
            .disputedProjects(disputeId)

        expect(disputeProject.disputeId).to.equal(disputeId);
        expect(disputeProject.reason).to.equal(ethers.utils.id(reason));
        expect(disputeProject.totalVoters).to.equal(100);
        expect(disputeProject.disputeRaiser).to.equal(owner.address);

    })
})
