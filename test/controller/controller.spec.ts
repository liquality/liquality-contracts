import { ethers } from 'hardhat'
import { Liqtroller } from '../../typechain'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { expect } from 'chai'

describe('Controller', function () {
  let signers: SignerWithAddress[]
  let liqtroller: Liqtroller

  before(async function () {
    signers = await ethers.getSigners()
  })

  this.beforeEach(async function () {
    const Liqtroller = await ethers.getContractFactory('Liqtroller')
    liqtroller = await Liqtroller.deploy(signers[0].address)
  })

  it('deploy', async function () {
    expect(await liqtroller.admin()).to.eq(signers[0].address)
  })

  it('set epoch threshold', async function () {
    await liqtroller._setEpochSealThreshold(5)
    expect(await liqtroller.epochSealThreshold()).to.equal(5)
  })
})
