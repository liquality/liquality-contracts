import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import { LiqualityZeroXAdapter, LiqualityZeroXAdapter__factory } from '../../typechain'

task('deployLiqZeroXAdapter').setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const liqualityZeroXAdapterFactory: LiqualityZeroXAdapter__factory =
    await ethers.getContractFactory('LiqualityZeroXAdapter')
  const liqZeroXAdapter: LiqualityZeroXAdapter = <LiqualityZeroXAdapter>(
    await liqualityZeroXAdapterFactory.deploy()
  )
  await liqZeroXAdapter.deployed()
  console.log('liqZeroXAdapter deployed to: ', liqZeroXAdapter.address)
})
