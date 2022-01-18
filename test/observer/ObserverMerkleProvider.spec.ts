import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import Liqtroller from '../../artifacts/contracts/controller/Liqtroller.sol/Liqtroller.json'
import ObserverStaking from '../../artifacts/contracts/observer/ObserverStaking.sol/ObserverStaking.json'

import { ObserverMerkleProvider } from '../../typechain'
import { expect } from 'chai'
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract'
import { mineBlocks } from '../utils'
import { ObserverMerkleProviderErrors } from '../errors'

const ROOT_1 = ethers.utils.sha256('0x01')
const ROOT_2 = ethers.utils.sha256('0x02')

describe('ObserverMerkleProvider', function () {
  const epochSealThreshold = 3
  const epochDuration = 15000

  let mockLiqtroller: MockContract
  let mockObserverStaking: MockContract

  let merkleProvider: ObserverMerkleProvider
  let observers: SignerWithAddress[]

  before(async function () {
    observers = await ethers.getSigners()
  })

  beforeEach(async function () {
    const ObserverMerkleProviderFactory = await ethers.getContractFactory('ObserverMerkleProvider')
    mockLiqtroller = await deployMockContract(observers[0], Liqtroller.abi)
    await mockLiqtroller.mock.epochSealThreshold.returns(epochSealThreshold)
    await mockLiqtroller.mock.epochDuration.returns(epochDuration)

    mockObserverStaking = await deployMockContract(observers[0], ObserverStaking.abi)
    await mockObserverStaking.mock.isObserverEligible.returns(true)

    merkleProvider = <ObserverMerkleProvider>(
      await ObserverMerkleProviderFactory.deploy(
        mockLiqtroller.address,
        mockObserverStaking.address,
        ethers.provider.blockNumber
      )
    )
  })

  it('starts at 0 epoch', async function () {
    expect(await merkleProvider.lastEpoch()).to.equal(0)
  })

  it('lets observers submit roots', async function () {
    await submitMerkleRoot(epochSealThreshold - 1, 1, ROOT_1)
  })

  it('seal epoch after enough submissions', async function () {
    expect(await merkleProvider.isEpochActive(1)).to.equal(false)
    await submitMerkleRoot(epochSealThreshold - 1, 1, ROOT_1)
    await expect(merkleProvider.connect(observers[2]).submitMerkleRoot(1, ROOT_1))
      .to.emit(merkleProvider, 'SealEpoch')
      .withArgs(1, ROOT_1)

    expect(await merkleProvider.isEpochActive(1)).to.equal(true)
    expect(await merkleProvider.lastEpoch()).to.equal(1)
    expect(await merkleProvider.merkleRoot(1), ROOT_1)
  })

  it('prevent further submissions after seal', async function () {
    await submitMerkleRoot(epochSealThreshold, 1, ROOT_1)
    await expect(
      merkleProvider.connect(observers[3]).submitMerkleRoot(1, ROOT_2)
    ).to.be.revertedWith(ObserverMerkleProviderErrors.EpochAlreadySealed)
  })

  it('multiple submissions from same observer fails', async function () {
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_1)
    await expect(
      merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_2)
    ).to.be.revertedWith(ObserverMerkleProviderErrors.ObserverVotedAlready)
  })

  it('sealing of epoch before epoch end block fails', async function () {
    //  Seal Epoch 0
    await submitMerkleRoot(epochSealThreshold, 1, ROOT_1)

    // Seal Epoch 1 should fail
    await submitMerkleRoot(epochSealThreshold - 1, 2, ROOT_1)
    await expect(
      merkleProvider.connect(observers[2]).submitMerkleRoot(2, ROOT_1)
    ).to.be.revertedWith(ObserverMerkleProviderErrors.EpochNotReadyForSealing)
  })

  it('seal epoch after epoch end block', async function () {
    await submitMerkleRoot(epochSealThreshold, 1, ROOT_1)
    await mineBlocks(ethers.provider, 15000)
    await submitMerkleRoot(epochSealThreshold, 2, ROOT_1)
    expect(await merkleProvider.isEpochActive(2))
  })

  it('submitting merkle roots fails if the epoch is not valid', async function () {
    await submitMerkleRoot(epochSealThreshold, 2, ROOT_1, ObserverMerkleProviderErrors.EpochInvalid)
  })

  async function submitMerkleRoot(
    numberOfObservers: number,
    epoch: number,
    merkleRoot: string,
    revertedWithMessage = ''
  ) {
    for (let i = 0; i < numberOfObservers; i++) {
      if (revertedWithMessage) {
        await expect(
          merkleProvider.connect(observers[i]).submitMerkleRoot(epoch, merkleRoot)
        ).to.be.revertedWith(revertedWithMessage)
      } else {
        await merkleProvider.connect(observers[i]).submitMerkleRoot(epoch, merkleRoot)
      }
    }
  }
})
