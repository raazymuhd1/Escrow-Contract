// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";


contract Multichain is CCIPReceiver, OwnerIsCreator {
    using SafeERC20 for IERC20;

    error Multichain__InvalidOrNotAllowedSourceChains(uint256 chainId);
    error Multichain__InvalidOrNotAllowedDestChains(uint256 chainId);

    bytes32 private s_lastReceivedMessageId;
    string private s_lastReceivedText;
    IRouterClient private immutable s_router;
    IERC20 private immutable s_linkToken;

    // -------------------------------------------------MAPPINGS-----------------------------------------------
    mapping(uint64 => bool) private s_allowedSourceChains;
    mapping(uint64 => bool) private s_allowedDestinationChains;

     event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );


    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string text, // The text being sent.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );


    constructor(address router_, address linkToken, uint256[] memory chainIds) CCIPReceiver(router_) {
        s_router = IRouterClient(router_);
        s_linkToken = IERC20(linkToken);
        
    }

    
    // -------------------------------------------------MODIFIERS-----------------------------------------------
    modifier OnlyListedChainAllowed(uint64 sourceChain, uint64 destChain) {
       if(!s_allowedSourceChains[sourceChain]) revert Multichain__InvalidOrNotAllowedSourceChains(sourceChain);
       if(!s_allowedDestinationChains[destChain]) revert Multichain__InvalidOrNotAllowedDestChains(destChain);
       _;
    }

       /// handle a received message
    /**
        @notice implementing a message received 
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(any2EvmMessage.data, (string))
        );
    }



}