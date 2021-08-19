import { MerkleTree } from 'merkletreejs'
import { BigNumber, utils } from 'ethers'
import keccak256 from 'keccak256' // Ethers.utils.keccak256 is not compatible with merkletreejs

export type Allocation = {
  index: number
  account: string
  amount: BigNumber
}

export type MerkleData = {
  merkleRoot: string
  totalTokens: string
  claims: { [account: string]: Claim }
}

export type Claim = {
  index: number
  amount: string
  proof: string[]
}

export function generateMerkleData(amountsMap: { [account: string]: number }): MerkleData {
  const allocations = Object.keys(amountsMap).map(
    (account, index) =>
      <Allocation>{
        index,
        account,
        amount: BigNumber.from(amountsMap[account])
      }
  )

  const leaves = allocations.map((account: Allocation) =>
    utils.solidityKeccak256(
      ['uint256', 'address', 'uint256'],
      [account.index, account.account, account.amount]
    )
  )

  const tree = new MerkleTree(leaves, keccak256, { sort: true })
  const claims: { [account: string]: Claim } = {}
  let totalTokens = BigNumber.from(0)
  allocations.forEach((allocation, i) => {
    claims[allocation.account] = {
      index: allocation.index,
      amount: allocation.amount.toHexString(),
      proof: tree.getHexProof(leaves[i])
    }
    totalTokens = totalTokens.add(allocation.amount)
  })

  const merkleData: MerkleData = {
    merkleRoot: tree.getHexRoot(),
    totalTokens: totalTokens.toHexString(),
    claims
  }

  return merkleData
}
