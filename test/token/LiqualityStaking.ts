import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { LiqualityToken } from '../../typechain'
import { SLiqualityToken } from '../../typechain'
import { UtilContract } from '../../typechain'
import { expect } from 'chai'

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
    const SLiqualityTokenFactory = await ethers.getContractFactory('sLiqualityToken')
    const UtilContractTokenFactory = await ethers.getContractFactory('UtilContract')
    this.utilContract = <UtilContract>await UtilContractTokenFactory.deploy()

    this.liqToken = <LiqualityToken>await LiqualityTokenFactory.deploy(initialMinter)
    await this.liqToken.connect(this.signers.admin).mint(this.signers.account1.address, testAmount)
    await this.liqToken.connect(this.signers.admin).mint(this.signers.account2.address, testAmount)

    this.staking = <SLiqualityToken>(
      await SLiqualityTokenFactory.deploy(
        this.liqToken.address,
        'Liquality Staking',
        'sLIQ',
        '1.0.0'
      )
    )
    await this.liqToken.connect(this.signers.account1).approve(this.staking.address, testAmount)
    await this.liqToken.connect(this.signers.account2).approve(this.staking.address, testAmount)
  })

  it('It initialized staking contract correctly', async function () {
    expect(await this.staking.name()).to.eq('Liquality Staking')
    expect(await this.staking.symbol()).to.eq('sLIQ')
    expect(await this.staking.version()).to.eq('1.0.0')
  })

  it('Stakes and gets voting power', async function () {
    const { account1 } = this.signers

    const unlockTime = (await this.utilContract.getCurrentTs()).toNumber() + 31 * 86400

    await expect(this.staking.connect(account1).create_lock(500, unlockTime))
      .to.emit(this.staking, 'Deposit')
      .emit(this.staking, 'Supply')
      .withArgs(0, 500)

    await expect((await this.staking.supply()).toNumber()).to.eq(500)
    const stakeInfo = await this.staking.locked(account1.address)
    expect(stakeInfo.amount.toNumber()).to.eq(500)
  })

  it('Cannot withdraw stake before unlock time', async function () {
    const { account1 } = this.signers
    const unlockTime = (await this.utilContract.getCurrentTs()).toNumber() + 31 * 86400
    await this.staking.connect(account1).create_lock(500, unlockTime)

    await expect(this.staking.connect(account1).withdraw()).to.revertedWith(
      "The lock didn't expire"
    )
  })

  it('can update global record successfully', async function () {
    const { account2 } = this.signers
    await expect(this.staking.connect(account2).checkpoint()).to.not.Throw
  })
})
