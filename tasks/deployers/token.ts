import { task } from 'hardhat/config'
import { TaskArguments } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

dotenvConfig({ path: resolve(__dirname, '../../.env') })

import { LiqualityToken, LiqualityToken__factory } from '../../typechain'

task('deploy:LiqualityToken')
  .addOptionalParam('minter')
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    let liqTokenMinter: string | undefined = process.env.LIQ_TOKEN_MINTER

    if (taskArguments.minter) {
      liqTokenMinter = taskArguments.minter
    }
    if (!liqTokenMinter) {
      throw new Error(
        'Please set your LIQ_TOKEN_MINTER in a .env file or pass it as command line argument e.g. --minter "0x.."'
      )
    }

    const liqTokenFactory: LiqualityToken__factory = await ethers.getContractFactory(
      'LiqualityToken'
    )
    const liqToken: LiqualityToken = <LiqualityToken>await liqTokenFactory.deploy(liqTokenMinter)
    await liqToken.deployed()
    console.log('Liquality Token deployed to: ', liqToken.address)
  })
