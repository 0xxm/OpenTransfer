# OpenTransfer
This is a permissionless contract to transfer native or ERC20 tokens to multiple addresses in a single transcation.

- It is completely decentralized and immutable, without any privilege. Feel safe to approve your token to this contract for token transfer.
- This contract should NOT hold any tokens. DO NOT transfer ERC20 tokens directly to this contract!
- Excessive ETH send to this contract will be returned at the end of sendETH()
- ANYONE can use rescueERC20 and rescueETH to claim ETHs or tokens remain this contract.

Currenly deployed on ploygon mainnet: https://polygonscan.com/address/0x2cba9ad7e8a9268efe8049799597fdb22b6ed320
