import { ethers } from 'hardhat'
// import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { ObserverMerkleProvider } from '../typechain/ObserverMerkleProvider'
import { expect } from 'chai'

describe('ObserverMerkleProvider', function () {
  let merkleProvider: ObserverMerkleProvider
  // let signers: SignerWithAddress[]
  // before(async function () {
  //   signers = await ethers.getSigners()
  // })

  beforeEach(async function () {
    const ObserverMerkleProvider = await ethers.getContractFactory('ObserverMerkleProvider')
    merkleProvider = <ObserverMerkleProvider>await ObserverMerkleProvider.deploy()
  })

  it('should start at 0 epoch', async function () {
    expect(await merkleProvider.lastEpoch()).to.equal(0)
  })
})
