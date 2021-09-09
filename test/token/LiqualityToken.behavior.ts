import { expect } from 'chai'

import { keccak256 } from '@ethersproject/keccak256'
import { splitSignature, hexlify } from '@ethersproject/bytes'
import { BigNumber } from '@ethersproject/bignumber'
import { defaultAbiCoder } from '@ethersproject/abi'
import { toUtf8Bytes } from '@ethersproject/strings'
import { AddressZero, MaxUint256 } from '@ethersproject/constants'
import { expandTo18Decimals, getPermitData } from './utils'

const MINT_AMOUNT = expandTo18Decimals(10000)
const TEST_AMOUNT = expandTo18Decimals(100)

export function shouldBehaveLikeErc20(): void {
  it('name, symbol, decimals, totalSupply, DOMAIN_SEPARATOR, PERMIT_TYPEHASH', async function () {
    const tokenVersion = '1'
    const name = await this.liqToken.name()
    const chainId = await this.liqToken.getChainId()

    expect(name).to.eq('Liquality')
    expect(await this.liqToken.symbol()).to.eq('LIQ')
    expect(await this.liqToken.decimals()).to.eq(18)
    expect(await this.liqToken.totalSupply()).to.eq(0)
    expect(await this.liqToken.getDomainSeparator()).to.eq(
      keccak256(
        defaultAbiCoder.encode(
          ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
          [
            keccak256(
              toUtf8Bytes(
                'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
              )
            ),
            keccak256(toUtf8Bytes(name)),
            keccak256(toUtf8Bytes(tokenVersion)),
            chainId.toNumber(),
            this.liqToken.address
          ]
        )
      )
    )
    expect(await this.liqToken.PERMIT_TYPEHASH()).to.eq(
      keccak256(
        toUtf8Bytes(
          'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
        )
      )
    )
  })

  it('mint', async function () {
    const { admin, sender } = this.signers

    await expect(this.liqToken.connect(admin).mint(sender.address, MINT_AMOUNT))
      .to.emit(this.liqToken, 'Transfer')
      .withArgs(AddressZero, sender.address, MINT_AMOUNT)

    expect(await this.liqToken.totalSupply()).to.eq(MINT_AMOUNT)
    expect(await this.liqToken.balanceOf(sender.address)).to.eq(MINT_AMOUNT)
  })

  it('approve', async function () {
    const { sender, receiver } = this.signers

    await expect(this.liqToken.connect(sender).approve(receiver.address, TEST_AMOUNT))
      .to.emit(this.liqToken, 'Approval')
      .withArgs(sender.address, receiver.address, TEST_AMOUNT)
    expect(await this.liqToken.allowance(sender.address, receiver.address)).to.eq(TEST_AMOUNT)
  })

  it('transfer', async function () {
    const { sender, receiver } = this.signers

    await expect(this.liqToken.connect(sender).transfer(receiver.address, TEST_AMOUNT))
      .to.emit(this.liqToken, 'Transfer')
      .withArgs(sender.address, receiver.address, TEST_AMOUNT)
    expect(await this.liqToken.balanceOf(sender.address)).to.eq(MINT_AMOUNT.sub(TEST_AMOUNT))
    expect(await this.liqToken.balanceOf(receiver.address)).to.eq(TEST_AMOUNT)
  })

  it('transfer:fail', async function () {
    const { sender, receiver } = this.signers
    const senderBalance = await this.liqToken.balanceOf(sender.address)
    const receiverBalance = await this.liqToken.balanceOf(receiver.address)

    await expect(this.liqToken.connect(sender).transfer(receiver.address, senderBalance.add(1))).to
      .be.reverted // ds-math-sub-underflow
    await expect(this.liqToken.connect(receiver).transfer(sender.address, receiverBalance.add(1)))
      .to.be.reverted // ds-math-sub-underflow
  })

  it('transferFrom', async function () {
    const { sender, receiver } = this.signers

    const senderBalance = await this.liqToken.balanceOf(sender.address)
    const receiverBalance = await this.liqToken.balanceOf(receiver.address)

    await this.liqToken.approve(receiver.address, TEST_AMOUNT)
    await expect(
      this.liqToken.connect(receiver).transferFrom(sender.address, receiver.address, TEST_AMOUNT)
    )
      .to.emit(this.liqToken, 'Transfer')
      .withArgs(sender.address, receiver.address, TEST_AMOUNT)

    expect(await this.liqToken.allowance(sender.address, receiver.address)).to.eq(0)
    expect(await this.liqToken.balanceOf(sender.address)).to.eq(senderBalance.sub(TEST_AMOUNT))
    expect(await this.liqToken.balanceOf(receiver.address)).to.eq(receiverBalance.add(TEST_AMOUNT))
  })

  it('transferFrom:max', async function () {
    const { sender, receiver } = this.signers

    const senderBalance = await this.liqToken.balanceOf(sender.address)
    const receiverBalance = await this.liqToken.balanceOf(receiver.address)

    await this.liqToken.connect(sender).approve(receiver.address, MaxUint256)
    await expect(
      this.liqToken.connect(receiver).transferFrom(sender.address, receiver.address, TEST_AMOUNT)
    )
      .to.emit(this.liqToken, 'Transfer')
      .withArgs(sender.address, receiver.address, TEST_AMOUNT)
    expect(await this.liqToken.allowance(sender.address, receiver.address)).to.eq(MaxUint256)
    expect(await this.liqToken.balanceOf(sender.address)).to.eq(senderBalance.sub(TEST_AMOUNT))
    expect(await this.liqToken.balanceOf(receiver.address)).to.eq(receiverBalance.add(TEST_AMOUNT))
  })

  it('permit', async function () {
    const { sender, receiver } = this.signers

    const nonce = await this.liqToken.nonces(sender.address)
    const deadline = MaxUint256

    const permitData = await getPermitData(
      this.liqToken,
      { owner: sender.address, spender: receiver.address, value: TEST_AMOUNT },
      nonce,
      deadline
    )

    const signature = await sender._signTypedData(
      permitData.domain,
      permitData.types,
      permitData.value
    )
    const { v, r, s } = splitSignature(signature)

    await expect(
      this.liqToken.permit(
        sender.address,
        receiver.address,
        TEST_AMOUNT,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    )
      .to.emit(this.liqToken, 'Approval')
      .withArgs(sender.address, receiver.address, TEST_AMOUNT)

    expect(await this.liqToken.allowance(sender.address, receiver.address)).to.eq(TEST_AMOUNT)
    expect(await this.liqToken.nonces(sender.address)).to.eq(BigNumber.from(1))
  })
}
