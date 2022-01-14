import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import Liqtroller from '../../artifacts/contracts/controller/Liqtroller.sol/Liqtroller.json'

import { ObserverStaking, Token } from '../../typechain'

import { expect } from 'chai'
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract'
import { mineBlocks } from '../utils'
import { ObserverStakingErrors } from '../errors'

describe('ObserverStaking', function () {
  const stakeAmount = ethers.utils.parseEther('100')
  const stakeDuration = 50
  const stakeDurationTreshold = 20

  let token: Token
  let observerStaking: ObserverStaking

  let governance: SignerWithAddress
  let observer: SignerWithAddress
  let mockLiqtroller: MockContract

  before(async function () {
    const signers = await ethers.getSigners()
    governance = signers[0]
    observer = signers[1]

    mockLiqtroller = await deployMockContract(governance, Liqtroller.abi)
    await mockLiqtroller.mock.stakeAmount.returns(stakeAmount)
    await mockLiqtroller.mock.stakeDuration.returns(stakeDuration)
    await mockLiqtroller.mock.stakeDurationTreshold.returns(stakeDurationTreshold)
    await mockLiqtroller.mock.getStakeParameters.returns(
      stakeAmount,
      stakeDuration,
      stakeDurationTreshold
    )
  })

  beforeEach(async function () {
    const observerStakingFactory = await ethers.getContractFactory('ObserverStaking')
    const tokenFactory = await ethers.getContractFactory('Token')

    token = <Token>(
      await tokenFactory.connect(observer).deploy('Token', 'TOK', ethers.utils.parseEther('10000'))
    )

    observerStaking = <ObserverStaking>(
      await observerStakingFactory
        .connect(governance)
        .deploy(mockLiqtroller.address, governance.address, token.address)
    )

    await token.approve(observerStaking.address, ethers.constants.MaxUint256)
  })

  describe('Staking', async function () {
    it('allows staking', async function () {
      const expireAt = (await ethers.provider.getBlockNumber()) + 1 + stakeDuration

      await expect(observerStaking.connect(observer).stake())
        .to.emit(observerStaking, 'ObserverStaked')
        .withArgs(observer.address, stakeAmount, expireAt)

      expect(await token.balanceOf(observerStaking.address)).to.be.eq(stakeAmount)

      const stake = await observerStaking.stakes(observer.address)
      expect(stake.amount).to.be.equal(stakeAmount)
      expect(stake.expireBlock).to.be.equal(expireAt)
    })

    it('fails if user does not have enough balance', async function () {
      await token.connect(observer).burn(await token.balanceOf(observer.address))
      await expect(observerStaking.connect(observer).stake()).to.be.revertedWith(
        ObserverStakingErrors.TransferFailed
      )
    })
  })

  describe('Unstaking', async function () {
    it('allows unstaking after expiry', async function () {
      await observerStaking.connect(observer).stake()
      await mineBlocks(ethers.provider, stakeDuration)
      await expect(observerStaking.connect(observer).unstake())
        .to.emit(observerStaking, 'ObserverUnstaked')
        .withArgs(observer.address, stakeAmount)
      expect(await token.balanceOf(observerStaking.address)).to.be.eq(0)
      const stake = await observerStaking.stakes(observer.address)
      expect(stake.amount).to.be.equal(0)
      expect(stake.expireBlock).to.be.equal(0)
    })

    it('fails if not expired', async function () {
      await observerStaking.connect(observer).stake()
      await expect(observerStaking.connect(observer).unstake()).to.be.revertedWith(
        ObserverStakingErrors.StakeNotExpired
      )
    })
  })

  describe('Extending', async function () {
    it('allows extending of a stake', async function () {
      await observerStaking.connect(observer).stake()

      const expireBlock = (await observerStaking.stakes(observer.address)).expireBlock
      const expireBlockAfterExtend = expireBlock.add(stakeDuration)
      const stakedAmountAfterExtend = stakeAmount.mul(2)

      await expect(observerStaking.connect(observer).extend(stakeAmount, stakeDuration))
        .to.emit(observerStaking, 'ObserverStaked')
        .withArgs(observer.address, stakedAmountAfterExtend, expireBlockAfterExtend)

      expect(await token.balanceOf(observerStaking.address)).to.be.eq(stakedAmountAfterExtend)
      const stake = await observerStaking.stakes(observer.address)
      expect(stake.amount).to.be.equal(stakedAmountAfterExtend)
      expect(stake.expireBlock).to.be.equal(expireBlockAfterExtend)
    })

    it('fails if stake does not exists', async function () {
      await expect(
        observerStaking.connect(observer).extend(stakeAmount, stakeDuration)
      ).to.be.revertedWith(ObserverStakingErrors.CannotExtendNonExistentStake)
    })
  })

  describe('Slashing', async function () {
    it('allows slashing from governance', async function () {
      await observerStaking.connect(observer).stake()

      const totalSupplyBeforeSlashing = await token.totalSupply()
      await expect(observerStaking.connect(governance).slash(observer.address, stakeAmount))
        .to.emit(observerStaking, 'ObserverSlashed')
        .withArgs(observer.address, stakeAmount)
      const totalSupplyAfterSlashing = await token.totalSupply()

      expect(totalSupplyAfterSlashing).to.be.equal(totalSupplyBeforeSlashing.sub(stakeAmount))
      expect(await token.balanceOf(observerStaking.address)).to.be.eq(0)
      const stake = await observerStaking.stakes(observer.address)
      expect(stake.amount).to.be.equal(0)
      expect(stake.expireBlock).to.be.equal(0)
    })

    it('correctly returns the slash remainder to the user', async function () {
      await observerStaking.connect(observer).stake()

      const slashAmount = stakeAmount.div(2)
      const remainingAmount = stakeAmount.sub(slashAmount)

      const observerBalanceBeforeSlashing = await token.balanceOf(observer.address)
      const totalSupplyBeforeSlashing = await token.totalSupply()
      await expect(observerStaking.connect(governance).slash(observer.address, slashAmount))
        .to.emit(observerStaking, 'ObserverSlashed')
        .withArgs(observer.address, slashAmount)
      const totalSupplyAfterSlashing = await token.totalSupply()
      const observerBalanceAfterSlashing = await token.balanceOf(observer.address)

      expect(totalSupplyAfterSlashing).to.be.equal(totalSupplyBeforeSlashing.sub(slashAmount))
      expect(observerBalanceAfterSlashing).to.be.equal(
        observerBalanceBeforeSlashing.add(remainingAmount)
      )
      expect(await token.balanceOf(observerStaking.address)).to.be.eq(0)
      const stake = await observerStaking.stakes(observer.address)
      expect(stake.amount).to.be.equal(0)
      expect(stake.expireBlock).to.be.equal(0)
    })

    it('fails if caller is not governance', async function () {
      await observerStaking.connect(observer).stake()
      await expect(
        observerStaking.connect(observer).slash(observer.address, stakeAmount)
      ).to.be.revertedWith(ObserverStakingErrors.ExecutionNotAuthorized)
    })

    it('fails if the slashed amount is bigger than staked amount', async function () {
      await observerStaking.connect(observer).stake()
      await expect(
        observerStaking.connect(governance).slash(observer.address, stakeAmount.add(1))
      ).to.be.revertedWith(ObserverStakingErrors.InvalidSlashAmount)
    })
  })

  describe('Eligibility', async function () {
    it('observer is eligible if amount and expiry are correct', async function () {
      await observerStaking.connect(observer).stake()
      expect(await observerStaking.isObserverEligible(observer.address)).to.be.true
    })

    it('fails if user does not have enough stake', async function () {
      await observerStaking.connect(observer).stake()

      await mockLiqtroller.mock.getStakeParameters.returns(
        stakeAmount.add(1),
        stakeDuration,
        stakeDurationTreshold
      )
      expect(await observerStaking.isObserverEligible(observer.address)).to.be.false
      await mockLiqtroller.mock.getStakeParameters.returns(
        stakeAmount,
        stakeDuration,
        stakeDurationTreshold
      )
    })

    it('fails if user stake is expired', async function () {
      await observerStaking.connect(observer).stake()
      const stake = await observerStaking.stakes(observer.address)
      const blocksUntilNotEligible = stake.expireBlock.sub(stakeDurationTreshold)
      const currentBlockNumber = await ethers.provider.getBlockNumber()
      await mineBlocks(ethers.provider, blocksUntilNotEligible.sub(currentBlockNumber).toNumber())
      expect(await observerStaking.isObserverEligible(observer.address)).to.be.false
    })
  })
})
