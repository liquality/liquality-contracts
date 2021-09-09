import { TypedDataDomain, TypedDataField } from '@ethersproject/abstract-signer'
import { BigNumber } from '@ethersproject/bignumber'
import { LiqualityToken } from '../../typechain'

export function expandTo18Decimals(n: number): BigNumber {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
}

interface IPermitData {
  domain: TypedDataDomain
  types: Record<string, Array<TypedDataField>>
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  value: Record<string, any>
}

export async function getPermitData(
  token: LiqualityToken,
  approve: {
    owner: string
    spender: string
    value: BigNumber
  },
  nonce: BigNumber,
  deadline: BigNumber
): Promise<IPermitData> {
  const name = await token.name()
  const chainId = await token.getChainId()

  return {
    types: {
      Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
      ]
    },
    domain: {
      name: name,
      version: '1',
      chainId: chainId,
      verifyingContract: token.address
    },
    value: {
      owner: approve.owner,
      spender: approve.spender,
      value: approve.value,
      nonce,
      deadline
    }
  }
}
