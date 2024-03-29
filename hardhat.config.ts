import '@nomiclabs/hardhat-waffle'
import '@nomiclabs/hardhat-vyper'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'hardhat-watcher'
import 'solidity-coverage'

import './tasks/accounts'
import './tasks/clean'
import './tasks/deployers'

import { resolve } from 'path'

import { config as dotenvConfig } from 'dotenv'
import { HardhatUserConfig } from 'hardhat/config'
import { NetworkUserConfig } from 'hardhat/types'

dotenvConfig({ path: resolve(__dirname, './.env') })

const chainIds = {
  ganache: 1337,
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3
}

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC
if (!mnemonic) {
  throw new Error('Please set your MNEMONIC in a .env file')
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY
if (!infuraApiKey) {
  throw new Error('Please set your INFURA_API_KEY in a .env file')
}

function getChainConfig(network: keyof typeof chainIds): NetworkUserConfig {
  const url: string = 'https://' + network + '.infura.io/v3/' + infuraApiKey
  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0"
    },
    chainId: chainIds[network],
    url
  }
}

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  gasReporter: {
    currency: 'USD',
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: './contracts'
  },
  networks: {
    hardhat: {
      gas: 12000000,
      allowUnlimitedContractSize: true,
      accounts: {
        mnemonic
      },
      chainId: chainIds.hardhat,
      // See https://github.com/sc-forks/solidity-coverage/issues/652
      hardfork: process.env.CODE_COVERAGE ? 'berlin' : 'london'
    },
    goerli: getChainConfig('goerli'),
    kovan: getChainConfig('kovan'),
    rinkeby: getChainConfig('rinkeby'),
    ropsten: getChainConfig('ropsten')
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test'
  },
  solidity: {
    compilers: [{ version: '0.8.10' }, { version: '0.5.16' }],
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/solidity-template/issues/31
        bytecodeHash: 'none'
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 800
      }
    }
  },
  vyper: {
    version: '0.2.4'
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5'
  },
  watcher: {
    ci: {
      files: ['./contracts', './test'],
      tasks: [
        { command: 'compile', params: { quiet: true } },
        { command: 'typechain', params: { quiet: true } },
        { command: 'test', params: { noCompile: true } }
      ]
    }
  }
}

export default config
