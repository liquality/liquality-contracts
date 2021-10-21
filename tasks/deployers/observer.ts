import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import {
  ObserverMerkleProvider,
  ObserverMerkleProvider__factory,
  Liqtroller,
  Liqtroller__factory,
  EpochMerkleDistributor,
  EpochMerkleDistributor__factory
} from '../../typechain'

task('deploy:ObserverMerkleProvider')
  .addOptionalParam('admin')
  .addOptionalParam('threshold')
  .addOptionalParam('token')
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    let liqtrollerAdmin: string | undefined = process.env.LIQTROLLER_ADMIN
    if (taskArguments.admin) {
      liqtrollerAdmin = taskArguments.admin
    }
    if (!liqtrollerAdmin) {
      throw new Error(
        'Please set your LIQTROLLER_ADMIN in a .env file or pass it as command line argument e.g. --admin "0x.."'
      )
    }

    let initialEpochSealThreshold: string | undefined = process.env.INITIAL_EPOCH_SEAL_THRESHOLD
    if (taskArguments.threshold) {
      initialEpochSealThreshold = taskArguments.threshold
    }
    if (!initialEpochSealThreshold) {
      throw new Error(
        'Please set your INITIAL_EPOCH_SEAL_THRESHOLD in a .env file or pass it as command line argument e.g. --threshold "1"'
      )
    }

    let liqTokenAddress: string | undefined = process.env.LIQ_TOKEN_ADDRESS
    if (taskArguments.token) {
      liqTokenAddress = taskArguments.token
    }
    if (!liqTokenAddress) {
      throw new Error(
        'Please set your LIQ_TOKEN_ADDRESS in a .env file or pass it as command line argument e.g. --token "0x.."'
      )
    }

    const liqtrollerFactory: Liqtroller__factory = await ethers.getContractFactory('Liqtroller')
    const liqtroller: Liqtroller = <Liqtroller>(
      await liqtrollerFactory.deploy(liqtrollerAdmin, initialEpochSealThreshold)
    )
    await liqtroller.deployed()
    console.log('Liqtroller deployed to: ', liqtroller.address)

    const observerMerkleProviderFactory: ObserverMerkleProvider__factory =
      await ethers.getContractFactory('ObserverMerkleProvider')
    const observerMerkleProvider: ObserverMerkleProvider = <ObserverMerkleProvider>(
      await observerMerkleProviderFactory.deploy(liqtroller.address)
    )
    await observerMerkleProvider.deployed()
    console.log('ObserverMerkleProvider deployed to: ', observerMerkleProvider.address)

    const epochMerkleDistributorFactory: EpochMerkleDistributor__factory =
      await ethers.getContractFactory('EpochMerkleDistributor')
    const epochMerkleDistributor: EpochMerkleDistributor = <EpochMerkleDistributor>(
      await epochMerkleDistributorFactory.deploy(observerMerkleProvider.address, liqTokenAddress)
    )
    await epochMerkleDistributor.deployed()
    console.log('EpochMerkleDistributor deployed to: ', epochMerkleDistributor.address)
  })