import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { LiqualityToken } from '../../typechain/LiqualityToken'
import { shouldBehaveLikeErc20 } from './LiqualityToken.behavior'

describe('Liquality Token', function () {
  before(async function () {
    const signers: SignerWithAddress[] = await ethers.getSigners()
    this.signers = {} as SignerWithAddress
    this.signers.admin = signers[0]
    this.signers.sender = signers[1]
    this.signers.receiver = signers[2]

    const initialMinter: string = this.signers.admin.address

    const LiqualityTokenFactory = await ethers.getContractFactory('LiqualityToken')
    this.liqToken = <LiqualityToken>await LiqualityTokenFactory.deploy(initialMinter)
  })

  shouldBehaveLikeErc20()
})
