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
  .addOptionalParam('epochEndBlock')
  .addOptionalParam('stakeAmount')
  .addOptionalParam('stakeDuration')
  .addOptionalParam('stakeDurationThreshold')
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

    let initialEpochDuration: string | undefined = process.env.INITIAL_EPOCH_DURATION
    if (taskArguments.duration) {
      initialEpochDuration = taskArguments.threshold
    }
    if (!initialEpochDuration) {
      throw new Error(
        'Please set your INITIAL_EPOCH_SEAL_THRESHOLD in a .env file or pass it as command line argument e.g. --duration "15000"'
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

    let epochEndBlock: string | undefined = process.env.EPOCH_END_BLOCK
    if (taskArguments.epochEndBlock) {
      epochEndBlock = taskArguments.epochEndBlock
    }
    if (!epochEndBlock) {
      throw new Error(
        'Please set your EPOCH_END_BLOCK in a .env file or pass it as command line argument e.g. --epochEndBlock "13638873"'
      )
    }

    let stakeAmount: string | undefined = process.env.STAKE_AMOUNT
    if (taskArguments.stakeAmount) {
      stakeAmount = taskArguments.stakeAmount
    }
    if (!stakeAmount) {
      throw new Error(
        'Please set your STAKE_AMOUNT in a .env file or pass it as command line argument e.g. --stakeAmount "100"'
      )
    }

    let stakeDuration: string | undefined = process.env.STAKE_DURATION
    if (taskArguments.stakeDuration) {
      stakeDuration = taskArguments.stakeDuration
    }
    if (!stakeDuration) {
      throw new Error(
        'Please set your STAKE_DURATION in a .env file or pass it as command line argument e.g. --stakeDuration "50"'
      )
    }

    let stakeDurationThreshold: string | undefined = process.env.STAKE_DURATION_THRESHOLD
    if (taskArguments.stakeDurationThreshold) {
      stakeDurationThreshold = taskArguments.stakeDurationThreshold
    }
    if (!stakeDurationThreshold) {
      throw new Error(
        'Please set your STAKE_DURATION_THRESHOLD in a .env file or pass it as command line argument e.g. --stakeDurationThreshold "20"'
      )
    }

    const liqtrollerFactory: Liqtroller__factory = await ethers.getContractFactory('Liqtroller')
    const liqtroller: Liqtroller = <Liqtroller>(
      await liqtrollerFactory.deploy(
        liqtrollerAdmin,
        initialEpochSealThreshold,
        initialEpochDuration,
        stakeAmount,
        stakeDuration,
        stakeDurationThreshold
      )
    )
    await liqtroller.deployed()
    console.log('Liqtroller deployed to: ', liqtroller.address)

    const observerMerkleProviderFactory: ObserverMerkleProvider__factory =
      await ethers.getContractFactory('ObserverMerkleProvider')
    const observerMerkleProvider: ObserverMerkleProvider = <ObserverMerkleProvider>(
      await observerMerkleProviderFactory.deploy(
        liqtroller.address,
        liqtroller.address, // TODO: change with Observer Staking contract
        epochEndBlock
      )
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
