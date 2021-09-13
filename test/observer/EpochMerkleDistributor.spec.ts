import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract'

import Liqtroller from '../../artifacts/contracts/controller/Liqtroller.sol/Liqtroller.json'
import { ObserverMerkleProvider } from '../../typechain'
import { EpochMerkleDistributor } from '../../typechain'
import { Token } from '../../typechain/Token'
import { expect } from 'chai'
import { generateMerkleData, MerkleData } from '../utils/merkleGenerator'
import { BigNumber } from 'ethers'

describe('EpochMerkleDistributor', function () {
  let mockLiqtroller: MockContract
  let merkleProvider: ObserverMerkleProvider
  let merkleDistributor: EpochMerkleDistributor
  let token: Token
  let minter: SignerWithAddress
  let observers: SignerWithAddress[]
  let users: SignerWithAddress[]
  let merkleData: MerkleData

  async function claimTokens(epoch: number, user: SignerWithAddress) {
    const userClaim = merkleData.claims[user.address]
    const balanceBefore = await token.balanceOf(user.address)

    const claim = await expect(
      merkleDistributor
        .connect(users[0])
        .claim(
          epoch,
          userClaim.index,
          user.address,
          BigNumber.from(userClaim.amount),
          userClaim.proof
        )
    )
      .to.emit(merkleDistributor, 'Claim')
      .withArgs(1, userClaim.index, user.address, userClaim.amount)

    const balanceAfter = await token.balanceOf(user.address)
    expect(balanceAfter.sub(balanceBefore)).to.eq(BigNumber.from(userClaim.amount))

    return claim
  }

  before(async function () {
    const signers = await ethers.getSigners()
    minter = signers[0]
    observers = signers.slice(1, 4)
    users = signers.slice(4, 7)
    merkleData = generateMerkleData({
      [users[0].address]: 10,
      [users[1].address]: 20,
      [users[2].address]: 30
    })
  })

  beforeEach(async function () {
    const ObserverMerkleProviderFactory = await ethers.getContractFactory('ObserverMerkleProvider')
    const EpochMerkleDistributorFactory = await ethers.getContractFactory('EpochMerkleDistributor')
    const TokenFactory = await ethers.getContractFactory('Token')

    // Create contracts
    token = <Token>(
      await TokenFactory.connect(minter).deploy(
        'Token',
        'TOK',
        BigNumber.from('1000000000000000000000')
      )
    )
    mockLiqtroller = await deployMockContract(observers[0], Liqtroller.abi)
    mockLiqtroller.mock.epochSealThreshold.returns(3)
    merkleProvider = <ObserverMerkleProvider>(
      await ObserverMerkleProviderFactory.deploy(mockLiqtroller.address)
    )
    merkleDistributor = <EpochMerkleDistributor>(
      await EpochMerkleDistributorFactory.deploy(merkleProvider.address, token.address)
    )

    // Send distributor some tokens
    await token.connect(minter).transfer(merkleDistributor.address, BigNumber.from('10000000'))

    // Observers seal the epoch
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, merkleData.merkleRoot)
    await merkleProvider.connect(observers[1]).submitMerkleRoot(1, merkleData.merkleRoot)
    await merkleProvider.connect(observers[2]).submitMerkleRoot(1, merkleData.merkleRoot)
  })

  it('claim successfully', async function () {
    await claimTokens(1, users[0])
    await claimTokens(1, users[1])
    await claimTokens(1, users[2])
  })

  it('isClaimed is set', async function () {
    const user = users[1]
    const userClaim = merkleData.claims[user.address]
    await claimTokens(1, user)
    expect(await merkleDistributor.isClaimed(1, userClaim.index))
  })

  it('claiming multiple times fails', async function () {
    await claimTokens(1, users[1])
    await expect(claimTokens(1, users[1])).to.be.revertedWith('ALREADY_CLAIMED')
  })

  it('claiming with incorrect amount fails', async function () {
    const user = users[1]
    const userClaim = merkleData.claims[user.address]
    await expect(
      merkleDistributor
        .connect(users[0])
        .claim(
          1,
          userClaim.index,
          user.address,
          BigNumber.from(userClaim.amount).add(5),
          userClaim.proof
        )
    ).to.be.revertedWith('MERKLE_PROOF_VERIFY_FAILED')
  })

  it('claiming an unsealed epoch fails', async function () {
    const user = users[1]
    const userClaim = merkleData.claims[user.address]
    await expect(
      merkleDistributor
        .connect(users[0])
        .claim(2, userClaim.index, user.address, BigNumber.from(userClaim.amount), userClaim.proof)
    ).to.be.revertedWith('EPOCH_NOT_SEALED')
  })
})
