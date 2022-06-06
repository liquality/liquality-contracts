// import { task } from 'hardhat/config'
// import { TaskArguments } from 'hardhat/types'
// import { config as dotenvConfig } from 'dotenv'
// import { resolve } from 'path'

// dotenvConfig({ path: resolve(__dirname, '../../.env') })

// import { Liquality1InchAdapter } from '../../typechain/Liquality1InchAdapter'
// import { Liquality1InchAdapter__factory } from '../../typechain/factories/Liquality1InchAdapter__factory'

// task('deployLiq1InchAdapter')
//   .setAction(async function (taskArguments: TaskArguments, { ethers }) {

//     const liquality1InchAdapterFactory: Liquality1InchAdapter__factory = <Liquality1InchAdapter__factory> await ethers.getContractFactory(
//       'Liquality1InchAdapter'
//     )
//     const liqZeroXAdapter: Liquality1InchAdapter = <Liquality1InchAdapter>await liquality1InchAdapterFactory.deploy()
//     await liqZeroXAdapter.deployed()
//     console.log('liqZeroXAdapter deployed to: ', liqZeroXAdapter.address)

//   })
