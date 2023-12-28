# Cross-chain-Anonymous-Dispute-Resolution

## Quickstart

```
git clone https://github.com/ArpanManna/Cross-chain-Anonymous-Dispute-Resolution.git
git checkout hh-ccip-voting
cd hardhat-voting
yarn
```

# Usage

Deploy:

```
yarn hardhat deploy
```

## Testing

```
yarn hardhat test --network <specify_the_chain>
e.g. yarn hardhat test --network polygonMumbai
```

# Deployment to a testnet or mainnet

1. Setup environment variabltes

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

2. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some tesnet ETH & LINK. You should see the ETH and LINK show up in your metamask. [You can read more on setting up your wallet with LINK.](https://docs.chain.link/docs/deploy-your-first-contract/#install-and-fund-your-metamask-wallet)

[You can get the router and LINK address from](https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet) . You should leave this step with:

1. routerAddress
2. LINK address

3. Deploy

In your `helper-hardhat-config.js` add your `router` and `linkAddress` under the section of the chainId you're using (aka, if you're deploying to sepolia, add your `router` and `linkAddress` in the `router` and `linkAddress`field under the `11155111` section.)

Then run:

```
yarn hardhat deploy --network sepolia
```

## Verify on etherscan

If you deploy to a testnet or mainnet, you can verify it if you get an [API Key](https://etherscan.io/myapikey) from Etherscan and set it as an environemnt variable named `ETHERSCAN_API_KEY`. You can pop it into your `.env` file as seen in the `.env.example`.

In it's current state, if you have your api key set, it will auto verify sepolia contracts!

However, you can manual verify with:

```
yarn hardhat verify --constructor-args arguments.js DEPLOYED_CONTRACT_ADDRESS
```

# Thank you!
