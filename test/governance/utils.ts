import { ethers } from 'hardhat'

import {
  GovernorBravoDelegate,
  Timelock,
  GovernorBravoDelegator,
  LiqualityToken
} from '../../typechain'

export async function deployGovernance(admin: string) {
  const LiqualityToken = await ethers.getContractFactory('LiqualityToken')
  const liq: LiqualityToken = await LiqualityToken.deploy(admin)

  const GovernorBravoDelegate = await ethers.getContractFactory('GovernorBravoDelegate')
  const delegate: GovernorBravoDelegate = await GovernorBravoDelegate.deploy()

  const Timelock = await ethers.getContractFactory('Timelock')
  const timelock: Timelock = await Timelock.deploy(delegate.address, 0)

  const GovernorBravoDelegator = await ethers.getContractFactory('GovernorBravoDelegator')
  const delegator: GovernorBravoDelegator = await GovernorBravoDelegator.deploy(
    timelock.address,
    liq.address,
    timelock.address,
    delegate.address,
    5760,
    1,
    '50000000000000000000000'
  )

  return { liq, timelock, delegate, delegator }
}
