import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'

import { ObserverMerkleProvider, ObserverMerkleProvider__factory } from '../../typechain'

task('deploy:ObserverMerkleProvider')
  .addParam('greeting', 'Say hello, be nice')
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const observerMerkleProviderFactory: ObserverMerkleProvider__factory =
      await ethers.getContractFactory('ObserverMerkleProvider')
    const observerMerkleProvider: ObserverMerkleProvider = <ObserverMerkleProvider>(
      await observerMerkleProviderFactory.deploy()
    )
    await observerMerkleProvider.deployed()
    console.log('ObserverMerkleProvider deployed to: ', observerMerkleProvider.address)
  })
