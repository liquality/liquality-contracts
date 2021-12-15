import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { ReferralRegistry } from '../../typechain'
import { expect } from 'chai'

describe.only('ReferralRegistry', function () {
  let referralRegistry: ReferralRegistry
  let signers: SignerWithAddress[]

  before(async function () {
    signers = await ethers.getSigners()
  })

  beforeEach(async function () {
    const ReferralRegistryFactory = await ethers.getContractFactory('ReferralRegistry')
    referralRegistry = <ReferralRegistry>await ReferralRegistryFactory.deploy(signers[0].address)
  })

  it('cannot be called by other than controller', async function () {
    await expect(
      referralRegistry.connect(signers[1]).registerReferral(signers[0].address, signers[1].address)
    ).to.be.revertedWith('OnlyControllerAllowed()')
  })

  it('can register referral', async function () {
    const referrer = signers[1].address
    const referee = signers[2].address
    await expect(referralRegistry.registerReferral(referrer, referee))
      .to.emit(referralRegistry, 'ReferralRegistered')
      .withArgs(referrer, referee)
    const referral = await referralRegistry.getReferral(referee)
    const blockNumber = await ethers.provider.getBlockNumber()
    expect(referral.referrer).to.equal(referrer)
    expect(referral.blockNumber).to.equal(blockNumber)
  })

  it('cannot register self', async function () {
    const referrer = signers[1].address
    await expect(referralRegistry.registerReferral(referrer, referrer)).to.be.revertedWith(
      'RefferringSelfNotAllowed()'
    )
  })

  it('cannot refer 0 address', async function () {
    const referrer = signers[1].address
    const referee = '0x0000000000000000000000000000000000000000'
    await expect(referralRegistry.registerReferral(referrer, referee)).to.be.revertedWith(
      'InvalidAddress()'
    )
  })

  it('cannot be refferred by 0 address', async function () {
    const referrer = '0x0000000000000000000000000000000000000000'
    const referee = signers[1].address
    await expect(referralRegistry.registerReferral(referrer, referee)).to.be.revertedWith(
      'InvalidAddress()'
    )
  })

  it('cannot refer user twice', async function () {
    const user = signers[1].address

    await referralRegistry.registerReferral(signers[2].address, user)
    await expect(referralRegistry.registerReferral(signers[3].address, user)).to.be.revertedWith(
      'RefereeAlreadyRegistered()'
    )
  })

  it('referrer can refer multiple users', async function () {
    const referrer = signers[1].address

    await referralRegistry.registerReferral(referrer, signers[2].address)
    await referralRegistry.registerReferral(referrer, signers[3].address)
  })
})
