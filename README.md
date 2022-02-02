# Liquality Conrtacts

[![Continuous Integration](https://github.com/liquality/liquality-contracts/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/liquality/liquality-contracts/actions/workflows/ci.yml)

## Contracts

- Token
- Governance - Forked from https://github.com/compound-finance/compound-protocol/commit/a6251ecc30adb8dfa904e2231e9a9fdb4eea78be and upgrade to 0.8.0 solidity
- Observers

## Architecture

![image](https://user-images.githubusercontent.com/11529637/152171038-0e42019c-207d-4e1b-9f6e-dbf47f4f65cc.png)

**Liquality Proxy:** Any user activity possible on any chain (initial EVM) goes through this contract. Its purpose is to detect user activity as well as handle refferal registration and fees.

**Liquality Referral Registry:** Registers wallet referrals - can be queried to see who referred who for the purpose of allocating rewards

**Wallet Integrations:** Integrations built into the wallet. This can be swaps or things like lending/borrowing.

**User Staking Contract:** Users stake into this contract in variable times to be able to vote on governance. And perhaps receive other benefits. 

**Indexer:** The single data source for user activity using the Liquality protocol or wallet. It indexes transactions made through the Liquality proxy and through the liquality swap protocol. It is a public web service.

**Epoch:** A reward period. Typically 2 weeks.

**Observer:** A program run in epoch intervals to calculate rewards and submit them to the chain. It uses the Indexer and referral registry to figure this out. It creates a merkle tree and submits it to the Merkle Data Provider

**Observer Staking:** A staking contract. Observers must stake a certain amount LIQ to be able to submit epochs. Their stake can be slashed by governance.

**Merkle Data Provider:** Observers submit the map (merkle tree) of rewards here.

**Airdrop Merkle Distributor:** Relies on the "Merkle Data Provider" to allow users to claim airdrop distribution. 

**Epoch Merkle Distributor:** Relies on the "Merkle Data Provider" to allow users to claim activity rewards.

### User Scenario

Swapping ETH to BTC as an example

1. Liquality wallet retrieves a quote for swapping ETH → BTC
2. Thorchain provides the best rate, the user continues
3. The user's swap is routed through the `Liquality Proxy`, where several things happen:
    - If the user has opted into the fee, a **0.3%** fee is deducted from the base currency and sent to the treasury and possibly the developer of the thorchain integration.
    - If the user was referred and this is their first interaction, their referrer is registered with the `Liquality Referral Registry`
    - The swap is conducted with Thorchain
4. The `Liquality Indexer` detects the `Liquality Proxy` transaction and indexes its details.
5. Observers collate the activity using the `Liquality Indexer` and calculate the rewards owed to the user. If the user was referred, the referrer is also rewarded.
6. Observers generate the merkle tree for the rewards and submit them to the `ObserverMerkleProvider`
7. Once the `epochSealThreshold` (as defined by governance) is reached. The epoch is final.
8. Once the epoch is final, users are able to call `EpochMerkleDistributor` to claim their rewards. If left unclaimed will be rolled into the next epoch.


## Governance deployment

How governance is deployed.

- First deploy the `GovernorBravoDelegate` this will be a shell until it's initialised
- Deploy `Timelock` with the above contract address as admin
- Deploy `GovernorBravoDelegator`, this will initialize the governance and set the admin as the timelock
- Deploy `Liqtroller` with admin being set to `GovernorBravoDelegator` address

## Observer deployment

- Add `LIQTROLLER_ADMIN`, `INITIAL_EPOCH_SEAL_THRESHOLD` and `LIQ_TOKEN_ADDRESS` inside the `.env` file
- Run `yarn deploy --network <network_name>`
- The order of deployment is: `Liqtroller` -> `ObserverMerkleProvider` -> `EpochMerkleDistributor`


## Pending

Implement Unitroller method: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Unitroller.sol

Needs only have setImplementation method with admin being Governance. Liqtrollers will need to be changed to have `_become()` method that:

1. Sets implementation of unitroller to the current contract
2. Copies over any storage variables from pervious controller version

## Usage

### Pre Requisites

Before running any command, you need to create a `.env` file and set a BIP-39 compatible mnemonic as an environment
variable. Follow the example in `.env.example`. If you don't already have a mnemonic, use this [website](https://iancoleman.io/bip39/) to generate one.

Then, proceed with installing dependencies:

```sh
yarn install
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ yarn compile
```

### TypeChain

Compile the smart contracts and generate TypeChain artifacts:

```sh
$ yarn typechain
```

### Lint Solidity

Lint the Solidity code:

```sh
$ yarn lint:sol
```

### Lint TypeScript

Lint the TypeScript code:

```sh
$ yarn lint:ts
```

### Test

Run the Mocha tests:

```sh
$ yarn test
```

### Run Watcher

Run tests while watching contracts and tests. (faster development)

```sh
$ yarn watch
```

### Coverage

Generate the code coverage report:

```sh
$ yarn coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```sh
$ REPORT_GAS=true yarn test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```sh
$ yarn clean
```

### Deploy

Deploy the contracts to Hardhat Network:

```sh
$ yarn deploy --greeting "Bonjour, le monde!"
```

## Syntax Highlighting

If you use VSCode, you can enjoy syntax highlighting for your Solidity code via the
[vscode-solidity](https://github.com/juanfranblanco/vscode-solidity) extension. The recommended approach to set the
compiler version is to add the following fields to your VSCode user settings:

```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.4+commit.c7e474f2",
  "solidity.defaultCompiler": "remote"
}
```

Where of course `v0.8.4+commit.c7e474f2` can be replaced with any other version.
