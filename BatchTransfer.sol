// SPDX-License-Identifier: MIT
/**
 * @title OpenBatchTransfer
 * @notice A permissionless contract to transfer ETH or ERC20 to multiple addresses
 * in a single transcation.
 * This contract is completely decentralized and immutable, without any privilege.
 * This contract should NOT hold any tokens. It should be safe to approve your token
 * this contract for token transfer.
 * Excessive ETH send to this contract will be returned at the end of sendETH()
 * ANYONE can use rescueERC20 and rescueETH to claim ETHs or tokens in this contract.
 */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OpenBatchTransfer {
    using SafeERC20 for IERC20;

    /**
     * @dev allow batch transfer eth (or other native token if not on mainet)
     *      with the best effort to save gas
     * @param receivers   An array of receivers' address
     * @param amounts     An array of eth amount to send for each receiver, the caller
     *                    should make sure its length and order are consistent with [receivers]
     * @note gas estimation
     *
     *       txNum         |   gas usage   |    gas increment | gas per tx
     *    1(use evm send)  |      2,1000   |         -        |   2,1000
     *         2           |      4,2320   |       2,1320     |   2,1160
     *         3           |      5,2270   |        9550      |   1,7424
     *         4           |      6,2220   |        9950      |   1,5555
     *         5           |      7,2170   |        9950      |   1,4434
     *         6           |      8,2132   |        9962      |   1,3689
     *         7           |      9,2082   |        9950      |   1,3155
     */
    function sendETH(
        address payable[] calldata receivers,
        uint256[] calldata amounts
    ) external payable {
        assembly {
            // if(receivers.length != amounts.length) revert();
            let rlen := receivers.length
            let alen := amounts.length
            if xor(rlen, alen) {
                revert(0, 0)
            }

            let rdata := receivers.offset
            let adata := amounts.offset

            /* The following for loop is equivalent to:
             *   for (uint256 i; i < receivers.length; ++i) {
             *       (bool success, ) = receivers[i].call{value: amounts[i]}("");
             *       if(!success) revert();
             *   }
             */
            for {
                let i := 0
            } lt(i, rlen) {
                i := add(i, 1)
            } {
                let sent := call(
                    gas(),
                    calldataload(rdata),
                    calldataload(adata),
                    0,
                    0,
                    0,
                    0
                )
                if iszero(sent) {
                    revert(0, 0)
                }
                rdata := add(rdata, 0x20)
                adata := add(adata, 0x20)
            }

            // return remaining eth back to sender if applicable
            if gt(selfbalance(), 0) {
                let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }
        }
    }

    function sendERC20Token(
        IERC20 token,
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external {
        uint256 txCount = receivers.length;
        if (txCount != amounts.length) revert();

        unchecked {
            for (uint256 i; i < txCount; ++i) {
                token.safeTransferFrom(msg.sender, receivers[i], amounts[i]);
            }
        }
    }

    function rescueERC20(IERC20 token) external {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function rescueETH() external {
        assembly {
            let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
        }
    }
}
