// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockRouter {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

      /// @inheritdoc IRouterClient
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee) {
    if (message.feeToken == address(0)) {
      // For empty feeToken return native quote.
      message.feeToken = address(s_wrappedNative);
    }
    address onRamp = s_onRamps[destinationChainSelector];
    if (onRamp == address(0)) revert UnsupportedDestinationChain(destinationChainSelector);
    return IEVM2AnyOnRamp(onRamp).getFee(destinationChainSelector, message);
  }

   /// @inheritdoc IRouterClient
  function isChainSupported(
    uint64 chainSelector
  ) public view returns (bool) {
    return s_onRamps[chainSelector] != address(0);
  }

    /// @inheritdoc IRouterClient
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external payable whenNotCursed returns (bytes32) {
    address onRamp = s_onRamps[destinationChainSelector];
    if (onRamp == address(0)) revert UnsupportedDestinationChain(destinationChainSelector);
    uint256 feeTokenAmount;
    // address(0) signals payment in true native
    if (message.feeToken == address(0)) {
      // for fee calculation we check the wrapped native price as we wrap
      // as part of the native fee coin payment.
      message.feeToken = s_wrappedNative;
      // We rely on getFee to validate that the feeToken is whitelisted.
      feeTokenAmount = IEVM2AnyOnRamp(onRamp).getFee(destinationChainSelector, message);
      // Ensure sufficient native.
      if (msg.value < feeTokenAmount) revert InsufficientFeeTokenAmount();
      // Wrap and send native payment.
      // Note we take the whole msg.value regardless if its larger.
      feeTokenAmount = msg.value;
      IWrappedNative(message.feeToken).deposit{value: feeTokenAmount}();
      IERC20(message.feeToken).safeTransfer(onRamp, feeTokenAmount);
    } else {
      if (msg.value > 0) revert InvalidMsgValue();
      // We rely on getFee to validate that the feeToken is whitelisted.
      feeTokenAmount = IEVM2AnyOnRamp(onRamp).getFee(destinationChainSelector, message);
      IERC20(message.feeToken).safeTransferFrom(msg.sender, onRamp, feeTokenAmount);
    }

    // Transfer the tokens to the token pools.
    for (uint256 i = 0; i < message.tokenAmounts.length; ++i) {
      IERC20 token = IERC20(message.tokenAmounts[i].token);
      // We rely on getPoolBySourceToken to validate that the token is whitelisted.
      token.safeTransferFrom(
        msg.sender,
        address(IEVM2AnyOnRamp(onRamp).getPoolBySourceToken(destinationChainSelector, token)),
        message.tokenAmounts[i].amount
      );
    }

    return IEVM2AnyOnRamp(onRamp).forwardFromRouter(destinationChainSelector, message, feeTokenAmount, msg.sender);
  }

}