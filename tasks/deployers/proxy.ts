import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import {
  Liquality1InchAdapter,
  Liquality1InchAdapter__factory,
  LiqualityHTLCAdapter,
  LiqualityHTLCAdapter__factory,
  LiqualityProxy,
  LiqualityProxy__factory,
  LiqualityZeroXAdapter,
  LiqualityZeroXAdapter__factory
} from '../../typechain'

export const SWAPPERS = {
  ONE_INCH_AGGREGATORV4: '0x1111111254fb6c44bAC0beD2854e76F90643097d'.toLowerCase(), //Verified
  ZEROX: '0xDef1C0ded9bec7F1a1670819833240f027b25EfF'.toLowerCase(), //  Verified
  HTLC: '0x133713376F69C1A67d7f3594583349DFB53d8166'.toLowerCase()
}

const wEth_arbitrum = '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1'
const wEth_avalance = '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7'

task('deployLiqualityProxy').setAction(async function (taskArguments: TaskArguments, { ethers }) {
  console.log('================= Deploying LiqZeroXAdapter =================')
  const liqualityZeroXAdapterFactory: LiqualityZeroXAdapter__factory =
    await ethers.getContractFactory('LiqualityZeroXAdapter')
  const liqZeroXAdapter: LiqualityZeroXAdapter = <LiqualityZeroXAdapter>(
    await liqualityZeroXAdapterFactory.deploy()
  )
  await liqZeroXAdapter.deployed()
  console.log('liqZeroXAdapter deployed to: ', liqZeroXAdapter.address)

  console.log('================= Deploying Liquality1InchAdapter =================')
  const Liquality1InchAdapterFactory: Liquality1InchAdapter__factory = <
    Liquality1InchAdapter__factory
  >await ethers.getContractFactory('Liquality1InchAdapter')
  const liquality1InchAdapter: Liquality1InchAdapter = <Liquality1InchAdapter>(
    await Liquality1InchAdapterFactory.deploy(wEth_avalance)
  )
  await liquality1InchAdapter.deployed()
  console.log('Liquality1InchAdapter deployed to: ', liquality1InchAdapter.address)

  console.log('================= Deploying LiqualityHTLCAdapter =================')
  const LiqualityHTLCAdapterFactory: LiqualityHTLCAdapter__factory = <
    LiqualityHTLCAdapter__factory
  >await ethers.getContractFactory('LiqualityHTLCAdapter')
  const liqualityHTLCAdapter: LiqualityHTLCAdapter = <LiqualityHTLCAdapter>(
    await LiqualityHTLCAdapterFactory.deploy()
  )
  await liqualityHTLCAdapter.deployed()
  console.log('LiqualityHTLCAdapter deployed to: ', liqualityHTLCAdapter.address)

  console.log('================= Deploying Liquality Proxy =================')
  const [signer1, signer2] = await ethers.getSigners()
  const feeCollector = await signer2.getAddress()
  const admin = await signer1.getAddress()

  // Construct swapperInfo
  const swappersInfo = []
  swappersInfo.push({
    swapper: SWAPPERS.ZEROX,
    adapter: liqZeroXAdapter.address,
    feeRate: 1000
  })
  swappersInfo.push({
    swapper: SWAPPERS.ONE_INCH_AGGREGATORV4,
    adapter: liquality1InchAdapter.address,
    feeRate: 1000
  })
  swappersInfo.push({
    swapper: SWAPPERS.HTLC,
    adapter: liqualityHTLCAdapter.address,
    feeRate: 1000
  })
  const liqProxyFactory: LiqualityProxy__factory = await ethers.getContractFactory('LiqualityProxy')
  const liqProxy: LiqualityProxy = <LiqualityProxy>(
    await liqProxyFactory.deploy(admin, feeCollector, swappersInfo)
  )
  await liqProxy.deployed()
  console.log('Liquality Proxy deployed to: ', liqProxy.address)
})
