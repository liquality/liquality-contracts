import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import {
  Liquality1InchAdapter,
  Liquality1InchAdapter__factory,
  LiqualityProxy,
  LiqualityProxy__factory,
  LiqualityZeroXAdapter,
  LiqualityZeroXAdapter__factory
} from '../../typechain'
import { SWAPPERS } from '../proxy/utils'

task('deployLiqualityProxy').setAction(async function (taskArguments: TaskArguments, { ethers }) {
  console.log('================= Deploying Liquality Proxy =================')
  const [signer1, signer2] = await ethers.getSigners()
  const feeCollector = await signer2.getAddress()
  const admin = await signer1.getAddress()

  const liqProxyFactory: LiqualityProxy__factory = await ethers.getContractFactory('LiqualityProxy')
  const liqProxy: LiqualityProxy = <LiqualityProxy>(
    await liqProxyFactory.deploy(admin, 1000, feeCollector)
  )
  await liqProxy.deployed()
  console.log('Liquality Proxy deployed to: ', liqProxy.address)

  console.log('================= Deploying LiqZeroXAdapter =================')
  const liqualityZeroXAdapterFactory: LiqualityZeroXAdapter__factory =
    await ethers.getContractFactory('LiqualityZeroXAdapter')
  const liqZeroXAdapter: LiqualityZeroXAdapter = <LiqualityZeroXAdapter>(
    await liqualityZeroXAdapterFactory.deploy()
  )
  await liqZeroXAdapter.deployed()
  console.log('liqZeroXAdapter deployed to: ', liqZeroXAdapter.address)

  await (await liqProxy.addAdapter(SWAPPERS.ZEROX, liqZeroXAdapter.address)).wait()
  console.log('liqZeroXAdapter added to proxy')

  console.log('================= Deploying Liquality1InchAdapter =================')
  const Liquality1InchAdapterFactory: Liquality1InchAdapter__factory = <
    Liquality1InchAdapter__factory
  >await ethers.getContractFactory('Liquality1InchAdapter')
  const liquality1InchAdapter: Liquality1InchAdapter = <Liquality1InchAdapter>(
    await Liquality1InchAdapterFactory.deploy()
  )
  await liquality1InchAdapter.deployed()
  console.log('Liquality1InchAdapter deployed to: ', liquality1InchAdapter.address)

  await (
    await liqProxy.addAdapter(SWAPPERS.ONE_INCH_AGGREGATORV4, liquality1InchAdapter.address)
  ).wait()
  console.log('Liquality1InchAdapter added to proxy')
})
