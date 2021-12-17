import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { MockStaking } from '../../typechain/MockStaking'
import { LiqualityToken } from '../../typechain'
import { expect } from 'chai'

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

describe('Liquality Statking', function () {
  before(async function () {
    const signers: SignerWithAddress[] = await ethers.getSigners()
    this.signers = {} as SignerWithAddress
    this.signers.admin = signers[0]
    this.signers.account1 = signers[1]
    this.signers.account2 = signers[2]
  })

  beforeEach(async function () {
    // For anything to happen before each
    const initialMinter: string = this.signers.admin.address
    const testAmount = 5000

    const LiqualityTokenFactory = await ethers.getContractFactory('LiqualityToken')
    this.liqToken = <LiqualityToken>await LiqualityTokenFactory.deploy(initialMinter)
    await this.liqToken.connect(this.signers.admin).mint(this.signers.account1.address, testAmount)
    await this.liqToken.connect(this.signers.admin).mint(this.signers.account2.address, testAmount)

    const MockStakingFactory = await ethers.getContractFactory('MockStaking')
    this.staking = <MockStaking>await MockStakingFactory.deploy(this.liqToken.address)
    await this.liqToken.connect(this.signers.account1).approve(this.staking.address, testAmount)
    await this.liqToken.connect(this.signers.account2).approve(this.staking.address, testAmount)
  })

  it('Stakes and gets voting power', async function () {
    const { account1 } = this.signers

    const currentTs = await this.staking.getCurrentTs()
    const unlockTime = currentTs.toNumber() + 31 * 86400

    await expect(this.staking.connect(account1).addStake(500, unlockTime))
      .to.emit(this.staking, 'StakeAdded')
      .emit(this.staking, 'Supply')
      .withArgs(0, 500)

    await expect((await this.staking.supply()).toNumber()).to.eq(500)
    const stakeInfo = await this.staking.stakingInfo(account1.address)
    expect(stakeInfo.amount.toNumber()).to.eq(500)
  })

  it('Cannot withdraw stake before unlock time', async function () {
    const { account1 } = this.signers
    const currentTs = await this.staking.getCurrentTs()
    const unlockTime = currentTs.toNumber() + 31 * 86400
    await this.staking.connect(account1).addStake(500, unlockTime)

    await expect(this.staking.connect(account1).removeStake()).to.revertedWith(
      "The lock didn't expire"
    )
  })

  it('Can withdraw after unlock time', async function () {
    const { account2 } = this.signers

    const currentTs = await this.staking.getCurrentTs()
    await this.staking.connect(account2).addStakeNoMinLimit(500, currentTs.toNumber() + 5)

    await sleep(5000)

    await expect(this.staking.connect(account2).removeStake())
      .to.emit(this.staking, 'StakeRemoved')
      .emit(this.staking, 'Supply')
      .withArgs(500, 0)

    const stakeInfo = await this.staking.stakingInfo(account2.address)
    expect(stakeInfo.amount.toNumber()).to.eq(0)
  })

  it('does not transfer', async function () {
    const { account2, account1 } = this.signers

    const currentTs = await this.staking.getCurrentTs()
    const unlockTime = currentTs.toNumber() + 86400 * 31 // 31 days
    await this.staking.connect(account2).addStake(500, unlockTime)
    await expect(this.staking.connect(account2).transfer(account1.address, 200)).to.revertedWith(
      'ERC20NonTransferable: Transfer operation disabled for staked tokens'
    )
  })

  it('does not approve', async function () {
    const { account2, account1 } = this.signers

    const currentTs = await this.staking.getCurrentTs()
    const unlockTime = currentTs.toNumber() + 86400 * 31 // 31 days
    await this.staking.connect(account2).addStake(500, unlockTime)
    await expect(this.staking.connect(account2).approve(account1.address, 200)).to.revertedWith(
      'ERC20NonTransferable: Approval operation disabled for staked tokens'
    )
  })

  it('can update global record successfully', async function () {
    const { account2 } = this.signers
    await expect(this.staking.connect(account2).checkpoint()).to.not.Throw
  })

  it('Sets min lock time successfully', async function () {
    const { account2, admin } = this.signers

    await expect(this.staking.connect(admin).setMinLock(2)) // 2 days
      .to.emit(this.staking, 'MinLockUpdated')
      .withArgs(30, 2)

    await expect(this.staking.connect(admin).setMinLock(6 * 365)) // 6 years
      .to.revertedWith(
        'INVALIDLOCK : Min lock time must be greater than zero and less than max lock'
      )

    const currentTs = await this.staking.getCurrentTs()
    await expect(this.staking.connect(account2).addStake(500, currentTs.toNumber() + 86400)) //1day
      .to.revertedWith('unlock time must be greater than minimun lock time')
  })

  it('Sets max lock time successfully', async function () {
    const { account2, admin } = this.signers

    await expect(this.staking.connect(admin).setMaxLock(31)) // 31 days
      .to.emit(this.staking, 'MaxLockUpdated')
      .withArgs(5 * 365, 31)

    await expect(this.staking.connect(admin).setMaxLock(29)) // 29 days
      .to.revertedWith(
        'INVALIDLOCK : Lock time must be greater than zero and greater than min lock'
      )

    const currentTs = await this.staking.getCurrentTs()

    await expect(this.staking.connect(account2).addStake(500, currentTs.toNumber() + 86400 * 35)) // 35 days
      .to.revertedWith('Unlock time cannot exceed max lock')
  })
})
