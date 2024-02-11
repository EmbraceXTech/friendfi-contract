// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IFunctionsRouter} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {IFunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsClient.sol";
import {FunctionsResponse} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsResponse.sol";

contract TestFunctionsRouter is IFunctionsRouter {

  bytes32 lastRequestId;

  function getAllowListId() external view returns (bytes32) {
    return bytes32("");
  }
  function setAllowListId(bytes32 allowListId) external{}
  function getAdminFee() external view returns (uint72 adminFee) {
    return uint72(0);
  }

  function sendRequest(
    uint64 subscriptionId,
    bytes calldata data,
    uint16 dataVersion,
    uint32 callbackGasLimit,
    bytes32 donId
  ) external returns (bytes32) {
    lastRequestId = keccak256(abi.encodePacked(subscriptionId, data, dataVersion, callbackGasLimit, donId));
    return lastRequestId;
  }

  function sendRequestToProposed(
    uint64 subscriptionId,
    bytes calldata data,
    uint16 dataVersion,
    uint32 callbackGasLimit,
    bytes32 donId
  ) external returns (bytes32) {
    return donId;
  }

  function fulfill(
    bytes memory response,
    bytes memory err,
    uint96 juelsPerGas,
    uint96 costWithoutFulfillment,
    address transmitter,
    FunctionsResponse.Commitment memory commitment
  ) external returns (FunctionsResponse.FulfillResult, uint96) {
    IFunctionsClient(commitment.client).handleOracleFulfillment(lastRequestId, response, err);
    return (FunctionsResponse.FulfillResult.FULFILLED, juelsPerGas);
  }

  function isValidCallbackGasLimit(uint64 subscriptionId, uint32 callbackGasLimit) external view {}
  function getContractById(bytes32 id) external view returns (address) {}
  function getProposedContractById(bytes32 id) external view returns (address) {}
  function getProposedContractSet() external view returns (bytes32[] memory, address[] memory) {}
  function proposeContractsUpdate(bytes32[] memory proposalSetIds, address[] memory proposalSetAddresses) external {}
  function updateContracts() external {}
  function pause() external {}
  function unpause() external {}
}
