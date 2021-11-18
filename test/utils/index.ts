import { JsonRpcProvider } from '@ethersproject/providers'

export async function mineBlocks(provider: JsonRpcProvider, blocks: number): Promise<void> {
  for (let i = 0; i <= blocks; i++) {
    await provider.send('evm_mine', [])
  }
}
