import { ethers } from 'hardhat'
import { Liqtroller, Liqtroller__factory } from '../../typechain'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { expect } from 'chai'
import { LiqtrollerErrors } from '../errors'

describe('Controller', function () {
  const epochSealThreshold = 3
  const epochDuration = 15000

  let signers: SignerWithAddress[]
  let admin: SignerWithAddress
  let liqtroller: Liqtroller

  before(async function () {
    signers = await ethers.getSigners()
    admin = signers[0]
  })

  this.beforeEach(async function () {
    const Liqtroller: Liqtroller__factory = await ethers.getContractFactory('Liqtroller')
    liqtroller = await Liqtroller.deploy(admin.address, epochSealThreshold, epochDuration)
  })

  it('deploy', async function () {
    expect(await liqtroller.admin()).to.eq(admin.address)
    expect(await liqtroller.epochSealThreshold()).to.eq(epochSealThreshold)
    expect(await liqtroller.epochDuration()).to.eq(epochDuration)
  })

  it('set epoch threshold and emits an event', async function () {
    const newEpochSealThreshold = 5

    await expect(liqtroller.setEpochSealThreshold(newEpochSealThreshold))
      .to.emit(liqtroller, 'NewEpochSealThreshold')
      .withArgs(epochSealThreshold, newEpochSealThreshold)

    expect(await liqtroller.epochSealThreshold()).to.equal(newEpochSealThreshold)
  })

  it('set epoch duration in blocks and emits an event', async function () {
    const newEpochDuration = 18000

    await expect(liqtroller.setEpochDuration(newEpochDuration))
      .to.emit(liqtroller, 'NewEpochDuration')
      .withArgs(epochDuration, newEpochDuration)

    expect(await liqtroller.epochDuration()).to.equal(newEpochDuration)
  })

  it('works only with admin', async function () {
    await expect(liqtroller.connect(signers[1]).setEpochSealThreshold(5)).to.be.revertedWith(
      LiqtrollerErrors.OnlyAdmin
    )

    await expect(liqtroller.connect(signers[1]).setEpochDuration(5)).to.be.revertedWith(
      LiqtrollerErrors.OnlyAdmin
    )
  })
})
