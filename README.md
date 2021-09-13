# Liquality Conrtacts

## Contracts

- Token
- Governance - Forked from https://github.com/compound-finance/compound-protocol/commit/a6251ecc30adb8dfa904e2231e9a9fdb4eea78be and upgrade to 0.8.0 solidity
- Observers

## Governance deployment

How governance is deployed.

- First deploy the `GovernorBravoDelegate` this will be a shell until it's initialised
- Deploy `Timelock` with the above contract address as admin
- Deploy `GovernorBravoDelegator`, this will initialize the governance and set the admin as the timelock
- Deploy `Liqtroller` with admin being set to `GovernorBravoDelegator` address

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
