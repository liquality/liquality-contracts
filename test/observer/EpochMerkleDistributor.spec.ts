import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract'

import Liqtroller from '../../artifacts/contracts/controller/Liqtroller.sol/Liqtroller.json'
import { ObserverMerkleProvider } from '../../typechain'
import { EpochMerkleDistributor } from '../../typechain'
import { Token } from '../../typechain/Token'
import { expect } from 'chai'
import { generateMerkleData, MerkleData } from '../utils/merkleGenerator'
import { BigNumber, BigNumberish } from 'ethers'
import { BytesLike } from '@ethersproject/bytes'

import { mineBlocks } from '../utils'
import { EpochMerkleDistributorErrors } from '../errors'

interface ClaimRequest {
  epoch: BigNumberish
  index: BigNumberish
  account: string
  amount: BigNumberish
  merkleProof: BytesLike[]
}

interface Claim {
  epoch: number
  user: SignerWithAddress
}

describe('EpochMerkleDistributor', function () {
  let mockLiqtroller: MockContract
  let merkleProvider: ObserverMerkleProvider
  let merkleDistributor: EpochMerkleDistributor
  let token: Token
  let minter: SignerWithAddress
  let observers: SignerWithAddress[]
  let users: SignerWithAddress[]
  let merkleData: MerkleData
  interface Claim {
    epoch: number
    user: SignerWithAddress
  }
  interface ClaimRequest {
    epoch: BigNumberish
    index: BigNumberish
    account: string
    amount: BigNumberish
    merkleProof: BytesLike[]
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
    await mockLiqtroller.mock.epochSealThreshold.returns(3)
    await mockLiqtroller.mock.epochDuration.returns(15000)
    merkleProvider = <ObserverMerkleProvider>(
      await ObserverMerkleProviderFactory.deploy(
        mockLiqtroller.address,
        ethers.provider.blockNumber
      )
    )
    merkleDistributor = <EpochMerkleDistributor>(
      await EpochMerkleDistributorFactory.deploy(merkleProvider.address, token.address)
    )

    // Send distributor some tokens
    await token.connect(minter).transfer(merkleDistributor.address, BigNumber.from('10000000'))

    // Observers seal the epoch 1
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, merkleData.merkleRoot)
    await merkleProvider.connect(observers[1]).submitMerkleRoot(1, merkleData.merkleRoot)
    await merkleProvider.connect(observers[2]).submitMerkleRoot(1, merkleData.merkleRoot)
  })

  it('claim successfully', async function () {
    await claimTokens(1, users[0])
    await claimTokens(1, users[1])
    await claimTokens(1, users[2])
  })

  it('claim fails if epoch end block was reached', async function () {
    await mineBlocks(ethers.provider, 15000)
    await expect(claimTokens(1, users[0])).to.be.revertedWith(
      EpochMerkleDistributorErrors.EpochNotActive
    )
    await expect(claimTokens(1, users[1])).to.be.revertedWith(
      EpochMerkleDistributorErrors.EpochNotActive
    )
    await expect(claimTokens(1, users[2])).to.be.revertedWith(
      EpochMerkleDistributorErrors.EpochNotActive
    )
  })

  it('isClaimed is set', async function () {
    const user = users[1]
    const userClaim = merkleData.claims[user.address]
    await claimTokens(1, user)
    expect(await merkleDistributor.isClaimed(1, userClaim.index))
  })

  it('claiming multiple times fails', async function () {
    await claimTokens(1, users[1])
    await expect(claimTokens(1, users[1])).to.be.revertedWith(
      EpochMerkleDistributorErrors.AlreadyClaimed
    )
  })

  it('claiming with incorrect amount fails', async function () {
    const user = users[1]
    const userClaim = merkleData.claims[user.address]
    const claimRequest: ClaimRequest = {
      index: userClaim.index,
      epoch: 1,
      account: user.address,
      amount: BigNumber.from(userClaim.amount).add(5),
      merkleProof: userClaim.proof
    }
    await expect(merkleDistributor.connect(users[0]).claim(claimRequest)).to.be.revertedWith(
      EpochMerkleDistributorErrors.MerkleProofVerifyFailed
    )
  })

  it('claiming an unsealed epoch fails', async function () {
    const user = users[1]
    const userClaim = merkleData.claims[user.address]
    const claimRequest: ClaimRequest = {
      index: userClaim.index,
      epoch: 2,
      account: user.address,
      amount: BigNumber.from(userClaim.amount),
      merkleProof: userClaim.proof
    }
    await expect(merkleDistributor.connect(users[0]).claim(claimRequest)).to.be.revertedWith(
      EpochMerkleDistributorErrors.EpochNotActive
    )
  })

  it('claims successfully for batch request inputs', async function () {
    const requests: Claim[] = [
      {
        epoch: 1,
        user: users[0]
      },
      {
        epoch: 1,
        user: users[1]
      },
      {
        epoch: 1,
        user: users[2]
      }
    ]
    const claimRequests = await batchClaimRequest(requests)

    await merkleDistributor.connect(users[0]).batchClaim(claimRequests)
    expect(await merkleDistributor.isClaimed(1, claimRequests[0].index))
    expect(await merkleDistributor.isClaimed(1, claimRequests[1].index))
    expect(await merkleDistributor.isClaimed(1, claimRequests[2].index))
  })

  async function claimTokens(epoch: number, user: SignerWithAddress) {
    const userClaim = merkleData.claims[user.address]
    const balanceBefore = await token.balanceOf(user.address)
    const claimRequest: ClaimRequest = {
      index: userClaim.index,
      epoch,
      account: user.address,
      amount: BigNumber.from(userClaim.amount),
      merkleProof: userClaim.proof
    }
    const claim = await expect(merkleDistributor.connect(users[0]).claim(claimRequest))
      .to.emit(merkleDistributor, 'Claim')
      .withArgs(1, userClaim.index, user.address, userClaim.amount)

    const balanceAfter = await token.balanceOf(user.address)
    expect(balanceAfter.sub(balanceBefore)).to.eq(BigNumber.from(userClaim.amount))

    return claim
  }

  async function batchClaimRequest(requests: Claim[]) {
    const claimRequests: ClaimRequest[] = []
    for (let i = 0; i < requests.length; i++) {
      const userClaim = merkleData.claims[requests[i].user.address]
      const claimRequest: ClaimRequest = {
        index: userClaim.index,
        epoch: requests[i].epoch,
        account: requests[i].user.address,
        amount: BigNumber.from(userClaim.amount),
        merkleProof: userClaim.proof
      }
      claimRequests.push(claimRequest)
    }
    return claimRequests
  }
})
