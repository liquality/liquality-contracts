import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import { LiqualityProxy, LiqualityProxy__factory } from '../../typechain'

task('deployLiqualityProxy').setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const admin = '0x0797b98884de920620dcd9d84c4f106374c6121c'
  const liqProxyFactory: LiqualityProxy__factory = await ethers.getContractFactory('LiqualityProxy')
  const liqProxy: LiqualityProxy = <LiqualityProxy>await liqProxyFactory.deploy(admin)
  await liqProxy.deployed()
  console.log('Liquality Proxy deployed to: ', liqProxy.address)

  // Set Fee rate
  await (await liqProxy.setFeeRate(1000)).wait()

  // Set Fee collector
  await (await liqProxy.setFeeCollector('0x0EDd8AF763D0a7999f15623859dA9a0A786D1A9B')).wait()
})
