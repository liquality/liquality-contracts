import { ethers } from 'hardhat'

import {
  GovernorBravoDelegate,
  Timelock,
  GovernorBravoDelegator,
  LiqualityToken,
  SLiqualityToken
} from '../../typechain'

export async function deployGovernance(admin: string) {
  const LiqualityToken = await ethers.getContractFactory('LiqualityToken')
  const liq: LiqualityToken = await LiqualityToken.deploy(admin)
  const LiqualityStaking = await ethers.getContractFactory('sLiqualityToken')
  const sLiq = <SLiqualityToken>(
    await LiqualityStaking.deploy(liq.address, 'Liquality Staking', 'sLIQ', '1.0.0')
  )

  const GovernorBravoDelegate = await ethers.getContractFactory('GovernorBravoDelegate')
  const delegate: GovernorBravoDelegate = await GovernorBravoDelegate.deploy()

  const Timelock = await ethers.getContractFactory('Timelock')
  const timelock: Timelock = await Timelock.deploy(delegate.address, 0)

  const GovernorBravoDelegator = await ethers.getContractFactory('GovernorBravoDelegator')
  const delegator: GovernorBravoDelegator = await GovernorBravoDelegator.deploy(
    timelock.address,
    sLiq.address,
    timelock.address,
    delegate.address,
    5760,
    1,
    '50000000000000000000000'
  )

  return { liq, sLiq, timelock, delegate, delegator }
}
