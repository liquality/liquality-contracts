import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { ObserverMerkleProvider } from '../typechain/ObserverMerkleProvider'
import { expect } from 'chai'

const ROOT_1 = ethers.utils.sha256('0x01')
const ROOT_2 = ethers.utils.sha256('0x02')
const ROOT_3 = ethers.utils.sha256('0x03')

describe('ObserverMerkleProvider', function () {
  let merkleProvider: ObserverMerkleProvider
  let observers: SignerWithAddress[]
  before(async function () {
    observers = await ethers.getSigners()
  })

  beforeEach(async function () {
    const ObserverMerkleProvider = await ethers.getContractFactory('ObserverMerkleProvider')
    merkleProvider = <ObserverMerkleProvider>await ObserverMerkleProvider.deploy()
  })

  it('should start at 0 epoch', async function () {
    expect(await merkleProvider.lastEpoch()).to.equal(0)
  })

  it('should let observers submit roots', async function () {
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_1)
    await merkleProvider.connect(observers[1]).submitMerkleRoot(1, ROOT_1)
  })

  it('should seal epoch after enough submissions', async function () {
    expect(await merkleProvider.isEpochSealed(1)).to.equal(false)
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_1)
    await merkleProvider.connect(observers[1]).submitMerkleRoot(1, ROOT_1)
    await expect(merkleProvider.connect(observers[2]).submitMerkleRoot(1, ROOT_1))
      .to.emit(merkleProvider, 'SealEpoch')
      .withArgs(1, ROOT_1)
    expect(await merkleProvider.isEpochSealed(1)).to.equal(true)
    expect(await merkleProvider.lastEpoch()).to.equal(1)
    expect(await merkleProvider.merkleRoot(1), ROOT_1)
  })

  it('should prevent further submissions after seal', async function () {
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_1)
    await merkleProvider.connect(observers[1]).submitMerkleRoot(1, ROOT_1)
    await merkleProvider.connect(observers[2]).submitMerkleRoot(1, ROOT_1)
    await expect(
      merkleProvider.connect(observers[3]).submitMerkleRoot(1, ROOT_2)
    ).to.be.revertedWith('EPOCH_ALREADY_SEALED')
  })

  it('should not be able to submit twice', async function () {
    await merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_1)
    await expect(
      merkleProvider.connect(observers[0]).submitMerkleRoot(1, ROOT_2)
    ).to.be.revertedWith('OBSERVER_VOTED_ALREADY')
  })
})
