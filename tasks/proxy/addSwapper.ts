import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import { LiqualityProxy } from '../../typechain'
import { INTERFACES_DESC, SWAPPERS } from './utils'

task('addSwapper').setAction(async function (taskArguments: TaskArguments, hre) {
  const LIQ_PROXY_ADDRESS = '0xF5aA8e3C6BA1EdF766E197a0bCD5844Fd1ed8A27'

  // Interfaces
  const IZeroX = new hre.ethers.utils.Interface(INTERFACES_DESC.ZEROX)

  const IAdapter = new hre.ethers.utils.Interface(INTERFACES_DESC.ADAPTER)

  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  /// @ts-ignore
  const liqProxy: LiqualityProxy = <LiqualityProxy>(
    await hre.ethers.getContractAt('LiqualityProxy', LIQ_PROXY_ADDRESS)
  )

  // Add adapter for uniswapV3
  await (
    await liqProxy.addAdapter(SWAPPERS.ZEROX, '0x5A3Deb79F213F5d4C2702fC75eDfa41F46B5E271')
  ).wait()

  // // Add zeroX adapter functions
  // await ( await liqProxy.mapSwapperFunctionToAdapterFunction(SWAPPERS.ZEROX, IZeroX.getSighash("sellToUniswap"), IAdapter.getSighash("exactInputSwap")) ).wait();

  console.log(' ... \n Adapter Added ... \n')
})
