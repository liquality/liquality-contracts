import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import {
  ObserverMerkleProvider,
  ObserverMerkleProvider__factory,
  Liqtroller,
  Liqtroller__factory
} from '../../typechain'

console.log
const liqtrollerAdmin: string | undefined = process.env.LIQTROLLER_ADMIN
if (!liqtrollerAdmin) {
  throw new Error('Please set your LIQTROLLER_ADMIN in a .env file')
}

const initialEpochSealThreshold: string | undefined = process.env.INITIAL_EPOCH_SEAL_THRESHOLD
if (!initialEpochSealThreshold) {
  throw new Error('Please set your INITIAL_EPOCH_SEAL_THRESHOLD in a .env file')
}

task('deploy:ObserverMerkleProvider').setAction(async function (
  taskArguments: TaskArguments,
  { ethers }
) {
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
})
