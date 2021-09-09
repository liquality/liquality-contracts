import hre from 'hardhat'
import { Artifact } from 'hardhat/types'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { LiqualityToken } from '../../typechain/LiqualityToken'
import { shouldBehaveLikeErc20 } from './LiqualityToken.behavior'

const { deployContract } = hre.waffle

describe('Liquality Token', function () {
  before(async function () {
    const signers: SignerWithAddress[] = await hre.ethers.getSigners()
    this.signers = {} as SignerWithAddress
    this.signers.admin = signers[0]
    this.signers.sender = signers[1]
    this.signers.receiver = signers[2]

    const initialMinter: string = this.signers.admin.address
    const greeterArtifact: Artifact = await hre.artifacts.readArtifact('LiqualityToken')
    this.liqToken = <LiqualityToken>(
      await deployContract(this.signers.admin, greeterArtifact, [initialMinter])
    )
  })

  shouldBehaveLikeErc20()
})
