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

    error Multichain__InvalidOrNotAllowedSourceChains(uint64 chainId);
    error Multichain__InvalidOrNotAllowedDestChains(uint64 chainId);
    error MultiChain__InvalidChain(uint64 chainId);
    error MultiChain__AlreadyAllowed(uint64 chainId);
    error MultiChain__InvalidReceiverOrSender(address rcv);

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

    modifier OnlyValidReceiver(address _receiver) {
        if(_receiver == address(0)) revert MultiChain__InvalidReceiverOrSender(_receiver);
        _;
    }

    modifier OnlyValidSender(address _sender) {
        if(_sender == address(0)) revert MultiChain__InvalidReceiverOrSender(_sender);
        _;
    }

     // ------------------------------------------- EXTERNAL & PUBLIC FUNCTIONS ----------------------------------------------
    function allowedSourceChain(uint64 chainId, bool allowed) external returns(uint64) {
        _allowedChains(chainId, allowed, s_allowedSourceChains[chainId]);
    }

    function allowedDestChain(uint64 chainId, bool allowed) external returns(uint64) {
        _allowedChains(chainId, allowed, s_allowedDestinationChains[chainId]);
    }

    /**
        @dev send token along with message to a dest chain
     */
    function sendMessagePayWithLink(
        uint64 destChain,
        address receiver,
        string calldata text,
        address tokenAddr,
        uint256 tokenAmount
    ) external returns(bool) {

    }

     // ------------------------------------------- INTERNAL & PRIVATE FUNCTIONS ----------------------------------------------
    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for programmable tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _text The string data to be sent.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: abi.encode(_text), // ABI-encoded string
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit and allowing out-of-order execution.
                    // Best Practice: For simplicity, the values are hardcoded. It is advisable to use a more dynamic approach
                    // where you set the extra arguments off-chain. This allows adaptation depending on the lanes, messages,
                    // and ensures compatibility with future CCIP upgrades. Read more about it here: https://docs.chain.link/ccip/best-practices#using-extraargs
                    Client.EVMExtraArgsV2({
                        gasLimit: 200_000, // Gas limit for the callback on the destination chain
                        allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                    })
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
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

    function _allowedChains(uint64 chainId, bool allowed, bool srcOrDest) internal {
         if(chainId == 0) revert MultiChain__InvalidChain(chainId);
         if(srcOrDest == allowed) revert MultiChain__AlreadyAllowed(chainId);
         srcOrDest = allowed;
    }

}