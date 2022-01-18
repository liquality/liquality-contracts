import { ethers } from 'hardhat'
import hre from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import { expect } from 'chai'
import { deployGovernance } from './utils'

describe('Governance Deploy', function () {
  let signers: SignerWithAddress[]
  before(async function () {
    signers = await ethers.getSigners()
  })

  it('can deploy', async function () {
    const { timelock, delegate, delegator } = await deployGovernance(signers[0].address)
    const adminTx = await delegate.populateTransaction.admin()
    const admin = await delegator.provider.call({
      to: delegator.address,
      data: adminTx.data
    })
    const adminAddress = ethers.utils.defaultAbiCoder.decode(['address'], admin)[0]
    expect(adminAddress).to.equal(timelock.address)
  })
})
