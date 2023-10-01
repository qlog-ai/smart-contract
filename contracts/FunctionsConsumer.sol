// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1363} from "@openzeppelin/contracts/interfaces/IERC1363.sol";

error QLog_LinkAmountToLow();
error QLog_payLinkForDatasetFailed();
error QLog_payLinkForRegistryFailed();
error QLog_refundFailedContactUs();

/**
 * @title Chainlink Functions example on-demand consumer contract example
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
  using FunctionsRequest for FunctionsRequest.Request;

  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  bytes32 internal sourceHash;

  address internal immutable linkAddress = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
  address internal immutable linkBillingProxyAddress = 0x65Dcc24F8ff9e51F10DCc7Ed1e4e2A61e6E14bd6;
  uint256 internal constant LINK_DIVISIBILITY = 10 ** 18;

  mapping(bytes32 => address) public requestWalletAddress;
  mapping(bytes32 => uint256) public requestLinkAmount;

  constructor(address router, bytes32 _donId) FunctionsClient(router) ConfirmedOwner(msg.sender) {
    donId = _donId;
  }

  /**
   * @notice Set the DON ID
   * @param newDonId New DON ID
   */
  function setDonId(bytes32 newDonId) external onlyOwner {
    donId = newDonId;
  }

  /**
   * @notice Triggers an on-demand Functions request using remote encrypted secrets
   * @param source JavaScript source code
   * @param secretsLocation Location of secrets (only Location.Remote & Location.DONHosted are supported)
   * @param encryptedSecretsReference Reference pointing to encrypted secrets
   * @param args String arguments passed into the source code and accessible via the global variable `args`
   * @param subscriptionId Subscription ID used to pay for request (FunctionsConsumer contract address must first be added to the subscription)
   * @param callbackGasLimit Maximum amount of gas used to call the inherited `handleOracleFulfillment` method
   * @param linkAmount Amount of LINK to pay for the request (must be at least 1 LINK)
   */
  function sendRequest(
    string calldata source,
    FunctionsRequest.Location secretsLocation,
    bytes calldata encryptedSecretsReference,
    string[] calldata args,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 linkAmount
  ) external onlyOwner {
    // Purchase Dataset amount should be at least 1 LINK
    if (linkAmount < LINK_DIVISIBILITY) revert QLog_LinkAmountToLow();
    bool success = IERC20(linkAddress).transferFrom(msg.sender, address(this), linkAmount);
    if (!success) revert QLog_payLinkForDatasetFailed();

    // Fund subscription
    bool success2 = IERC1363(linkAddress).transferAndCall(
      linkBillingProxyAddress,
      // This is more than enough to cover the current fees 0.2 LINK + transaction cost + variable (depending on gas)
      LINK_DIVISIBILITY / 3,
      abi.encode(subscriptionId)
    );
    if (!success2) revert QLog_payLinkForRegistryFailed();

    FunctionsRequest.Request memory req;
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
    req.secretsLocation = secretsLocation;
    req.encryptedSecretsReference = encryptedSecretsReference;
    if (args.length > 0) {
      req.setArgs(args);
    }
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, donId);
    requestWalletAddress[s_lastRequestId] = msg.sender;
    requestLinkAmount[s_lastRequestId] = linkAmount;
  }

  /**
   * @notice Witdraws LINK from the contract to the Owner
   */
  function withdrawLinkOwner() external onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Forbidden to transfer link to non-owner");
  }

  /**
   * @notice Allows the source hash to be updated
   *
   * @param newSourceHash New source hash
   */
  function updateSourceHash(bytes32 newSourceHash) external onlyOwner {
    sourceHash = newSourceHash;
  }

  /**
   * @notice Store latest result/error
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    if (err.length > 0) {
      // Refund link
      bool success = IERC20(linkAddress).transferFrom(
        address(this),
        requestWalletAddress[requestId],
        requestLinkAmount[requestId]
      );
      if (!success) revert QLog_refundFailedContactUs();
    }

    // for debugging purposes, should be removed later
    s_lastResponse = response;
    s_lastError = err;
  }
}
